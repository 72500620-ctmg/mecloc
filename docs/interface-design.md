# Interface MecLoc

## Direção

O mapa representa a busca real, e o painel representa a decisão: serviço, oficina, distância, endereço, orçamento. A linguagem visual usa o azul existente do MecLoc, grafite para o contexto do veículo e superfícies claras ou escuras de alto contraste. A inspiração de [navegação](https://21st.dev/community/components/s/navigation-menu), [cards](https://21st.dev/community/components/s/card) e [filtros](https://21st.dev/community/components/s/tabs) do 21st.dev foi traduzida para componentes nativos Flutter, mantendo as interações próprias de toque e teclado. A skill `design-taste-frontend` orientou hierarquia, conteúdo real, foco, movimento discreto e consistência. Suas receitas de HTML/CSS e o verificador de landing pages não medem corretamente a interface Flutter renderizada em canvas.

## Fluxo principal

- No celular, a busca fica diretamente sobre o mapa, sem cabeçalho. O painel abre em 55% da altura disponível, pode ser arrastado livremente e prioriza filtros e resultados; o atalho da garagem vem depois. O painel usa a superfície neutra do tema e se separa do mapa por borda e elevação. A navegação arredondada usa as cores do tema e ocupa espaço próprio no `Scaffold`, sem cobrir cards e formulários.
- No desktop, a navegação passa para uma rail e a lista ocupa a coluna esquerda. Mapa, busca e resultados ficam simultaneamente visíveis.
- Cada card usa dados existentes: nome, categoria, endereço, distância quando disponível, avaliação quando disponível e indicação de parceria. Salvar favorito, abrir detalhes e cotar possuem alvos independentes.
- Filtros de serviço seguem visíveis nos resultados; ordenação oferece proximidade, nome e compatibilidade quando há veículo ativo. Favoritos têm busca por nome, endereço ou categoria, ignorando acentos.
- Sem GPS, o mapa centraliza a primeira oficina com coordenadas já carregada; se não houver nenhuma, o estado vazio orienta a busca por cidade ou localização. Erros e carregamentos mostram o próximo passo disponível. Garagem e favoritos vazios conduzem a uma ação concreta.
- Perfil, garagem e orçamentos limitam a largura de leitura em janelas grandes. As telas seguem as cores e a tipografia do tema compartilhado.

## Verificação

Rodar `flutter analyze`, `flutter test` e `flutter build web`. Os testes de interface cobrem filtro tocável sem rolagem em 320×568, favoritos, independência das ações do card e layouts em 320, 390, 768, 1024 e 1440 px, inclusive tema escuro. Capturas manuais do build foram verificadas em 320×568 e 390×844, claro e escuro. Conferir também as capturas do build web em `diagnostics/taste/` (arquivos locais ignorados pelo Git).

## Revisão de superfícies e hierarquia

- O tema define os papéis de superfície para páginas, painel, cards e navegação. A barra inferior consulta `NavigationBarThemeData` em vez de escolher cores próprias. Seleção, ícones e texto usam os pares do `ColorScheme`.
- O painel sobre o mapa usa `surface` e uma borda com sombra para separar camadas sem tornar o tema claro acinzentado. Cards usam `surfaceContainer`, que mantém contraste tonal no tema escuro.
- No celular, o painel apresenta filtros e oficinas antes do convite para a garagem. O gesto do painel não salta automaticamente para outra altura após um arrasto curto.
- Avisos sobre o mapa e ícones do Perfil usam cores do tema ativo. O azul de ação no escuro foi substituído pelo `primary` do esquema escuro para manter a leitura.
- A validação visual da tela inicial foi refeita em Chrome headless nos temas claro e escuro em 320×568 e 390×844. As outras telas foram verificadas por análise de código e testes de widget; a inspeção visual completa delas em dispositivo físico continua pendente.

## Próximas decisões de produto

A classificação de compatibilidade continua dependente dos dados de especialidade disponíveis para cada oficina. A busca ao vivo e o mapa dependem dos serviços OSM, geolocalização e chave de mapa configurada. Avaliações e preços só devem aparecer quando vêm de dados reais; não foram criados exemplos fictícios para preencher a tela.

O finish gate HTML da skill foi executado no build web e retornou `GATE: FAIL 11 (round 1 of 3)`. Seus achados exigem elementos HTML (`<main>`, `<h1>`, `.wrap`, botões DOM e uma seção de landing page); o Flutter entrega a aplicação em `<flutter-view>`, então esses critérios não correspondem às telas nativas. O relatório bruto fica em `diagnostics/taste/gate.log`. A validação de responsividade e interações foi feita pelos testes de widget e por capturas reais em Chrome headless.
