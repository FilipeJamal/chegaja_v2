#!/usr/bin/env python3
import argparse
import html
import json
import os
import re
import time
import urllib.parse
import urllib.request
from collections import OrderedDict
from pathlib import Path

PLACEHOLDER_RE = re.compile(r"\{[^}]+\}")


def protect_placeholders(text: str):
    placeholders = []

    def repl(match):
        placeholders.append(match.group(0))
        return f"__PH_{len(placeholders) - 1}__"

    return PLACEHOLDER_RE.sub(repl, text), placeholders


def restore_placeholders(text: str, placeholders):
    for i, ph in enumerate(placeholders):
        text = text.replace(f"__PH_{i}__", ph)
    return text


def translate_libretranslate(text, source, target, url, api_key):
    payload = {
        "q": text,
        "source": source,
        "target": target,
        "format": "text",
    }
    if api_key:
        payload["api_key"] = api_key
    data = urllib.parse.urlencode(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        out = json.loads(resp.read().decode("utf-8"))
    return out.get("translatedText", "")


def translate_google(text, source, target):
    query = urllib.parse.quote(text)
    url = (
        "https://translate.googleapis.com/translate_a/single"
        f"?client=gtx&sl={source}&tl={target}&dt=t&q={query}"
    )
    with urllib.request.urlopen(url, timeout=30) as resp:
        out = json.loads(resp.read().decode("utf-8"))
    parts = out[0] if out and isinstance(out[0], list) else []
    return "".join([seg[0] for seg in parts if seg and seg[0]])


def translate_googlecloud(text, source, target, api_key):
    payload = {
        "q": text,
        "source": source,
        "target": target,
        "format": "text",
        "key": api_key,
    }
    data = urllib.parse.urlencode(payload).encode("utf-8")
    req = urllib.request.Request(
        "https://translation.googleapis.com/language/translate/v2",
        data=data,
        headers={"Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        out = json.loads(resp.read().decode("utf-8"))
    translations = out.get("data", {}).get("translations", [])
    if not translations:
        return ""
    return html.unescape(translations[0].get("translatedText", ""))


def fetch_googlecloud_languages(api_key):
    url = (
        "https://translation.googleapis.com/language/translate/v2/languages"
        f"?target=en&key={urllib.parse.quote(api_key)}"
    )
    with urllib.request.urlopen(url, timeout=30) as resp:
        out = json.loads(resp.read().decode("utf-8"))
    langs = out.get("data", {}).get("languages", [])
    return [l.get("language") for l in langs if l.get("language")]


def translate_with_retries(fn, *args, retries=3):
    for attempt in range(retries):
        try:
            return fn(*args)
        except Exception:
            if attempt == retries - 1:
                raise
            time.sleep(1 + attempt)


def is_icu_message(text: str) -> bool:
    if "{" not in text:
        return False
    return "plural" in text or "select" in text


def load_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write_json(path, data):
    Path(path).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default="lib/l10n/app_en.arb")
    parser.add_argument(
        "--langs",
        default="auto",
        help="Comma-separated language codes, 'auto' to use app_*.arb, or 'all' for Google Cloud",
    )
    parser.add_argument(
        "--provider",
        default="googlecloud",
        choices=["google", "libretranslate", "googlecloud"],
    )
    parser.add_argument(
        "--libretranslate-url",
        default=os.environ.get("LIBRETRANSLATE_URL", "").strip(),
    )
    parser.add_argument(
        "--libretranslate-key",
        default=os.environ.get("LIBRETRANSLATE_API_KEY", "").strip(),
    )
    parser.add_argument(
        "--google-key",
        default=os.environ.get("GOOGLE_TRANSLATE_API_KEY", "").strip(),
    )
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--sleep-ms", type=int, default=100)
    args = parser.parse_args()

    if args.provider == "libretranslate" and not args.libretranslate_url:
        raise SystemExit(
            "LIBRETRANSLATE_URL nao definido. Ex: http://localhost:5000/translate"
        )
    if args.provider == "googlecloud" and not args.google_key:
        raise SystemExit(
            "GOOGLE_TRANSLATE_API_KEY nao definido para provider googlecloud."
        )

    source = load_json(args.source)
    base_items = [(k, v) for k, v in source.items() if k != "@@locale"]

    lang_map = {
        "zh": "zh-CN",
    }
    cache = {}
    if args.langs == "auto":
        source_locale = source.get("@@locale")
        if not source_locale:
            stem = Path(args.source).stem
            source_locale = stem.split("_", 1)[1] if "_" in stem else stem
        langs = []
        for path in Path("lib/l10n").glob("app_*.arb"):
            stem = path.stem
            code = stem.split("_", 1)[1] if "_" in stem else stem
            if code and code != source_locale:
                langs.append(code)
        langs = sorted(set(langs))
    elif args.langs == "all":
        if args.provider != "googlecloud":
            raise SystemExit("langs=all requer provider googlecloud.")
        langs = fetch_googlecloud_languages(args.google_key)
        langs = sorted({l for l in langs if l and l != "en"})
    else:
        langs = [l.strip() for l in args.langs.split(",") if l.strip()]

    for lang in langs:
        target_path = Path(f"lib/l10n/app_{lang}.arb")
        if target_path.exists():
            target = load_json(target_path)
        else:
            target = {}

        out = OrderedDict()
        out["@@locale"] = lang
        for k, v in base_items:
            if k.startswith("@"):
                out[k] = v
                continue
            if k in target and not args.overwrite:
                out[k] = target[k]
                continue
            if not isinstance(v, str):
                out[k] = v
                continue
            if is_icu_message(v):
                if k in target:
                    out[k] = target[k]
                else:
                    out[k] = v
                continue

            protected, placeholders = protect_placeholders(v)
            target_code = lang_map.get(lang, lang)
            cache_key = (args.provider, target_code, protected)
            if cache_key in cache:
                translated = cache[cache_key]
            elif args.provider == "googlecloud":
                translated = translate_with_retries(
                    translate_googlecloud,
                    protected,
                    "en",
                    target_code,
                    args.google_key,
                )
                cache[cache_key] = translated
            elif args.provider == "google":
                translated = translate_with_retries(
                    translate_google,
                    protected,
                    "en",
                    target_code,
                )
                cache[cache_key] = translated
            else:
                translated = translate_with_retries(
                    translate_libretranslate,
                    protected,
                    "en",
                    target_code,
                    args.libretranslate_url,
                    args.libretranslate_key,
                )
                cache[cache_key] = translated
            out[k] = restore_placeholders(translated, placeholders)
            time.sleep(args.sleep_ms / 1000.0)

        write_json(target_path, out)

    print("Done.")


if __name__ == "__main__":
    main()
