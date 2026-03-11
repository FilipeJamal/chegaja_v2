const fs = require('fs');
const path = require('path');
const pptxgen = require('pptxgenjs');

const html2pptx = require('C:/Users/HP/.codex/skills/pptx-official/scripts/html2pptx.js');

const workspace = 'C:/Users/HP/Documents/ProjetosFlutter/chegaja_v2';
const outputDir = path.join(workspace, 'artifacts', 'presentation_chegaja');
const slidesDir = path.join(outputDir, 'slides');
const mediaDir = path.join(outputDir, 'media');
const outputFile = path.join(outputDir, 'ChegaJa_Apresentacao_App.pptx');

const assets = {
  logo: path.join(workspace, 'assets', 'images', 'app_icon.png'),
  splash: path.join(workspace, 'assets', 'images', 'splash_logo.png'),
  roleSelector: path.join(workspace, 'artifacts', 'role_selector.png'),
  clientHome: path.join(workspace, 'artifacts', 'cliente_home_loaded.png'),
  providerHome: path.join(workspace, 'artifacts', 'prestador_home_loaded.png'),
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeSlide(name, html) {
  const filePath = path.join(slidesDir, name);
  fs.writeFileSync(filePath, html, 'utf8');
  return filePath;
}

function prepareMedia() {
  ensureDir(mediaDir);
  const result = {};
  for (const [key, source] of Object.entries(assets)) {
    const filename = path.basename(source);
    const target = path.join(mediaDir, filename);
    fs.copyFileSync(source, target);
    result[key] = path.relative(slidesDir, target).replace(/\\/g, '/');
  }
  return result;
}

function shellHtml(content, title = 'ChegaJa') {
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>${title}</title>
  <style>
    html { background: #F6F8F8; }
    body {
      width: 720pt;
      height: 405pt;
      margin: 0;
      padding: 0;
      background: #F6F8F8;
      color: #111418;
      font-family: Arial, Helvetica, sans-serif;
      display: flex;
      overflow: hidden;
    }
    * { box-sizing: border-box; }
    .slide {
      width: 100%;
      height: 100%;
      padding: 24pt 28pt;
      display: flex;
      flex-direction: column;
    }
    h1, h2, h3, h4, p, ul, ol { margin: 0; }
    h1 {
      font-size: 28pt;
      line-height: 1.12;
      font-weight: 700;
    }
    h2 {
      font-size: 19pt;
      line-height: 1.18;
      font-weight: 700;
    }
    h3 {
      font-size: 14pt;
      line-height: 1.2;
      font-weight: 700;
    }
    h4 {
      font-size: 12pt;
      line-height: 1.2;
      font-weight: 700;
      letter-spacing: 1pt;
      text-transform: uppercase;
      color: #12BA9B;
    }
    p, li {
      font-size: 10.8pt;
      line-height: 1.32;
      color: #46515D;
    }
    ul, ol { padding-left: 18pt; }
    li { margin-bottom: 4pt; }
    .muted { color: #6B7280; }
    .small { font-size: 9.5pt; line-height: 1.28; }
    .tiny { font-size: 8.5pt; line-height: 1.2; color: #6B7280; }
    .brand { color: #12BA9B; }
    .navy { color: #0B3C5D; }
    .accent { color: #FF5A5F; }
    .row {
      display: flex;
      gap: 12pt;
      width: 100%;
    }
    .col {
      display: flex;
      flex-direction: column;
      gap: 12pt;
    }
    .card {
      background: #FFFFFF;
      border: 1pt solid #DDE5E8;
      border-radius: 16pt;
      padding: 12pt 14pt;
      box-shadow: 0 6pt 18pt rgba(17, 20, 24, 0.08);
    }
    .soft-card {
      background: #EEF7F5;
      border: 1pt solid #CFEAE4;
      border-radius: 16pt;
      padding: 12pt 14pt;
    }
    .tag {
      display: inline-flex;
      background: #E9F6F2;
      border: 1pt solid #CDE9E2;
      border-radius: 999pt;
      padding: 4pt 10pt;
      margin-right: 6pt;
      margin-bottom: 6pt;
    }
    .tag p {
      font-size: 9.5pt;
      line-height: 1;
      color: #0B3C5D;
      font-weight: 700;
    }
    .divider {
      width: 84pt;
      height: 4pt;
      background: #12BA9B;
      border-radius: 999pt;
      margin-top: 10pt;
    }
    .phone {
      background: #FFFFFF;
      border: 1pt solid #D8E2E6;
      border-radius: 24pt;
      padding: 8pt;
      box-shadow: 0 8pt 24pt rgba(17, 20, 24, 0.12);
    }
    .phone img {
      width: 100%;
      height: auto;
      border-radius: 16pt;
      display: block;
    }
    .step-row {
      display: flex;
      align-items: center;
      gap: 8pt;
      width: 100%;
      margin-top: 6pt;
    }
    .step {
      flex: 1;
      min-height: 66pt;
      background: #FFFFFF;
      border: 1pt solid #DDE5E8;
      border-radius: 14pt;
      padding: 10pt 12pt;
    }
    .arrow {
      width: 18pt;
      display: flex;
      justify-content: center;
      align-items: center;
      padding-top: 10pt;
    }
    .arrow p {
      font-size: 18pt;
      color: #12BA9B;
      font-weight: 700;
      line-height: 1;
    }
    .footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: auto;
      padding-top: 4pt;
    }
    .footer-line {
      width: 100%;
      height: 1pt;
      background: #DDE5E8;
      margin-top: 10pt;
    }
    .screenshot-caption {
      text-align: center;
      margin-top: 2pt;
    }
  </style>
</head>
<body>
${content}
</body>
</html>`;
}

function buildSlides(media) {
  return [
    writeSlide(
      '01_capa.html',
      shellHtml(`
      <div class="slide" style="background:#F6F8F8;">
        <div class="row" style="gap:20pt; align-items:center; flex:1;">
          <div class="col" style="width:62%;">
            <div class="tag"><p>Marketplace de serviços</p></div>
            <div class="tag"><p>Flutter + Firebase</p></div>
            <h1>ChegaJá<br/><span class="brand">Como o aplicativo funciona</span></h1>
            <div class="divider"></div>
            <p style="margin-top:12pt; font-size:11pt;">
              Visão executiva do produto com base no código, nos fluxos
              principais e nas integrações operacionais.
            </p>
            <div class="card" style="margin-top:12pt; padding:10pt 12pt;">
              <h3>O que esta apresentação cobre</h3>
              <ul style="margin-top:4pt;">
                <li>proposta de valor e objetivo do app</li>
                <li>fluxo completo do cliente e do prestador</li>
                <li>pedidos, chat, mapas, pagamentos, KYC e suporte</li>
                <li>camada administrativa da operação</li>
              </ul>
            </div>
          </div>
          <div class="col" style="width:38%; align-items:center; justify-content:center;">
            <div class="card" style="padding:14pt; width:100%; display:flex; align-items:center; justify-content:center;">
              <div id="cover-art" class="placeholder" style="width:190pt; height:190pt; border-radius:20pt;"></div>
            </div>
            <p class="small screenshot-caption">Marca e identidade visual usadas no app</p>
          </div>
        </div>
        <div class="footer">
          <p class="tiny">ChegaJá v2</p>
          <p class="tiny">Análise funcional do aplicativo</p>
        </div>
      </div>`),
    ),
    writeSlide(
      '02_visao_geral.html',
      shellHtml(`
      <div class="slide">
        <h4>Visão Geral</h4>
        <h2 style="margin-top:8pt;">O que é o ChegaJá</h2>
        <p style="margin-top:10pt; max-width:600pt;">
          O ChegaJá é um marketplace mobile de serviços locais. O produto conecta
          clientes que precisam de ajuda imediata, agendada ou por orçamento com
          prestadores que podem aceitar, negociar, executar e finalizar o serviço.
        </p>
        <div class="row" style="margin-top:18pt; flex:1;">
          <div class="col" style="width:33%;">
            <div class="soft-card">
              <h3>Objetivo de negócio</h3>
              <ul style="margin-top:8pt;">
                <li>reduzir atrito na contratação de serviços</li>
                <li>dar previsibilidade ao cliente</li>
                <li>gerar pipeline de trabalho para prestadores</li>
              </ul>
            </div>
            <div class="card">
              <h3>Perfis da plataforma</h3>
              <ul style="margin-top:8pt;">
                <li>cliente</li>
                <li>prestador</li>
                <li>admin / operação</li>
              </ul>
            </div>
          </div>
          <div class="col" style="width:33%;">
            <div class="card">
              <h3>Formas de pedido</h3>
              <ul style="margin-top:8pt;">
                <li>imediato</li>
                <li>agendado</li>
                <li>por orçamento / proposta</li>
              </ul>
            </div>
            <div class="card">
              <h3>Camada tecnológica</h3>
              <ul style="margin-top:8pt;">
                <li>Flutter para cliente web/mobile</li>
                <li>Firebase Auth, Firestore, Functions e Storage</li>
                <li>Stripe, geolocalização, notificações e deep links</li>
              </ul>
            </div>
          </div>
          <div class="col" style="width:34%;">
            <div class="card">
              <h3>Capacidades chave</h3>
              <ul style="margin-top:8pt;">
                <li>matching por categoria e localização</li>
                <li>chat em tempo real com anexos e localização</li>
                <li>timeline do pedido e histórico de eventos</li>
                <li>pagamentos, onboarding de prestador e assinatura</li>
                <li>KYC, avaliação, no-show, suporte e painel admin</li>
              </ul>
            </div>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '03_entrada_e_navegacao.html',
      shellHtml(`
      <div class="slide">
        <h4>Entrada no Produto</h4>
        <h2 style="margin-top:8pt;">Primeiro passo: escolher o papel no ecossistema</h2>
        <div class="row" style="margin-top:12pt; flex:1;">
          <div class="col" style="width:43%;">
            <div class="phone" style="width:92%; margin:0 auto;">
              <div id="role-shot" class="placeholder" style="width:100%; height:250pt; border-radius:16pt;"></div>
            </div>
            <p class="small screenshot-caption">Tela real de entrada</p>
          </div>
          <div class="col" style="width:57%;">
            <div class="card">
              <h3>Como o acesso funciona</h3>
              <ul style="margin-top:8pt;">
                <li>o app inicia com autenticação anónima para reduzir fricção</li>
                <li>o utilizador escolhe entre “Sou cliente” e “Sou prestador”</li>
                <li>o papel ativo personaliza home, pedidos e chat</li>
              </ul>
            </div>
            <div class="card">
              <h3>Navegação principal</h3>
              <ul style="margin-top:8pt;">
                <li>cliente: Início, Meus pedidos, Mensagens, Perfil</li>
                <li>prestador: Início, Meus trabalhos, Mensagens, Perfil</li>
                <li>admin: painel com tickets, no-show, stories e métricas</li>
              </ul>
            </div>
            <div class="soft-card">
              <h3>Leitura estratégica</h3>
              <p style="margin-top:8pt;">
                O onboarding leva o utilizador ao contexto certo logo no primeiro toque.
              </p>
            </div>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '04_fluxo_cliente.html',
      shellHtml(`
      <div class="slide">
        <h4>Fluxo do Cliente</h4>
        <h2 style="margin-top:8pt;">Como o cliente descobre serviços e cria um pedido</h2>
        <div class="row" style="margin-top:14pt;">
          <div class="col" style="width:58%;">
            <div class="phone">
              <div id="client-shot" class="placeholder" style="width:100%; height:262pt; border-radius:16pt;"></div>
            </div>
            <p class="small screenshot-caption">Home do cliente com tabs de modo e pesquisa</p>
          </div>
          <div class="col" style="width:42%;">
            <div class="card">
              <h3>O que o cliente vê na home</h3>
              <ul style="margin-top:8pt;">
                <li>catálogo de serviços disponíveis</li>
                <li>separação por orçamento, agendado e imediato</li>
                <li>pesquisa de serviço e pesquisa de prestador</li>
                <li>atalhos para pedidos pendentes e mensagens</li>
              </ul>
            </div>
            <div class="soft-card">
              <h3>Criação do pedido</h3>
              <ul style="margin-top:8pt;">
                <li>escolhe a categoria</li>
                <li>define título, descrição e urgência</li>
                <li>informa localização automática ou manual</li>
                <li>pode deixar o matching automático ou convidar prestador específico</li>
              </ul>
            </div>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '05_jornada_pedido.html',
      shellHtml(`
      <div class="slide">
        <h4>Jornada End-to-End</h4>
        <h2 style="margin-top:8pt;">Fluxo completo do pedido dentro da plataforma</h2>
        <p style="margin-top:10pt;">
          O modelo de pedido suporta imediatismo, agendamento e negociação.
          A lógica do app controla transições como convite, proposta, aceitação,
          execução, confirmação de valor, conclusão e cancelamento.
        </p>
        <div class="step-row" style="margin-top:20pt;">
          <div class="step">
            <h3>1. Criação</h3>
            <p style="margin-top:6pt;">cliente abre pedido com categoria, modo, endereço e regra de preço</p>
          </div>
          <div class="arrow"><p>→</p></div>
          <div class="step">
            <h3>2. Matching</h3>
            <p style="margin-top:6pt;">plataforma procura prestador ou envia convite manual</p>
          </div>
          <div class="arrow"><p>→</p></div>
          <div class="step">
            <h3>3. Proposta</h3>
            <p style="margin-top:6pt;">prestador aceita, envia faixa min/max ou proposta direta</p>
          </div>
        </div>
        <div class="step-row">
          <div class="step">
            <h3>4. Aceite</h3>
            <p style="margin-top:6pt;">cliente escolhe o prestador ou confirma o valor proposto</p>
          </div>
          <div class="arrow"><p>→</p></div>
          <div class="step">
            <h3>5. Execução</h3>
            <p style="margin-top:6pt;">serviço entra em andamento com chat, mapa e contacto</p>
          </div>
          <div class="arrow"><p>→</p></div>
          <div class="step">
            <h3>6. Fecho</h3>
            <p style="margin-top:6pt;">valor final, pagamento, conclusão, avaliação ou tratamento de no-show/cancelamento</p>
          </div>
        </div>
        <div class="row" style="margin-top:16pt;">
          <div class="card" style="width:50%;">
            <h3>Estados tratados no domínio</h3>
            <p style="margin-top:8pt;">
              criado, aguarda_resposta_prestador, aguarda_resposta_cliente,
              aceito, em_andamento, aguarda_confirmacao_valor, concluído e cancelado.
            </p>
          </div>
          <div class="card" style="width:50%;">
            <h3>Proteções operacionais</h3>
            <p style="margin-top:8pt;">
              histórico do pedido, política de reembolso, motivos de cancelamento,
              revisão administrativa de no-show e regras de transição no serviço de pedidos.
            </p>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '06_fluxo_prestador.html',
      shellHtml(`
      <div class="slide">
        <h4>Fluxo do Prestador</h4>
        <h2 style="margin-top:8pt;">Como o prestador recebe, filtra e executa trabalho</h2>
        <div class="row" style="margin-top:12pt;">
          <div class="col" style="width:55%;">
            <div class="phone" style="width:94%; margin:0 auto;">
              <div id="provider-shot" class="placeholder" style="width:100%; height:252pt; border-radius:16pt;"></div>
            </div>
            <p class="small screenshot-caption">Home do prestador com estado online, KPIs e pedidos próximos</p>
          </div>
          <div class="col" style="width:45%;">
            <div class="card">
              <h3>Lógica principal do lado prestador</h3>
              <ul style="margin-top:8pt;">
                <li>ativa modo online para começar a receber pedidos</li>
                <li>define categorias de atuação e raio/localização</li>
                <li>aceita pedido aberto ou convite direto</li>
                <li>envia orçamento quando o serviço é por proposta</li>
              </ul>
            </div>
            <div class="soft-card">
              <h3>Operação diária</h3>
              <ul style="margin-top:8pt;">
                <li>acompanha trabalhos ativos e mensagens não lidas</li>
                <li>inicia serviço, propõe valor final e conclui</li>
                <li>acede a perfil, pagamentos, configurações, assinatura e KYC</li>
              </ul>
            </div>
            <p class="small" style="margin-top:2pt;">
              O matching considera categorias, estado online e distância geográfica.
            </p>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '07_confianca_e_comunicacao.html',
      shellHtml(`
      <div class="slide">
        <h4>Confiança e Comunicação</h4>
        <h2 style="margin-top:8pt;">Recursos que sustentam a experiência ponta a ponta</h2>
        <div class="row" style="margin-top:18pt; flex:1;">
          <div class="col" style="width:33%;">
            <div class="card">
              <h3>Chat operacional</h3>
              <ul style="margin-top:8pt;">
                <li>mensagens em tempo real por pedido</li>
                <li>favoritos, reações, edição e remoção</li>
                <li>status de digitando, entregue e visto</li>
                <li>envio de áudio e localização</li>
              </ul>
            </div>
            <div class="card">
              <h3>Mapa e localização</h3>
              <ul style="margin-top:8pt;">
                <li>captura da posição do pedido</li>
                <li>tracking do prestador quando online</li>
                <li>visualização de mapa no detalhe do pedido</li>
              </ul>
            </div>
          </div>
          <div class="col" style="width:33%;">
            <div class="card">
              <h3>Confiança</h3>
              <ul style="margin-top:8pt;">
                <li>avaliação do prestador no fim do serviço</li>
                <li>anexos e histórico de eventos do pedido</li>
                <li>tratamento de cancelamento e reembolso</li>
                <li>registo de no-show para mediação</li>
              </ul>
            </div>
            <div class="soft-card">
              <h3>Suporte e continuidade</h3>
              <ul style="margin-top:8pt;">
                <li>tickets de suporte no Firestore</li>
                <li>notificações push</li>
                <li>deep links para abrir pedido ou chat diretamente</li>
              </ul>
            </div>
          </div>
          <div class="col" style="width:34%;">
            <div class="card">
              <h3>Pagamentos e monetização</h3>
              <ul style="margin-top:8pt;">
                <li>cliente paga via Stripe Payment Sheet</li>
                <li>prestador faz onboarding Stripe Connect Express</li>
                <li>assinaturas Basic e Pro para aumentar exposição</li>
              </ul>
            </div>
            <div class="card">
              <h3>Compliance</h3>
              <ul style="margin-top:8pt;">
                <li>KYC com upload seguro de documento frente/verso</li>
                <li>status none, pending, approved ou rejected</li>
                <li>liberação operacional após aprovação</li>
              </ul>
            </div>
          </div>
        </div>
      </div>`),
    ),
    writeSlide(
      '08_backoffice_e_resumo.html',
      shellHtml(`
      <div class="slide">
        <h4>Operação da Plataforma</h4>
        <h2 style="margin-top:8pt;">Backoffice e resumo do valor do aplicativo</h2>
        <div class="row" style="margin-top:12pt; flex:1;">
          <div class="col" style="width:44%;">
            <div class="card">
              <h3>Painel administrativo</h3>
              <ul style="margin-top:8pt;">
                <li>dashboard com métricas-chave</li>
                <li>gestão de tickets de suporte</li>
                <li>decisão de casos de no-show</li>
                <li>moderação de stories</li>
              </ul>
            </div>
            <div class="soft-card">
              <h3>Resumo executivo</h3>
              <p style="margin-top:8pt;">
                O ChegaJá não é só catálogo. É um fluxo transacional completo:
                descoberta, matching, execução, pagamento e suporte.
              </p>
            </div>
          </div>
          <div class="col" style="width:56%;">
            <div class="card">
              <h3>Leitura final do produto</h3>
              <ul style="margin-top:8pt;">
                <li><b>Cliente:</b> encontra ajuda com previsibilidade e acompanhamento</li>
                <li><b>Prestador:</b> recebe trabalho relevante e gere a operação</li>
                <li><b>Operação:</b> monitoriza risco, suporte e performance</li>
              </ul>
            </div>
            <div class="step-row" style="margin-top:10pt;">
              <div class="step">
                <h3>Atrai</h3>
                <p style="margin-top:6pt;">entrada por necessidade imediata ou agendada</p>
              </div>
              <div class="arrow"><p>→</p></div>
              <div class="step">
                <h3>Converte</h3>
                <p style="margin-top:6pt;">matching, proposta, aceite e pagamento</p>
              </div>
              <div class="arrow"><p>→</p></div>
              <div class="step">
                <h3>Retém</h3>
                <p style="margin-top:6pt;">mensagens, avaliação, assinatura e reuso</p>
              </div>
            </div>
            <div class="footer-line"></div>
            <div class="footer">
              <p class="tiny">Conteúdo gerado a partir da análise do repositório Flutter/Firebase</p>
              <p class="tiny">ChegaJá v2</p>
            </div>
          </div>
        </div>
      </div>`),
    ),
  ];
}

async function main() {
  ensureDir(slidesDir);
  const media = prepareMedia();

  const pptx = new pptxgen();
  pptx.layout = 'LAYOUT_16x9';
  pptx.author = 'OpenAI Codex';
  pptx.company = 'ChegaJa';
  pptx.subject = 'Apresentacao do aplicativo ChegaJa';
  pptx.title = 'ChegaJa - Apresentacao do aplicativo';
  pptx.lang = 'pt-PT';
  pptx.theme = {
    headFontFace: 'Arial',
    bodyFontFace: 'Arial',
    lang: 'pt-PT',
  };

  const slideFiles = buildSlides(media);
  const imagePlans = {
    0: [{ id: 'cover-art', path: assets.logo }],
    2: [{ id: 'role-shot', path: assets.roleSelector }],
    3: [{ id: 'client-shot', path: assets.clientHome }],
    5: [{ id: 'provider-shot', path: assets.providerHome }],
  };

  for (const [index, slideFile] of slideFiles.entries()) {
    const { slide, placeholders } = await html2pptx(slideFile, pptx);
    const plans = imagePlans[index] ?? [];
    for (const plan of plans) {
      const box = placeholders.find((item) => item.id === plan.id);
      if (!box) continue;
      slide.addImage({
        path: plan.path,
        x: box.x,
        y: box.y,
        w: box.w,
        h: box.h,
      });
    }
  }

  await pptx.writeFile({ fileName: outputFile });
  console.log(outputFile);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
