# MecLoc — Design System (One UI × Uber)

Nov 3, 2026 · @Hugo Lopes

## Visão geral

O MecLoc segue a estrutura do Uber (mapa como protagonista, um painel de busca, primário preto e branco) com o acabamento do One UI 9 (cantos grandes, títulos que encolhem ao rolar, preto puro no modo escuro). A mudança é só de estilo: `providers/`, `services/` e `models/` não são tocados.

**Princípios**

- **Mapa primeiro.** A busca fica num painel. O mapa ocupa o resto da tela.
- **Monocromático com um acento.** Preto ou branco para ações, verde-limão `#B5D93B` só para seleção e destaque.
- **Superfícies sólidas.** Vidro apenas em elementos que flutuam sobre o mapa ou sobre imagens.
- **Movimento curto.** Animações entre 200 e 500 ms, sem nada em loop fora do carregamento.

**Restrições técnicas**

| Item | Valor |
| --- | --- |
| Flutter | 3.27.1 |
| Dart | 3.6.0 |
| Alvo principal | Chrome no desktop (CanvasKit) |
| Pacotes novos | Nenhum (só o que já está no `pubspec.yaml`) |
| Material | Material 3 (`useMaterial3: true`) |

**Arquivos do sistema**

| Arquivo | Conteúdo |
| --- | --- |
| `lib/theme/app_theme.dart` | `AppColors`, `AppTokens`, `AppRadius`, `AppTheme.light` / `.dark` |
| `lib/theme/theme_controller.dart` | Modo claro/escuro salvo em `shared_preferences` |
| `lib/widgets/ui.dart` | Componentes reutilizáveis |

O `pubspec.lock` atual exige Flutter 3.44 ou superior. Antes de implementar, apague o lock e rode `flutter pub get` no 3.27.1.

## Cores

Toda cor de tela vem de `context.tokens` (um `ThemeExtension`), nunca de um hex escrito direto no widget. Assim, claro e escuro trocam juntos e a transição de tema anima sozinha (`lerp`).

**Tokens (`AppTokens`)**

| Token | Claro | Escuro | Uso |
| --- | --- | --- | --- |
| Fundo da tela (`scaffoldBackgroundColor`) | `#F3F3F5` | `#000000` | Fundo de todas as telas |
| `surface` | `#FFFFFF` | `#151517` | Cards, painel, sheet |
| `surfaceAlt` | `#EEEEF0` | `#232326` | Campos, chips, estados vazios, skeleton |
| `ink` | `#0B0B0C` | `#F5F5F7` | Texto principal e ícones |
| `muted` | `#6B6B70` | `#9A9AA0` | Texto secundário |
| `line` | `#E4E4E7` | `#2C2C30` | Divisores; borda dos cards no escuro |
| `glass` | `#FFFFFF` a 72% | `#1C1C1F` a 62% | Fundo do vidro |
| `glassBorder` | `#FFFFFF` a 20% | `#FFFFFF` a 12% | Borda do vidro |
| `accent` | `#B5D93B` | `#B5D93B` | Seleção, badge da oficina, ponto do mapa |
| `onAccent` | `#0B0B0C` | `#0B0B0C` | Texto e ícone sobre o acento |
| `accentText` | `#174D43` | `#B5D93B` | Preço e destaques em texto |
| `shadow` | `#000000` a 10% | `#000000` a 40% | Sombras |
| `mesh` (4 cores) | verdes claros | verdes escuros | Fundo `GradientMesh` |

**ColorScheme (Material 3)**

- `primary`: preto no claro, branco no escuro. É o botão principal, estilo Uber.
- `onPrimary`: o inverso de `primary`.
- `secondary`: `#B5D93B`.
- `error`: `#B33D36` no claro, `#FF6B61` no escuro.
- O restante sai de `ColorScheme.fromSeed(seedColor: #174D43)`.

**Regras de uso**

- Um único elemento em acento por área. Se tudo é verde, nada se destaca.
- Favorito ativo usa `#FF4D5E` (vermelho). Estrela de avaliação usa `#FFB300`.
- No escuro, cards levam borda `line` em vez de sombra, porque sombra some no preto.
- Os tiles do mapa no escuro usam `darkModeTileBuilder` do `flutter_map`.

## Tipografia

A fonte é a padrão do Flutter (Roboto no web). A cara de Uber vem do peso alto e do espaçamento negativo nos títulos. A base é `Typography.material2021()`, com estes ajustes:

| Estilo | Peso | Letter spacing | Onde aparece |
| --- | --- | --- | --- |
| `displaySmall` | 900 | -1.6 | Frase de destaque no desktop |
| `headlineMedium` | 800 | -0.9 | Nome da oficina no detalhe |
| `headlineSmall` | 800 | -0.6 | Título da Home, preço do orçamento |
| `titleLarge` | 700 | -0.3 | Seções e título da AppBar |
| `titleMedium` | 700 | 0 | Nome em cards, contagem de resultados |
| `bodyMedium` | 400 | padrão | Texto corrido |
| `bodySmall` | 400 | padrão | Notas e endereço |
| `labelLarge` | 700 | 0.1 | Botões e chips |

- Texto secundário é sempre `bodyMedium` ou `bodySmall` com cor `muted`.
- O logo “MecLoc” usa 18 px, peso 900 e degradê de `ink` para `accentText` via `ShaderMask`.

## Forma, espaçamento e breakpoints

Cantos grandes são a marca do One UI. Os raios ficam em `AppRadius` e nenhum widget usa um número solto.

**Raios (`AppRadius`)**

| Token | Valor | Uso |
| --- | --- | --- |
| `sm` | 14 | Campos de texto, snackbar |
| `md` | 20 | Botões, tiles da lista, estados vazios |
| `lg` | 26 | Cards (`AppSurface` padrão) |
| `xl` | 32 | Painel do desktop, sheet, mapa do desktop |
| pílula | 100 | Vidro da barra superior, botões redondos, chips |

**Espaçamento**

- Grade de 4 px. Valores usados: 4, 8, 10, 12, 14, 16, 18, 20, 24.
- Margem lateral mínima de 16 px. No desktop, o conteúdo das telas internas é centralizado em 760 px (`contentPadding`).
- Padding interno de card: 18 px. Tiles da lista: 14 px.
- Botões e campos: altura mínima de 54 px.

**Sombra**

| Elemento | Blur | Deslocamento Y | Cor |
| --- | --- | --- | --- |
| Card (só no claro) | 18 | 6 | `shadow` a 6% |
| Vidro | 24 | 8 | `shadow` |
| Sheet | 30 | -6 | `shadow` |
| Painel do desktop | 40 | 16 | `shadow` |

**Breakpoints**

| Largura | Home | Telas internas |
| --- | --- | --- |
| Menos de 720 px | Mapa em tela cheia + bottom sheet | Coluna única, botões empilhados |
| 720 a 899 px | Mapa em tela cheia + bottom sheet | Conteúdo centralizado, botões lado a lado |
| 900 px ou mais | Painel de 430 px à esquerda + mapa à direita | Conteúdo centralizado em 760 px |

## Componentes

Todos ficam em `lib/widgets/ui.dart`. Antes de criar um widget novo, veja se algum destes já resolve.

| Componente | O que faz | Técnica | Quando usar |
| --- | --- | --- | --- |
| `Glass` | Vidro fosco com borda e sombra | `BackdropFilter` + `ImageFilter.blur` (sigma 18) | Só sobre mapa ou imagem. No máximo 3 por tela |
| `GlassIconButton` | Botão redondo de vidro | `Glass` + `IconButton` | Voltar e favoritar sobre o cabeçalho |
| `AppSurface` | Card sólido com raio `lg` | `Material` + `InkWell` | Todo agrupamento de conteúdo |
| `PressableScale` | Encolhe ao pressionar e volta com mola | `AnimationController.unbounded` + `SpringSimulation` (massa 1, rigidez 520, amortecimento 24) | Botões principais, cards clicáveis, pins |
| `IconBadge` | Quadrado arredondado com ícone | Raio = 32% do tamanho | Avatar da oficina e do veículo |
| `FadeSlideIn` | Entrada com fade e subida de 18 px | `TweenAnimationBuilder` | Itens de lista; atraso de 45 ms por item, até 8 |
| `Shimmer` | Brilho correndo sobre o conteúdo | `ShaderMask` + `GradientTransform` + `AnimationController` (1,4 s, em loop) | Só durante o carregamento |
| `SkeletonBox` / `WorkshopSkeletonList` | Blocos fantasmas da lista | `Container` em `surfaceAlt` | No lugar do spinner |
| `GradientMesh` | Fundo com manchas de cor e grade de pontos | `CustomPainter` + `RadialGradient`, anima uma vez (1,6 s) | Fundo da Home e cabeçalho sem coordenadas |
| `BrandWordmark` | Logo “MecLoc” | `ShaderMask` | Barra superior |
| `ThemeToggleButton` | Troca claro/escuro | `AnimatedSwitcher` com rotação | Barra superior |
| `FavoriteIcon` | Coração que pula ao trocar | `AnimatedSwitcher` + `ScaleTransition` (`easeOutBack`) | Lista e detalhe |
| `SheetHandle` | Puxador do sheet | 40 × 5 px em `line` | Topo do `DraggableScrollableSheet` |

**Regras**

- `PressableScale` usa `Listener`, não `GestureDetector`, para não roubar o toque do `InkWell` filho.
- O `Shimmer` envolve só os blocos do skeleton. Se envolver o card inteiro, o card também fica cinza.
- Nada pode ficar animando em loop quando a tela está parada. Isso trava o `pumpAndSettle` dos testes.

## Movimento

O padrão é `Curves.easeOutCubic`: começa rápido e assenta devagar. A mola fica só para o que o dedo ou o mouse aperta.

| Ação | Duração | Curva / física | Widget |
| --- | --- | --- | --- |
| Trocar texto de botão ou status | 200 a 250 ms | padrão | `AnimatedSwitcher` |
| Trocar estado da lista (vazio, erro, carregando) | 300 ms | `easeOutCubic` | `AnimatedSwitcher` |
| Mostrar os controles Mapa/Lista | 280 ms | `easeOutCubic` | `AnimatedSize` |
| Mapa aparecer ou sumir | 500 ms | padrão (fade) | `AnimatedSwitcher` |
| Item de lista entrar | 360 ms + 45 ms por item | `easeOutCubic` | `FadeSlideIn` |
| Troca de tema | 350 ms | `easeOutCubic` | `MaterialApp.themeAnimationDuration` |
| Ícone do tema | 350 ms | rotação + fade | `AnimatedSwitcher` |
| Favoritar | 260 ms | `easeOutBack` | `FavoriteIcon` |
| Proposta confirmada | 350 ms | `easeOutCubic` | `AnimatedContainer` (borda em acento) |
| Pressionar | até assentar | mola: massa 1, rigidez 520, amortecimento 24 | `PressableScale` (0,96; pins 0,85) |
| Navegar entre telas | padrão | `ZoomPageTransitionsBuilder` | `pageTransitionsTheme` |
| Ícone da oficina lista → detalhe | padrão | voo | `Hero` com tag `workshop-badge-<id>` |

**Retorno tátil**

- `HapticFeedback.selectionClick` nos toggles, `lightImpact` ao favoritar, `mediumImpact` ao escolher proposta.
- No Chrome do desktop não vibra nada. As chamadas ficam para quando o app rodar no Android.

## Layout por tela

A Home é a única tela que muda de estrutura conforme a largura. As outras só centralizam o conteúdo.

&#91;embedded content: Home · desktop e mobile\]

O painel do desktop e o sheet do mobile mostram exatamente o mesmo conteúdo, montado por uma única função (`_panelSlivers`).

| Tela | Estrutura | Destaques |
| --- | --- | --- |
| Home | `Stack`: `GradientMesh` de fundo, mapa, painel ou `DraggableScrollableSheet`, barra de vidro no topo | Pins pretos com borda branca; ponto verde no centro da busca; skeleton no carregamento |
| Detalhe da oficina | `CustomScrollView` + `SliverAppBar` de 260 px (320 px no desktop), fixa ao rolar | Mini-mapa sem interação em parallax; base curva com `CustomClipper`; `Hero` no ícone; informações agrupadas num card |
| Orçamentos | `SliverAppBar.large`, título encolhe ao rolar | Cards de proposta; preço em `headlineSmall` com `accentText`; borda em acento quando confirmada |
| Meu veículo | `SliverAppBar.large` | Formulário dentro de um card; veículos em lista agrupada com divisores (estilo Configurações do One UI) |

Todo texto, rótulo e tooltip das telas fica igual ao original. O teste de widget procura por esses textos.

## Fora do escopo e checklist

Cinco efeitos da lista original ficaram de fora e um entrou só em parte, porque pedem pacote novo ou não funcionam bem no Chrome. Os demais estão cobertos pelos componentes acima.

| Efeito | Status | Motivo |
| --- | --- | --- |
| Lottie | Fora | Exige o pacote `lottie` e arquivos de animação |
| Rive | Fora | Exige o pacote `rive`; repete o papel do Lottie |
| Neumorphism | Fora | Conflita com o visual plano do Uber e do One UI |
| Liquid Glass (shader) | Fora | `FragmentProgram` é instável no web nessa versão; o `Glass` com blur cobre o efeito |
| InteractiveViewer | Fora | O mapa já tem zoom e arrasto próprios |
| Dynamic Color | Parcial | Não existe cor de papel de parede no web; o tema usa `fromSeed` |

**Checklist para implementar**

- [ ] Apagar `pubspec.lock` e rodar `flutter pub get` no Flutter 3.27.1
- [ ] Se o `geolocator ^14` não resolver, baixar para `^13`
- [ ] Copiar `lib/theme/` e `lib/widgets/` da branch `ui/oneui-uber`
- [ ] Trocar o `MaterialApp` do `main.dart` para receber `theme`, `darkTheme` e `themeMode`
- [ ] Restilizar as telas uma por vez: Home, Detalhe, Orçamentos, Veículo
- [ ] Em `workshop_detail_screen.dart`, importar `latlong2` com `hide Path`
- [ ] Rodar `flutter analyze` sem erros
- [ ] Rodar `flutter test` e confirmar que o teste da Home passa
- [ ] Testar no Chrome em 1440 px e em 400 px de largura
- [ ] Testar os dois temas em cada tela
