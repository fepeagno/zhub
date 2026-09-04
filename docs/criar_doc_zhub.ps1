# criar_doc_zhub.ps1 — Gera Zhub_Apresentacao_Comercial.docx via Word COM

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ─── Color helper: Word long = R + G*256 + B*65536 ──────────────────
function WC([int]$r,[int]$g,[int]$b){ return [int]($r + $g*256 + $b*65536) }

$GOLD        = WC 201 168  76   # #C9A84C
$GOLD_LIGHT  = WC 219 186  94   # #DBBA5E
$GOLD_BG     = WC 253 246 227   # #FDF6E3 — fundo champagne
$DARK        = WC  17  17  17   # #111111
$DARK_WARM   = WC  20  18  12   # #14120C
$DARK_CARD   = WC  32  30  22   # #201E16
$WHITE       = WC 255 255 255
$OFF_WHITE   = WC 238 232 212   # #EEE8D4
$TEXT_DARK   = WC  26  24  18   # quase preto quente
$TEXT_MID    = WC  80  72  56   # cinza quente médio
$GOLD_DARK   = WC 124  98  12   # #7C620C

# ─── Word constants ─────────────────────────────────────────────────
$wdLeft     = 0; $wdCenter = 1; $wdRight = 2; $wdJustify = 3
$wdTextureSolid = -4; $wdTextureNone = 0
$wdLineStyleSingle = 1; $wdLineStyleNone = 0
$wdBorderLeft = -2; $wdBorderTop = -1; $wdBorderBottom = -3
$wdPageBreak  = 7
$wdColorAuto  = -16777216

# ─── Launch Word ────────────────────────────────────────────────────
Write-Host "Iniciando Word..."
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$sel = $word.Selection

# Page setup A4
$ps = $doc.Sections(1).PageSetup
$ps.PageWidth    = $word.CentimetersToPoints(21)
$ps.PageHeight   = $word.CentimetersToPoints(29.7)
$ps.TopMargin    = $word.CentimetersToPoints(1.8)
$ps.BottomMargin = $word.CentimetersToPoints(1.8)
$ps.LeftMargin   = $word.CentimetersToPoints(2.2)
$ps.RightMargin  = $word.CentimetersToPoints(2.2)

# ─── Helper: type formatted paragraph ───────────────────────────────
function TF {
    param(
        [string]$T        = "",
        [double]$Sz       = 11,
        [int]   $Clr      = -1,     # -1 = use current / auto
        [bool]  $Bld      = $false,
        [bool]  $Ita      = $false,
        [int]   $Al       = 0,
        [double]$SA       = 6,
        [double]$SB       = 0,
        [int]   $Bg       = -2,     # -2 = no change, -1 = none, >=0 = color
        [string]$Fn       = "Calibri",
        [bool]  $LBorder  = $false,
        [int]   $LBClr    = 5023945, # GOLD default
        [int]   $LBW      = 36,      # 4.5pt
        [double]$LInd     = -1,      # left indent cm (-1 = no change)
        [bool]  $NoPara   = $false   # don't add paragraph break
    )

    $s = $global:sel

    # Font
    $s.Font.Name      = $Fn
    $s.Font.Size      = $Sz
    if ($Clr -ge 0)   { $s.Font.Color = $Clr } else { $s.Font.Color = $global:TEXT_DARK }
    $s.Font.Bold      = $Bld
    $s.Font.Italic    = $Ita
    $s.Font.Underline = 0

    # Paragraph format
    $s.ParagraphFormat.Alignment   = $Al
    $s.ParagraphFormat.SpaceAfter  = $SA
    $s.ParagraphFormat.SpaceBefore = $SB
    if ($LInd -ge 0) {
        $s.ParagraphFormat.LeftIndent = $global:word.CentimetersToPoints($LInd)
    } else {
        $s.ParagraphFormat.LeftIndent = 0
    }
    $s.ParagraphFormat.RightIndent = 0

    # Background shading
    if ($Bg -ge 0) {
        $s.Shading.BackgroundPatternColor = $Bg
        $s.Shading.ForegroundPatternColor = $Bg
        $s.Shading.Texture = $global:wdTextureSolid
    } elseif ($Bg -eq -1) {
        $s.Shading.Texture = $global:wdTextureNone
        $s.Shading.BackgroundPatternColor = $global:wdColorAuto
    }

    # Left border
    if ($LBorder) {
        $s.ParagraphFormat.Borders($global:wdBorderLeft).LineStyle = $global:wdLineStyleSingle
        $s.ParagraphFormat.Borders($global:wdBorderLeft).Color     = $LBClr
        $s.ParagraphFormat.Borders($global:wdBorderLeft).LineWidth = $LBW
        if ($LInd -lt 0) { $s.ParagraphFormat.LeftIndent = $global:word.CentimetersToPoints(0.5) }
    } else {
        $s.ParagraphFormat.Borders($global:wdBorderLeft).LineStyle = $global:wdLineStyleNone
    }

    # Other borders off
    $s.ParagraphFormat.Borders($global:wdBorderTop).LineStyle    = $global:wdLineStyleNone
    $s.ParagraphFormat.Borders($global:wdBorderBottom).LineStyle = $global:wdLineStyleNone

    # Type
    if ($T.Length -gt 0) { $s.TypeText($T) }
    if (-not $NoPara)    { $s.TypeParagraph() }
}

function Spacer([double]$Sz=8,[int]$Bg=-1,[int]$Clr=-1) {
    TF -T "" -Sz $Sz -Bg $Bg -Clr $Clr -SA 0 -SB 0 -Al $wdLeft
}

function SectionHeader([string]$T) {
    TF -T $T -Sz 13 -Clr $GOLD -Bld $true -Al $wdLeft -SA 8 -SB 20 -Bg -1 -LBorder $true -LBClr $GOLD -LBW 48
}

function BodyText([string]$T,[double]$SA=8,[bool]$Just=$true) {
    $al = if($Just){$wdJustify}else{$wdLeft}
    TF -T $T -Sz 11 -Clr $TEXT_DARK -Al $al -SA $SA -Bg -1
}

function Bullet([string]$T) {
    $s = $global:sel
    $s.Font.Name    = "Calibri"
    $s.Font.Size    = 11
    $s.Font.Color   = $global:TEXT_DARK
    $s.Font.Bold    = $false
    $s.Font.Italic  = $false
    $s.ParagraphFormat.Alignment   = $global:wdLeft
    $s.ParagraphFormat.SpaceAfter  = 3
    $s.ParagraphFormat.SpaceBefore = 0
    $s.ParagraphFormat.LeftIndent  = $global:word.CentimetersToPoints(0.6)
    $s.ParagraphFormat.Borders($global:wdBorderLeft).LineStyle = $global:wdLineStyleNone
    $s.Shading.Texture = $global:wdTextureNone
    $s.Shading.BackgroundPatternColor = $global:wdColorAuto
    $s.TypeText("  •  $T")
    $s.TypeParagraph()
}

function HighlightBox([string]$T) {
    TF -T $T -Sz 11 -Clr $GOLD_DARK -Bld $true -Al $wdLeft -SA 10 -SB 10 -Bg $GOLD_BG -LBorder $true -LBClr $GOLD -LBW 48 -LInd 0.5
}

function MetricLine([string]$Num,[string]$Desc) {
    $s = $global:sel
    $s.Font.Name   = "Calibri"
    $s.Font.Size   = 13
    $s.Font.Bold   = $true
    $s.Font.Color  = $GOLD
    $s.Font.Italic = $false
    $s.ParagraphFormat.Alignment   = $global:wdLeft
    $s.ParagraphFormat.SpaceAfter  = 2
    $s.ParagraphFormat.SpaceBefore = 0
    $s.ParagraphFormat.LeftIndent  = $global:word.CentimetersToPoints(0.6)
    $s.ParagraphFormat.Borders($global:wdBorderLeft).LineStyle = $global:wdLineStyleNone
    $s.Shading.Texture = $global:wdTextureSolid
    $s.Shading.BackgroundPatternColor = $GOLD_BG
    $s.Shading.ForegroundPatternColor = $GOLD_BG
    $s.TypeText("  $Num  ")
    $s.Font.Size  = 11
    $s.Font.Bold  = $false
    $s.Font.Color = $TEXT_DARK
    $s.TypeText($Desc)
    $s.TypeParagraph()
}

function Testimonial([string]$Quote,[string]$Author) {
    TF -T "`"$Quote`"" -Sz 11 -Clr $TEXT_DARK -Ita $true -Al $wdJustify -SA 4 -SB 10 -Bg $GOLD_BG -LBorder $true -LBClr $GOLD -LBW 36 -LInd 0.5
    TF -T "— $Author"   -Sz 10 -Clr $GOLD_DARK -Bld $true -Al $wdLeft  -SA 14 -SB 0  -Bg $GOLD_BG -LInd 0.5
}

# ════════════════════════════════════════════════════════════════════
# CAPA
# ════════════════════════════════════════════════════════════════════
Write-Host "Criando capa..."

# Painel escuro superior (simulado via sombreamento de parágrafo)
Spacer 28 $DARK $OFF_WHITE
Spacer 28 $DARK $OFF_WHITE
Spacer 20 $DARK $OFF_WHITE

# Label acima do título
TF -T "PLATAFORMA DE APRENDIZADO E INTELIGÊNCIA" -Sz 8.5 -Clr $GOLD -Bld $true -Al $wdCenter -SA 0 -SB 0 -Bg $DARK -Fn "Calibri"

Spacer 6 $DARK

# Título ZHUB
TF -T "ZHUB" -Sz 80 -Clr $GOLD -Bld $true -Al $wdCenter -SA 0 -SB 0 -Bg $DARK -Fn "Calibri"

# Linha dourada fina
TF -T "" -Sz 2 -Al $wdCenter -SA 0 -SB 0 -Bg $GOLD

# Espaço após linha
Spacer 12 $DARK

# Subtítulo
TF -T "especializada no ecossistema SAP" -Sz 15 -Clr $OFF_WHITE -Al $wdCenter -SA 0 -SB 0 -Bg $DARK

Spacer 28 $DARK
Spacer 28 $DARK
Spacer 28 $DARK
Spacer 28 $DARK
Spacer 20 $DARK

# Faixa dourada com métricas
TF -T "" -Sz 2 -Al $wdLeft -SA 0 -SB 0 -Bg $GOLD
TF -T "+920 profissionais formados   |   +18.000 na comunidade   |   +500h de conteúdo   |   +12.000 no YouTube" `
   -Sz 9 -Clr $TEXT_DARK -Al $wdCenter -SA 0 -SB 6 -Bg $GOLD_LIGHT -Bld $true
TF -T "" -Sz 2 -Al $wdLeft -SA 0 -SB 0 -Bg $GOLD

# Branding rodapé capa
Spacer 14 $DARK
TF -T "Lab2learn  |  lab2learn.com.br  |  @lab2learn.com.br" `
   -Sz 10 -Clr $GOLD_LIGHT -Al $wdCenter -SA 0 -SB 0 -Bg $DARK
Spacer 14 $DARK

# ─── Quebra de página ───────────────────────────────────────────────
$sel.Shading.Texture = $wdTextureNone
$sel.Shading.BackgroundPatternColor = $wdColorAuto
$sel.ParagraphFormat.Borders($wdBorderLeft).LineStyle = $wdLineStyleNone
$sel.Font.Color = $TEXT_DARK
$sel.InsertBreak($wdPageBreak)

# ════════════════════════════════════════════════════════════════════
# PÁGINA 2 — POR QUE O ZHUB EXISTE? / O QUE É O ZHUB?
# ════════════════════════════════════════════════════════════════════
Write-Host "Pagina 2..."

SectionHeader "POR QUE O ZHUB EXISTE?"

BodyText "O ecossistema SAP muda em ritmo acelerado. S/4HANA, Clean Core, SAP BTP, integrações em nuvem e inteligência artificial — o profissional que não acompanha esse ritmo perde espaço no mercado."
BodyText "Acompanhar tudo isso sozinho, no meio de um projeto real, é praticamente impossível. O Zhub foi criado para resolver exatamente isso: reunir aprendizado estruturado, conteúdo técnico atualizado e agentes de IA em um só lugar — acessível quando o profissional mais precisa." 16

SectionHeader "O QUE É O ZHUB?"

BodyText "O Zhub é uma plataforma de aprendizado e inteligência especializada no ecossistema SAP. É onde o profissional SAP estuda, se atualiza e conta com suporte de IA para o dia a dia dos projetos."
BodyText "Desenvolvida pela Lab2learn — braço educacional da Lab2dev, empresa pioneira no ecossistema SAP no Brasil desde 2018, com sede em Osasco, SP." 16

SectionHeader "PARA QUEM É O ZHUB?"

BodyText "O Zhub foi construído para profissionais que atuam ou desejam atuar em projetos SAP modernos:" 8

foreach ($b in @(
    "Consultores funcionais SAP",
    "Desenvolvedores e arquitetos SAP",
    "Analistas de negócio e especialistas em integração",
    "Líderes técnicos e gerentes de projeto SAP",
    "Profissionais em transição para S/4HANA e SAP BTP"
)) { Bullet $b }

Spacer 14 -1

# ─── Quebra de página ───────────────────────────────────────────────
$sel.Shading.Texture = $wdTextureNone
$sel.Shading.BackgroundPatternColor = $wdColorAuto
$sel.ParagraphFormat.Borders($wdBorderLeft).LineStyle = $wdLineStyleNone
$sel.Font.Color = $TEXT_DARK
$sel.InsertBreak($wdPageBreak)

# ════════════════════════════════════════════════════════════════════
# PÁGINA 3 — O QUE VOCÊ ACESSA DENTRO DO ZHUB
# ════════════════════════════════════════════════════════════════════
Write-Host "Pagina 3..."

SectionHeader "O QUE VOCÊ ACESSA DENTRO DO ZHUB"

# Sub 1
TF -T "1. Jornadas de Aprendizado" -Sz 12 -Clr $GOLD -Bld $true -Al $wdLeft -SA 6 -SB 12 -Bg -1
BodyText "Caminhos progressivos e estruturados dentro dos temas centrais do ecossistema SAP. Cada Jornada guia o profissional com didática clara e foco em aplicação real:" 6

foreach ($b in @(
    "Jornada Clean Core — entenda e aplique o modelo de extensibilidade do SAP S/4HANA",
    "Jornada SAP BTP — domine a plataforma de tecnologia da SAP para integrações e cloud",
    "Novas jornadas em desenvolvimento contínuo"
)) { Bullet $b }

Spacer 10 -1

# Sub 2
TF -T "2. Conteúdo Técnico de Mercado" -Sz 12 -Clr $GOLD -Bld $true -Al $wdLeft -SA 6 -SB 8 -Bg -1
BodyText "Mais de 500 horas de conteúdo cobrindo os principais tópicos do ecossistema SAP:" 6

foreach ($b in @(
    "SAP S/4HANA e estratégias de migração",
    "SAP BTP — Business Technology Platform",
    "Clean Core e extensibilidade sem customização de código",
    "Integrações e APIs SAP",
    "Nuvem e Inteligência Artificial aplicadas ao SAP"
)) { Bullet $b }

Spacer 10 -1

# Sub 3
TF -T "3. Agentes de IA Treinados com Experiência Real" -Sz 12 -Clr $GOLD -Bld $true -Al $wdLeft -SA 6 -SB 8 -Bg -1
BodyText "Os agentes de IA do Zhub foram treinados com base na experiência real de projetos SAP da Lab2dev. O profissional pode usar os agentes para:" 6

foreach ($b in @(
    "Apoio na criação de especificações técnicas",
    "Validação de decisões de arquitetura SAP",
    "Consulta a boas práticas de projetos reais",
    "Suporte para tomada de decisão técnica no projeto",
    "Aceleração de estudos e revisão de conceitos"
)) { Bullet $b }

Spacer 14 -1

# ─── Quebra de página ───────────────────────────────────────────────
$sel.Shading.Texture = $wdTextureNone
$sel.Shading.BackgroundPatternColor = $wdColorAuto
$sel.ParagraphFormat.Borders($wdBorderLeft).LineStyle = $wdLineStyleNone
$sel.Font.Color = $TEXT_DARK
$sel.InsertBreak($wdPageBreak)

# ════════════════════════════════════════════════════════════════════
# PÁGINA 4 — DIFERENCIAL + NÚMEROS + DEPOIMENTOS
# ════════════════════════════════════════════════════════════════════
Write-Host "Pagina 4..."

SectionHeader "NOSSO DIFERENCIAL"

HighlightBox "Somos a única plataforma com agentes de IA treinados com experiência real de projetos SAP."

BodyText "O Zhub não é apenas uma biblioteca de vídeos. É uma ferramenta ativa que o profissional usa dentro dos projetos — para aprender, validar decisões, consultar boas práticas e acelerar entregas no ecossistema SAP." 16

SectionHeader "NÚMEROS QUE FALAM POR SI"

Spacer 6 $GOLD_BG

MetricLine "+920"    "profissionais já formados pela Lab2learn"
MetricLine "+18.000" "consultores SAP na comunidade Lab2learn"
MetricLine "+500h"   "de conteúdo técnico SAP disponível na plataforma"
MetricLine "+12.000" "inscritos no canal do YouTube"

Spacer 6 $GOLD_BG
Spacer 10 -1

SectionHeader "O QUE DIZEM NOSSOS ALUNOS"

Testimonial `
    "Bom dia Senhores, passando para agradecer a vocês que após fazer o curso de CPI consegui minha primeira vaga. Devo muito a vocês. Ansioso para o Evento da Lab2dev Summit 2025." `
    "Bruno Bonifácio — Consultor SAP CI/CPI"

Testimonial `
    "Eu finalizei em 100% o curso RAP disponibilizado pela Lab2Learn... Aproveito também para parabenizar o Vitor Ueda pela excelência e didática ao longo do curso — foi extremamente produtivo e agregador, realmente vale ouro!" `
    "Aluno Lab2learn — Curso SAP RAP"

Spacer 10 -1

# ─── Quebra de página ───────────────────────────────────────────────
$sel.Shading.Texture = $wdTextureNone
$sel.Shading.BackgroundPatternColor = $wdColorAuto
$sel.ParagraphFormat.Borders($wdBorderLeft).LineStyle = $wdLineStyleNone
$sel.Font.Color = $TEXT_DARK
$sel.InsertBreak($wdPageBreak)

# ════════════════════════════════════════════════════════════════════
# PÁGINA 5 — INVESTIMENTO + CONTATO
# ════════════════════════════════════════════════════════════════════
Write-Host "Pagina 5..."

SectionHeader "INVESTIMENTO"

BodyText "Acesso anual completo à plataforma Zhub, com todas as Jornadas de aprendizado, conteúdo técnico e agentes de IA:" 12

# Tabela de preços
$range = $sel.Range
$range.Collapse(0)  # wdCollapseEnd

$tbl = $doc.Tables.Add($range, 5, 2)
$tbl.Borders.Enable = $true

# Cabeçalho
$tbl.Cell(1,1).Range.Text = "Modalidade"
$tbl.Cell(1,2).Range.Text = "Valor"
$tbl.Cell(1,1).Range.Font.Bold  = $true
$tbl.Cell(1,2).Range.Font.Bold  = $true
$tbl.Cell(1,1).Range.Font.Color = $WHITE
$tbl.Cell(1,2).Range.Font.Color = $WHITE
$tbl.Cell(1,1).Range.Font.Size  = 11
$tbl.Cell(1,2).Range.Font.Size  = 11
$tbl.Cell(1,1).Shading.BackgroundPatternColor = $DARK
$tbl.Cell(1,1).Shading.ForegroundPatternColor = $DARK
$tbl.Cell(1,1).Shading.Texture  = $wdTextureSolid
$tbl.Cell(1,2).Shading.BackgroundPatternColor = $DARK
$tbl.Cell(1,2).Shading.ForegroundPatternColor = $DARK
$tbl.Cell(1,2).Shading.Texture  = $wdTextureSolid
$tbl.Cell(1,1).Range.ParagraphFormat.Alignment = $wdLeft
$tbl.Cell(1,2).Range.ParagraphFormat.Alignment = $wdLeft

# Dados
$rows = @(
    @("Acesso anual — oferta de lançamento", "R$ 2.997,00/ano"),
    @("Acesso anual — preço integral",        "R$ 3.497,00/ano"),
    @("Alunos Lab2learn (cupom exclusivo)",    "20% de desconto"),
    @("Funcionários e membros do conselho",    "90% de desconto")
)

for ($i=0; $i -lt $rows.Count; $i++) {
    $row = $i + 2
    $tbl.Cell($row,1).Range.Text = $rows[$i][0]
    $tbl.Cell($row,2).Range.Text = $rows[$i][1]
    $tbl.Cell($row,1).Range.Font.Size  = 11
    $tbl.Cell($row,2).Range.Font.Size  = 11
    $tbl.Cell($row,1).Range.Font.Color = $TEXT_DARK
    $tbl.Cell($row,2).Range.Font.Color = $TEXT_DARK
    $tbl.Cell($row,2).Range.Font.Bold  = $true
    $tbl.Cell($row,1).Range.ParagraphFormat.Alignment = $wdLeft
    $tbl.Cell($row,2).Range.ParagraphFormat.Alignment = $wdLeft
    if ($i % 2 -eq 0) {
        $tbl.Cell($row,1).Shading.BackgroundPatternColor = $GOLD_BG
        $tbl.Cell($row,1).Shading.ForegroundPatternColor = $GOLD_BG
        $tbl.Cell($row,1).Shading.Texture = $wdTextureSolid
        $tbl.Cell($row,2).Shading.BackgroundPatternColor = $GOLD_BG
        $tbl.Cell($row,2).Shading.ForegroundPatternColor = $GOLD_BG
        $tbl.Cell($row,2).Shading.Texture = $wdTextureSolid
    }
}

# Largura das colunas
$tbl.Columns(1).Width = $word.CentimetersToPoints(10.5)
$tbl.Columns(2).Width = $word.CentimetersToPoints(5.5)

# Voltar ao fluxo do documento após a tabela
$endRange = $tbl.Range
$endRange.Collapse(0)
$endRange.InsertParagraphAfter()
$sel.SetRange($endRange.End, $endRange.End)

Spacer 10 -1

# Nota sobre cupons
TF -T "* Os cupons de desconto são ativados 7 dias após a compra." `
   -Sz 9.5 -Clr $TEXT_MID -Ita $true -Al $wdLeft -SA 20 -Bg -1

# ── CTA / Contato ──
SectionHeader "PRONTO PARA COMEÇAR?"

HighlightBox "Acesse agora: lab2learn.com.br  |  WhatsApp: +55 11 97816-2868  |  @lab2learn.com.br"

BodyText "Entre em contato com nossa equipe para tirar dúvidas, solicitar condições especiais para empresas ou obter mais informações sobre o Zhub." 14

# Rodapé estilizado
Spacer 20 -1
TF -T "" -Sz 2 -Al $wdLeft -SA 0 -SB 0 -Bg $GOLD
TF -T "Lab2learn  |  lab2learn.com.br  |  @lab2learn.com.br  |  +55 11 97816-2868  |  Osasco, SP" `
   -Sz 9 -Clr $WHITE -Al $wdCenter -SA 0 -SB 6 -Bg $DARK
TF -T "" -Sz 2 -Al $wdLeft -SA 0 -SB 0 -Bg $GOLD

# ─── Salvar ─────────────────────────────────────────────────────────
Write-Host "Salvando documento..."
$savePath = "C:\Users\lab2d\OneDrive\Desktop\Zhub\Zhub_Apresentacao_Comercial.docx"
$doc.SaveAs2($savePath, 16)   # 16 = wdFormatXMLDocument (.docx)
$doc.Close($false)
$word.Quit()

Write-Host ""
Write-Host "Documento criado com sucesso:"
Write-Host $savePath
