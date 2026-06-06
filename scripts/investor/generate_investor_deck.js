const fs = require('fs');
const path = require('path');
const pptxgen = require('pptxgenjs');
const { chromium } = require('playwright');
const SHAPE = new pptxgen().ShapeType;

const root = path.resolve(__dirname, '..', '..');
const outDir = path.join(root, 'artifacts', 'investor');
const mediaDir = path.join(outDir, 'media');

const pptxPath = path.join(outDir, 'ChegaJa_Investor_Deck_P0_5.pptx');
const htmlPath = path.join(outDir, 'ChegaJa_Investor_Deck_P0_5.html');
const pdfPath = path.join(outDir, 'ChegaJa_Investor_Deck_P0_5.pdf');
const previewPath = path.join(outDir, 'ChegaJa_Investor_Deck_P0_5_preview.png');
const manifestPath = path.join(outDir, 'ChegaJa_Investor_Deck_P0_5_manifest.json');

const temp = process.env.TEMP || process.env.TMP || '';
const sourceImages = [
  {
    key: 'clientHome',
    title: 'Home Cliente',
    candidates: [
      path.join(temp, 'chegaja-m22010-visual-qa', 'home_cliente__desktop.png'),
      path.join(root, 'artifacts', 'presentation_chegaja', 'client_home.png'),
    ],
  },
  {
    key: 'providerHome',
    title: 'Home Prestador',
    candidates: [
      path.join(temp, 'chegaja-m22010-visual-qa', 'home_prestador__desktop.png'),
      path.join(root, 'artifacts', 'presentation_chegaja', 'provider_home_fixed.png'),
    ],
  },
  {
    key: 'orderDetail',
    title: 'Detalhe do Pedido',
    candidates: [
      path.join(
        temp,
        'chegaja-e2e-full-ui',
        '2026-06-05T18-50-47-911Z',
        '30_manual_client_detail.png',
      ),
      path.join(
        temp,
        'chegaja-e2e-full-ui',
        '2026-06-05T18-50-47-911Z',
        '02_happy_client_order_created.png',
      ),
    ],
  },
  {
    key: 'chat',
    title: 'Chat no Pedido',
    candidates: [
      path.join(
        temp,
        'chegaja-e2e-full-ui',
        '2026-06-05T18-50-47-911Z',
        '33_chat_provider_sent.png',
      ),
      path.join(root, 'artifacts', 'presentation_chegaja', 'provider_chat_thread.png'),
    ],
  },
  {
    key: 'admin',
    title: 'Backoffice Admin',
    candidates: [
      path.join(root, 'artifacts', 'presentation_chegaja', 'admin_panel_fixed.png'),
      path.join(root, 'artifacts', 'presentation_chegaja', 'admin_panel.png'),
    ],
  },
  {
    key: 'logo',
    title: 'Logo',
    candidates: [
      path.join(root, 'assets', 'images', 'app_icon.png'),
      path.join(root, 'build', 'web_manual_release', 'icons', 'Icon-512.png'),
    ],
  },
];

const palette = {
  bg: 'F6F8F8',
  ink: '111827',
  muted: '64748B',
  teal: '14B8A6',
  tealDark: '0F766E',
  blue: '2563EB',
  navy: '0B1220',
  lime: '22C55E',
  amber: 'F59E0B',
  red: 'EF4444',
  white: 'FFFFFF',
  line: 'D7DEE8',
  panel: 'FFFFFF',
};

const slides = [
  {
    section: 'Abertura',
    title: 'ChegaJa',
    kicker: 'Investor pitch',
    subtitle: 'Infraestrutura local de confianca para servicos sob demanda',
    body:
      'MVP funcional para organizar descoberta, pedidos, perfis, reputacao e seguranca em servicos locais.',
    chips: ['Maputo primeiro', 'MVP navegavel', 'Trust & Safety desde o MVP'],
    visual: 'brand',
    notes:
      'Abrir com a tese: ChegaJa nao e so app de servicos, e uma camada local de confianca para contratar melhor.',
  },
  {
    section: 'Problema',
    title: 'Contratar servicos locais ainda e disperso',
    subtitle: 'O problema nao e so encontrar alguem. E encontrar alguem certo.',
    bullets: [
      'Clientes dependem de contactos soltos, grupos e recomendacoes informais.',
      'Pouco contexto antes da conversa: portfolio, reputacao, historico e disponibilidade.',
      'Prestadores pequenos dependem de redes pessoais e pouca visibilidade digital.',
      'Texto livre sem regras pode abrir risco de servicos proibidos.',
    ],
    visual: 'problemFlow',
    notes:
      'Enquadrar WhatsApp e contactos como comportamento existente, nao como inimigo. A dor e falta de estrutura e confianca.',
  },
  {
    section: 'Solucao',
    title: 'O ChegaJa estrutura o fluxo completo',
    subtitle: 'Do pedido ao perfil, da conversa a reputacao.',
    bullets: [
      'Cliente descreve necessidade em linguagem simples.',
      'App organiza por Servico, Intencao e Detalhes.',
      'Prestador tem perfil, portfolio, @handle e categorias.',
      'Pedido vira proposta, conversa, execucao e avaliacao.',
    ],
    visual: 'flow',
    notes:
      'Mostrar que o produto liga os dois lados do marketplace e reduz incerteza antes da contratacao.',
  },
  {
    section: 'Produto',
    title: 'MVP navegavel, nao so ideia',
    subtitle: 'Fluxos principais ja existem no produto.',
    bullets: [
      'Cliente/Prestador, pedidos, orcamento e chat.',
      'Perfil publico, portfolio, avaliacoes e favoritos.',
      'Discovery/search manual e link publico.',
      'Admin leve, categorias sensiveis e catalogo profissional.',
    ],
    visual: 'screens',
    notes:
      'Reduzir risco de produto: ha material navegavel para demonstrar, ainda que mercado real seja o proximo risco.',
  },
  {
    section: 'Cliente',
    title: 'Cliente: pedir com mais contexto',
    subtitle: 'Servico -> Intencao -> Detalhes',
    bullets: [
      'Escolhe servico ou descreve necessidade.',
      'Pede agora, agenda ou solicita orcamento.',
      'Compara prestadores por perfil, portfolio e reputacao leve.',
      'Acompanha o pedido no mesmo fluxo.',
    ],
    visual: 'clientScreenshot',
    imageKey: 'clientHome',
    notes:
      'Esta e a experiencia que substitui o caos inicial: o cliente comeca por uma necessidade, mas sai com pedido estruturado.',
  },
  {
    section: 'Prestador',
    title: 'Prestador: visibilidade e pedidos',
    subtitle: 'Um canal de trabalho, nao apenas cadastro.',
    bullets: [
      'Perfil profissional com servicos, portfolio e @handle.',
      'Categorias de atuacao organizadas por catalogo.',
      'Recebe pedidos compativeis e responde no contexto.',
      'Construi reputacao por avaliacoes reais.',
    ],
    visual: 'providerScreenshot',
    imageKey: 'providerHome',
    notes:
      'O prestador tambem tem produto. O valor e montra, reputacao, link partilhavel e pedidos mais organizados.',
  },
  {
    section: 'Diferenciais',
    title: 'Mais que uma lista de prestadores',
    subtitle: 'A diferenca esta na estrutura.',
    bullets: [
      'Catalogo profissional com categorias, subcategorias, aliases e frases comuns.',
      '"Outro servico" exige nome, descricao e termos de pesquisa.',
      'Discovery por perfil e servico.',
      'Trust & Safety e admin leve desde o MVP.',
    ],
    visual: 'comparison',
    notes:
      'Defender que a vantagem inicial nao e segredo tecnologico, e execucao local com estrutura e aprendizagem.',
  },
  {
    section: 'Seguranca',
    title: 'Trust & Safety desde o MVP',
    subtitle: 'Texto livre nao vira porta aberta.',
    bullets: [
      'allow: entra no fluxo normal.',
      'sensitiveReview: pode exigir analise.',
      'block: bloqueia e nao guarda.',
      'unknownReview: nao publica automaticamente.',
    ],
    visual: 'admission',
    notes:
      'Nao revelar termos internos. Mostrar maturidade: permitido entra, sensivel analisa, proibido bloqueia, vago nao publica.',
  },
  {
    section: 'Mercado',
    title: 'Foco inicial: Maputo',
    subtitle: 'Marketplace local precisa de densidade antes de escala.',
    bullets: [
      'Piloto controlado por categorias de alta frequencia.',
      'Recrutar poucos prestadores selecionados e acompanhar resposta.',
      'Ativar clientes por necessidades concretas.',
      'Medir pedidos, aceite, tempo de resposta, qualidade e repeticao.',
    ],
    visual: 'maputo',
    notes:
      'Evitar prometer expansao nacional imediata. A decisao forte e foco geografico para aprender rapido.',
  },
  {
    section: 'Negocio',
    title: 'Modelo futuro, validado por etapas',
    subtitle: 'Primeiro liquidez e confianca. Depois monetizacao.',
    bullets: [
      'Comissao por servico quando pagamentos reais forem integrados.',
      'Planos PRO para prestadores.',
      'Destaques pagos transparentes e leads qualificados.',
      'Parcerias locais com empresas e profissionais.',
    ],
    visual: 'business',
    notes:
      'A resposta correta e nao forcar receita antes da hora. O piloto decide qual modelo vem primeiro.',
  },
  {
    section: 'Investimento',
    title: 'Pedido recomendado: 700.000 MZN',
    subtitle: 'Capital para sair de MVP funcional para piloto real.',
    bullets: [
      '350.000 MZN: enxuto.',
      '700.000 MZN: recomendado.',
      '1.250.000 MZN: robusto.',
      'Possivel tranche ligada a metas do piloto.',
    ],
    visual: 'ask',
    notes:
      'Explicar que o dinheiro nao e para construir do zero. E para polir, recrutar, ativar, operar e medir.',
  },
  {
    section: 'Plano',
    title: '60 a 90 dias: piloto controlado',
    subtitle: 'Aprender com utilizadores reais antes de escalar.',
    bullets: [
      'Polir UX e preparar demo final.',
      'Validar Android fisico e suporte inicial.',
      'Recrutar prestadores e ativar clientes em Maputo.',
      'Medir sinais reais e reforcar server-side antes de producao ampla.',
    ],
    visual: 'timeline',
    notes:
      'Fechar com plano concreto. O proximo risco e mercado, nao uma lista infinita de features.',
  },
  {
    section: 'Fecho',
    title: 'Vamos validar Maputo juntos',
    subtitle: 'Produto navegavel, tese clara, proximo passo mensuravel.',
    body:
      'O investimento financia aprendizagem estruturada: prestadores reais, clientes reais e metricas reais.',
    chips: ['MVP funcional', 'Piloto controlado', '700.000 MZN'],
    visual: 'closing',
    notes:
      'Encerrar simples: o ChegaJa tem base tecnica e precisa provar mercado com disciplina.',
  },
];

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function pickFile(candidates) {
  return candidates.find((candidate) => candidate && fs.existsSync(candidate));
}

function copyMedia() {
  ensureDir(mediaDir);
  const copied = {};
  for (const item of sourceImages) {
    const source = pickFile(item.candidates);
    if (!source) continue;
    const ext = path.extname(source) || '.png';
    const target = path.join(mediaDir, `${item.key}${ext}`);
    fs.copyFileSync(source, target);
    copied[item.key] = {
      source,
      target,
      relative: path.relative(outDir, target).replace(/\\/g, '/'),
      title: item.title,
    };
  }
  return copied;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function createHtmlSlide(slide, index, media) {
  const bullets = slide.bullets
    ? `<ul>${slide.bullets.map((b) => `<li>${escapeHtml(b)}</li>`).join('')}</ul>`
    : '';
  const chips = slide.chips
    ? `<div class="chips">${slide.chips.map((c) => `<span>${escapeHtml(c)}</span>`).join('')}</div>`
    : '';
  const image =
    slide.imageKey && media[slide.imageKey]
      ? `<div class="device"><img src="${media[slide.imageKey].relative}" alt="${escapeHtml(
          media[slide.imageKey].title,
        )}" /></div>`
      : '';

  return `
    <section class="slide slide-${index + 1} visual-${slide.visual}">
      <div class="slide-top">
        <span class="section">${escapeHtml(slide.section)}</span>
        <span class="count">${String(index + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}</span>
      </div>
      <div class="content">
        <div class="copy">
          ${slide.kicker ? `<div class="kicker">${escapeHtml(slide.kicker)}</div>` : ''}
          <h1>${escapeHtml(slide.title)}</h1>
          ${slide.subtitle ? `<h2>${escapeHtml(slide.subtitle)}</h2>` : ''}
          ${slide.body ? `<p class="body">${escapeHtml(slide.body)}</p>` : ''}
          ${bullets}
          ${chips}
        </div>
        <div class="visual">
          ${image || createHtmlVisual(slide.visual)}
        </div>
      </div>
      <div class="footer">ChegaJa investor pack P0.5</div>
    </section>`;
}

function createHtmlVisual(type) {
  const visualMap = {
    brand: `
      <div class="brand-orbit">
        <div class="logo-mark">CJ</div>
        <div class="orbit-card a">Cliente</div>
        <div class="orbit-card b">Prestador</div>
        <div class="orbit-card c">Confianca</div>
      </div>`,
    problemFlow: `
      <div class="flow-grid">
        <div>Contactos soltos</div><b></b><div>Pouco contexto</div><b></b><div>Mais risco</div>
      </div>`,
    flow: `
      <div class="steps">
        <span>Procurar</span><span>Pedir</span><span>Conversar</span><span>Executar</span><span>Avaliar</span>
      </div>`,
    screens: `
      <div class="module-grid">
        <span>Pedidos</span><span>Perfis</span><span>Portfolio</span><span>Discovery</span><span>Admin</span><span>Safety</span>
      </div>`,
    comparison: `
      <div class="compare">
        <div><strong>Lista simples</strong><p>Nome, contacto e pouca confianca.</p></div>
        <div><strong>ChegaJa</strong><p>Pedido, perfil, portfolio, reputacao e regras.</p></div>
      </div>`,
    admission: `
      <div class="matrix">
        <div class="allow">allow</div><div class="review">sensitiveReview</div>
        <div class="block">block</div><div class="unknown">unknownReview</div>
      </div>`,
    maputo: `
      <div class="map-card"><div class="pin"></div><strong>Maputo</strong><span>Piloto local com densidade</span></div>`,
    business: `
      <div class="stage-list"><span>Agora: piloto</span><span>Depois: pagamentos</span><span>Escala: PRO + leads</span></div>`,
    ask: `
      <div class="ask-card"><strong>700.000 MZN</strong><span>piloto recomendado</span><div class="bar"><i style="width:20%"></i><i style="width:15%"></i><i style="width:20%"></i><i style="width:15%"></i><i style="width:10%"></i><i style="width:10%"></i><i style="width:10%"></i></div></div>`,
    timeline: `
      <div class="timeline"><span>Preparar</span><span>Recrutar</span><span>Pilotar</span><span>Medir</span></div>`,
    closing: `
      <div class="closing-mark">ChegaJa</div>`,
  };
  return visualMap[type] || '';
}

function writeHtml(media) {
  const html = `<!doctype html>
<html lang="pt">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ChegaJa Investor Deck P0.5</title>
  <style>
    @page { size: 16in 9in; margin: 0; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: #0b1220;
      color: #111827;
      font-family: Arial, Helvetica, sans-serif;
    }
    .slide {
      position: relative;
      width: 16in;
      height: 9in;
      padding: .55in .68in;
      page-break-after: always;
      overflow: hidden;
      background:
        linear-gradient(135deg, rgba(20, 184, 166, .12), rgba(37, 99, 235, .06)),
        #f6f8f8;
    }
    .slide::after {
      content: "";
      position: absolute;
      right: -.8in;
      bottom: -.95in;
      width: 3.2in;
      height: 3.2in;
      border-radius: 999px;
      background: rgba(20, 184, 166, .12);
    }
    .slide-top, .footer {
      position: relative;
      z-index: 2;
      display: flex;
      justify-content: space-between;
      color: #64748b;
      font-size: 13px;
      letter-spacing: 0;
      text-transform: uppercase;
      font-weight: 700;
    }
    .footer {
      position: absolute;
      left: .68in;
      right: .68in;
      bottom: .35in;
      text-transform: none;
      font-weight: 400;
    }
    .content {
      position: relative;
      z-index: 2;
      display: grid;
      grid-template-columns: 1.04fr .96fr;
      gap: .5in;
      height: 7.4in;
      align-items: center;
    }
    .copy { max-width: 6.85in; }
    .kicker {
      display: inline-flex;
      color: #0f766e;
      background: rgba(20, 184, 166, .14);
      border: 1px solid rgba(20, 184, 166, .28);
      border-radius: 999px;
      padding: 8px 14px;
      font-size: 14px;
      font-weight: 700;
      margin-bottom: 24px;
    }
    h1 {
      margin: 0;
      font-size: 58px;
      line-height: 1.03;
      color: #111827;
      letter-spacing: 0;
    }
    h2 {
      margin: 20px 0 0;
      font-size: 25px;
      line-height: 1.26;
      color: #334155;
      font-weight: 600;
      letter-spacing: 0;
    }
    .body {
      margin: 26px 0 0;
      color: #475569;
      font-size: 24px;
      line-height: 1.35;
    }
    ul {
      margin: 30px 0 0;
      padding: 0;
      display: grid;
      gap: 15px;
      list-style: none;
    }
    li {
      position: relative;
      padding-left: 30px;
      color: #334155;
      font-size: 22px;
      line-height: 1.28;
    }
    li::before {
      content: "";
      position: absolute;
      left: 0;
      top: 10px;
      width: 11px;
      height: 11px;
      border-radius: 99px;
      background: #14b8a6;
    }
    .chips {
      margin-top: 30px;
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }
    .chips span {
      padding: 10px 14px;
      border: 1px solid #b6dcd7;
      border-radius: 999px;
      color: #0f766e;
      background: #e7faf7;
      font-weight: 700;
      font-size: 16px;
    }
    .visual {
      min-height: 5.6in;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .device {
      width: 100%;
      border-radius: 24px;
      padding: 14px;
      background: #ffffff;
      border: 1px solid #d7dee8;
      box-shadow: 0 24px 70px rgba(15, 23, 42, .16);
    }
    .device img {
      width: 100%;
      display: block;
      border-radius: 16px;
    }
    .brand-orbit {
      position: relative;
      width: 5.4in;
      height: 5.4in;
      border-radius: 32px;
      background: #0b1220;
      color: white;
      box-shadow: 0 24px 70px rgba(15, 23, 42, .25);
    }
    .logo-mark {
      position: absolute;
      left: 50%;
      top: 50%;
      transform: translate(-50%, -50%);
      width: 1.45in;
      height: 1.45in;
      border-radius: 28px;
      background: #14b8a6;
      display: grid;
      place-items: center;
      font-size: 42px;
      font-weight: 800;
    }
    .orbit-card {
      position: absolute;
      padding: 16px 18px;
      border-radius: 18px;
      background: rgba(255,255,255,.12);
      border: 1px solid rgba(255,255,255,.16);
      font-weight: 700;
    }
    .orbit-card.a { left: .55in; top: .7in; }
    .orbit-card.b { right: .45in; top: 2.25in; }
    .orbit-card.c { left: 1.3in; bottom: .65in; }
    .flow-grid, .steps, .module-grid, .compare, .matrix, .map-card, .stage-list, .ask-card, .timeline, .closing-mark {
      width: 100%;
    }
    .flow-grid, .steps, .module-grid, .stage-list, .timeline {
      display: grid;
      gap: 16px;
    }
    .flow-grid div, .steps span, .module-grid span, .stage-list span, .timeline span {
      padding: 22px;
      background: #fff;
      border: 1px solid #d7dee8;
      border-radius: 18px;
      font-weight: 800;
      color: #111827;
      box-shadow: 0 14px 35px rgba(15,23,42,.08);
    }
    .flow-grid b {
      height: 24px;
      width: 2px;
      background: #14b8a6;
      justify-self: center;
    }
    .module-grid {
      grid-template-columns: repeat(2, 1fr);
    }
    .compare {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }
    .compare div {
      min-height: 3.4in;
      border-radius: 22px;
      padding: 26px;
      background: #fff;
      border: 1px solid #d7dee8;
      box-shadow: 0 14px 35px rgba(15,23,42,.08);
    }
    .compare div:last-child {
      background: #0b1220;
      color: #fff;
    }
    .compare strong {
      display: block;
      font-size: 26px;
      margin-bottom: 18px;
    }
    .compare p {
      margin: 0;
      font-size: 20px;
      line-height: 1.3;
      color: inherit;
    }
    .matrix {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
    }
    .matrix div {
      min-height: 1.35in;
      border-radius: 20px;
      display: grid;
      place-items: center;
      font-size: 24px;
      font-weight: 800;
      color: #0b1220;
      background: #fff;
      border: 1px solid #d7dee8;
    }
    .matrix .allow { background: #dcfce7; }
    .matrix .review { background: #fef3c7; }
    .matrix .block { background: #fee2e2; }
    .matrix .unknown { background: #dbeafe; }
    .map-card, .ask-card {
      min-height: 4.6in;
      border-radius: 30px;
      background: #0b1220;
      color: white;
      display: flex;
      flex-direction: column;
      justify-content: center;
      padding: 38px;
      box-shadow: 0 24px 70px rgba(15,23,42,.25);
    }
    .pin {
      width: .9in;
      height: .9in;
      background: #14b8a6;
      border-radius: 999px 999px 999px 0;
      transform: rotate(-45deg);
      margin-bottom: .45in;
    }
    .map-card strong, .ask-card strong, .closing-mark {
      font-size: 48px;
      line-height: 1.02;
      font-weight: 900;
    }
    .map-card span, .ask-card span {
      font-size: 22px;
      color: #cbd5e1;
      margin-top: 14px;
    }
    .bar {
      display: flex;
      overflow: hidden;
      height: 22px;
      border-radius: 999px;
      margin-top: 34px;
      background: rgba(255,255,255,.18);
    }
    .bar i { display: block; height: 100%; }
    .bar i:nth-child(1) { background: #14b8a6; }
    .bar i:nth-child(2) { background: #2563eb; }
    .bar i:nth-child(3) { background: #22c55e; }
    .bar i:nth-child(4) { background: #f59e0b; }
    .bar i:nth-child(5) { background: #38bdf8; }
    .bar i:nth-child(6) { background: #a78bfa; }
    .bar i:nth-child(7) { background: #e2e8f0; }
    .closing-mark {
      color: #14b8a6;
      background: #0b1220;
      min-height: 4in;
      display: grid;
      place-items: center;
      border-radius: 32px;
      box-shadow: 0 24px 70px rgba(15,23,42,.25);
    }
    @media screen {
      body { padding: 32px; }
      .slide { margin: 0 auto 32px; box-shadow: 0 20px 80px rgba(0,0,0,.35); }
    }
  </style>
</head>
<body>
  ${slides.map((slide, index) => createHtmlSlide(slide, index, media)).join('\n')}
</body>
</html>`;

  fs.writeFileSync(htmlPath, html.replace(/[ \t]+$/gm, ''), 'utf8');
}

function addTextBox(slide, text, x, y, w, h, opts = {}) {
  slide.addText(text, {
    x,
    y,
    w,
    h,
    margin: 0,
    breakLine: false,
    fit: 'shrink',
    fontFace: opts.fontFace || 'Arial',
    fontSize: opts.fontSize || 16,
    bold: opts.bold || false,
    color: opts.color || palette.ink,
    valign: opts.valign || 'top',
    align: opts.align || 'left',
    transparency: opts.transparency || 0,
  });
}

function addPill(slide, text, x, y, w, color = palette.tealDark, fill = 'E7FAF7') {
  slide.addShape(SHAPE.roundRect, {
    x,
    y,
    w,
    h: 0.36,
    rectRadius: 0.08,
    fill: { color: fill },
    line: { color: 'B6DCD7', transparency: 0 },
  });
  addTextBox(slide, text, x + 0.12, y + 0.09, w - 0.24, 0.18, {
    fontSize: 9,
    bold: true,
    color,
    align: 'center',
  });
}

function addHeader(slide, item, index) {
  addTextBox(slide, item.section.toUpperCase(), 0.55, 0.35, 2.4, 0.22, {
    fontSize: 8,
    bold: true,
    color: palette.muted,
  });
  addTextBox(slide, `${String(index + 1).padStart(2, '0')} / ${String(slides.length).padStart(2, '0')}`, 11.8, 0.35, 0.9, 0.22, {
    fontSize: 8,
    bold: true,
    color: palette.muted,
    align: 'right',
  });
}

function addBullets(slide, bullets, x, y, w) {
  bullets.forEach((bullet, idx) => {
    const yy = y + idx * 0.56;
    slide.addShape(SHAPE.ellipse, {
      x,
      y: yy + 0.08,
      w: 0.11,
      h: 0.11,
      fill: { color: palette.teal },
      line: { color: palette.teal },
    });
    addTextBox(slide, bullet, x + 0.27, yy, w - 0.27, 0.38, {
      fontSize: 13.5,
      color: '334155',
    });
  });
}

function addImageCard(slide, mediaItem, x, y, w, h) {
  slide.addShape(SHAPE.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.16,
    fill: { color: palette.white },
    line: { color: palette.line },
    shadow: { type: 'outer', opacity: 0.15, blur: 2, angle: 45, distance: 2 },
  });
  if (mediaItem) {
    slide.addImage({
      path: mediaItem.target,
      x: x + 0.18,
      y: y + 0.18,
      w: w - 0.36,
      h: h - 0.36,
      sizingCrop: true,
    });
  }
}

function addVisual(slide, item, media) {
  const x = 7.12;
  const y = 1.28;
  const w = 5.55;
  const h = 5.2;
  if (item.imageKey) {
    addImageCard(slide, media[item.imageKey], x, y, w, h);
    return;
  }

  if (item.visual === 'brand' || item.visual === 'closing') {
    slide.addShape(SHAPE.roundRect, {
      x: 7.2,
      y: 1.35,
      w: 5.25,
      h: 5.25,
      rectRadius: 0.2,
      fill: { color: palette.navy },
      line: { color: palette.navy },
      shadow: { type: 'outer', opacity: 0.2, blur: 2, angle: 45, distance: 2 },
    });
    addTextBox(slide, item.visual === 'brand' ? 'CJ' : 'ChegaJa', 8.45, 3.25, 2.8, 0.6, {
      fontSize: item.visual === 'brand' ? 34 : 28,
      bold: true,
      color: palette.teal,
      align: 'center',
    });
    ['Cliente', 'Prestador', 'Confianca'].forEach((label, idx) => {
      const positions = [
        [7.55, 2.0],
        [10.35, 3.25],
        [8.4, 5.0],
      ];
      addPill(slide, label, positions[idx][0], positions[idx][1], 1.35, palette.white, '1F2937');
    });
    return;
  }

  if (item.visual === 'admission') {
    const cells = [
      ['allow', 'DCFCE7', palette.tealDark],
      ['sensitiveReview', 'FEF3C7', '92400E'],
      ['block', 'FEE2E2', '991B1B'],
      ['unknownReview', 'DBEAFE', '1D4ED8'],
    ];
    cells.forEach(([label, fill, color], idx) => {
      const col = idx % 2;
      const row = Math.floor(idx / 2);
      slide.addShape(SHAPE.roundRect, {
        x: x + col * 2.75,
        y: y + row * 1.75,
        w: 2.55,
        h: 1.45,
        rectRadius: 0.14,
        fill: { color: fill },
        line: { color: palette.line },
      });
      addTextBox(slide, label, x + col * 2.75 + 0.15, y + row * 1.75 + 0.55, 2.25, 0.3, {
        fontSize: 16,
        bold: true,
        color,
        align: 'center',
      });
    });
    return;
  }

  if (item.visual === 'ask') {
    slide.addShape(SHAPE.roundRect, {
      x,
      y,
      w,
      h: 4.6,
      rectRadius: 0.2,
      fill: { color: palette.navy },
      line: { color: palette.navy },
    });
    addTextBox(slide, '700.000 MZN', x + 0.45, y + 1.25, w - 0.9, 0.6, {
      fontSize: 34,
      bold: true,
      color: palette.white,
      align: 'center',
    });
    addTextBox(slide, 'piloto recomendado', x + 0.45, y + 1.95, w - 0.9, 0.35, {
      fontSize: 16,
      color: 'CBD5E1',
      align: 'center',
    });
    const labels = ['UI/UX', 'Piloto', 'Marketing', 'Operacao', 'Infra', 'Juridico', 'Reserva'];
    labels.forEach((label, idx) => {
      addPill(slide, label, x + 0.45 + (idx % 2) * 2.25, y + 2.85 + Math.floor(idx / 2) * 0.48, 1.85, palette.white, '1F2937');
    });
    return;
  }

  const labels = {
    problemFlow: ['Contactos soltos', 'Pouco contexto', 'Mais risco'],
    flow: ['Procurar', 'Pedir', 'Conversar', 'Executar', 'Avaliar'],
    screens: ['Pedidos', 'Perfis', 'Portfolio', 'Discovery', 'Admin', 'Safety'],
    comparison: ['Lista simples', 'Infraestrutura ChegaJa'],
    maputo: ['Maputo', 'Categorias frequentes', 'Densidade local'],
    business: ['Agora: piloto', 'Depois: pagamentos', 'Escala: PRO + leads'],
    timeline: ['Preparar', 'Recrutar', 'Pilotar', 'Medir'],
  }[item.visual] || ['ChegaJa'];

  labels.forEach((label, idx) => {
    const yy = y + idx * 0.74;
    slide.addShape(SHAPE.roundRect, {
      x,
      y: yy,
      w,
      h: 0.55,
      rectRadius: 0.1,
      fill: { color: idx % 2 === 0 ? palette.white : 'E7FAF7' },
      line: { color: palette.line },
      shadow: { type: 'outer', opacity: 0.08, blur: 1, angle: 45, distance: 1 },
    });
    addTextBox(slide, label, x + 0.25, yy + 0.16, w - 0.5, 0.2, {
      fontSize: 15,
      bold: true,
      color: idx % 2 === 0 ? palette.ink : palette.tealDark,
    });
  });
}

async function writePptx(media) {
  const pptx = new pptxgen();
  pptx.layout = 'LAYOUT_WIDE';
  pptx.author = 'ChegaJa';
  pptx.company = 'ChegaJa';
  pptx.subject = 'Investor pitch';
  pptx.title = 'ChegaJa Investor Deck P0.5';
  pptx.lang = 'pt-PT';
  pptx.theme = {
    headFontFace: 'Arial',
    bodyFontFace: 'Arial',
    lang: 'pt-PT',
  };

  slides.forEach((item, index) => {
    const slide = pptx.addSlide();
    slide.background = { color: palette.bg };
    slide.addShape(SHAPE.rect, {
      x: 0,
      y: 0,
      w: 13.333,
      h: 7.5,
      fill: { color: palette.bg },
      line: { color: palette.bg },
    });
    slide.addShape(SHAPE.arc, {
      x: 11.6,
      y: 6.0,
      w: 2.6,
      h: 2.6,
      adjustPoint: 0.5,
      fill: { color: 'D8F4EF', transparency: 5 },
      line: { color: 'D8F4EF', transparency: 100 },
    });
    addHeader(slide, item, index);
    if (item.kicker) {
      addPill(slide, item.kicker, 0.72, 1.12, 1.55);
    }
    addTextBox(slide, item.title, 0.72, item.kicker ? 1.64 : 1.22, 6.0, 1.08, {
      fontSize: item.title.length > 36 ? 27 : 33,
      bold: true,
      color: palette.ink,
    });
    if (item.subtitle) {
      addTextBox(slide, item.subtitle, 0.72, item.kicker ? 2.76 : 2.34, 5.8, 0.6, {
        fontSize: 16,
        color: '334155',
      });
    }
    if (item.body) {
      addTextBox(slide, item.body, 0.72, 3.15, 5.75, 0.75, {
        fontSize: 16,
        color: '475569',
      });
    }
    if (item.bullets) {
      addBullets(slide, item.bullets, 0.72, 3.15, 5.9);
    }
    if (item.chips) {
      item.chips.forEach((chip, idx) => addPill(slide, chip, 0.72 + idx * 1.78, 4.25, 1.58));
    }
    addVisual(slide, item, media);
    addTextBox(slide, 'ChegaJa investor pack P0.5', 0.72, 7.1, 2.5, 0.15, {
      fontSize: 7,
      color: palette.muted,
    });
    slide.addNotes(item.notes);
  });

  await pptx.writeFile({ fileName: pptxPath });
}

async function writePdf() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
  await page.goto(`file://${htmlPath.replace(/\\/g, '/')}`, { waitUntil: 'load' });
  await page.addStyleTag({
    content:
      '@media screen { body { padding: 0 !important; } .slide { margin: 0 !important; box-shadow: none !important; } }',
  });
  await page.screenshot({ path: previewPath, fullPage: false });
  await page.pdf({
    path: pdfPath,
    width: '16in',
    height: '9in',
    printBackground: true,
    preferCSSPageSize: true,
    margin: { top: 0, right: 0, bottom: 0, left: 0 },
  });
  await browser.close();
}

function writeManifest(media) {
  const manifest = {
    generatedAt: new Date().toISOString(),
    title: 'ChegaJa Investor Deck P0.5',
    outputs: {
      pptx: path.relative(root, pptxPath).replace(/\\/g, '/'),
      html: path.relative(root, htmlPath).replace(/\\/g, '/'),
      pdf: path.relative(root, pdfPath).replace(/\\/g, '/'),
      preview: path.relative(root, previewPath).replace(/\\/g, '/'),
    },
    slideCount: slides.length,
    sources: {
      docs: [
        'docs/investor/P0_1_DECK_INVESTIDOR_STRUCTURE.md',
        'docs/investor/P0_2_ROTEIRO_DEMO_APP.md',
        'docs/investor/P0_3_ONE_PAGER_INVESTIDOR.md',
        'docs/investor/P0_4_QA_PERGUNTAS_DIFICEIS_INVESTIDOR.md',
      ],
      media: Object.fromEntries(
        Object.entries(media).map(([key, value]) => [
          key,
          {
            source: value.source,
            packaged: path.relative(root, value.target).replace(/\\/g, '/'),
          },
        ]),
      ),
    },
  };
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
}

async function main() {
  ensureDir(outDir);
  const media = copyMedia();
  writeHtml(media);
  await writePptx(media);
  await writePdf();
  writeManifest(media);

  console.log(JSON.stringify({
    pptxPath,
    htmlPath,
    pdfPath,
    previewPath,
    manifestPath,
    slideCount: slides.length,
    mediaKeys: Object.keys(media),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
