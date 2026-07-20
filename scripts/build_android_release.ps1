$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$generatedRegistrant = Join-Path $workspaceRoot 'android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java'
$expectedRegistrant = [System.IO.Path]::GetFullPath(
  (Join-Path $workspaceRoot 'android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java')
)

if ([System.IO.Path]::GetFullPath($generatedRegistrant) -ne $expectedRegistrant) {
  throw 'O caminho do registrador gerado saiu do workspace esperado.'
}

Push-Location $workspaceRoot
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get falhou antes da geracao do APK.'
  }

  if (-not (Test-Path -LiteralPath $generatedRegistrant)) {
    throw 'O Flutter nao gerou GeneratedPluginRegistrant.java.'
  }

  # `flutter test`/`pub get` inclui o plugin integration_test no registrador
  # comum, mas o source set release exclui dependencias dev. Preservamos todos
  # os plugins de producao e removemos apenas o bloco de integration_test.
  $registrant = [System.IO.File]::ReadAllText($generatedRegistrant)
  $integrationPattern = '(?ms)^[ \t]*try \{\r?\n[ \t]*flutterEngine\.getPlugins\(\)\.add\(new dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin\(\)\);\r?\n[ \t]*\} catch \(Exception e\) \{\r?\n[ \t]*Log\.e\(TAG, "Error registering plugin integration_test, dev\.flutter\.plugins\.integration_test\.IntegrationTestPlugin", e\);\r?\n[ \t]*\}\r?\n'
  $releaseRegistrant = [System.Text.RegularExpressions.Regex]::Replace(
    $registrant,
    $integrationPattern,
    ''
  )
  if ($releaseRegistrant -eq $registrant -or $releaseRegistrant.Contains('integration_test')) {
    throw 'Nao foi possivel remover exclusivamente integration_test do registrador gerado.'
  }
  if (-not $releaseRegistrant.Contains('class GeneratedPluginRegistrant') -or
      -not $releaseRegistrant.Contains('registerWith')) {
    throw 'O registrador sanitizado perdeu a estrutura obrigatoria.'
  }
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText(
    $generatedRegistrant,
    $releaseRegistrant,
    $utf8NoBom
  )

  flutter build apk --release --no-shrink --no-pub
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter build apk falhou.'
  }

  node scripts/qa/release_source_fingerprint.js --write-build-evidence
  if ($LASTEXITCODE -ne 0) {
    throw 'Nao foi possivel gerar a proveniencia da APK release.'
  }
} finally {
  Pop-Location
}
