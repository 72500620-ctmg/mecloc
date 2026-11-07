# MecLoc

Aplicativo Flutter para localizar estabelecimentos de serviços automotivos no OpenStreetMap, consultar informações disponíveis, salvar favoritos e organizar veículos. Orçamentos são simulações locais: nenhuma solicitação é enviada a oficinas.

## Tela inicial e busca

A tela inicial abre o mapa e solicita a localização do dispositivo. O campo flutuante pesquisa uma cidade ao tocar na lupa ou pressionar Enter; a busca funciona mesmo enquanto uma tentativa de GPS está pendente. Nominatim é o geocodificador principal, com Photon como contingência. “Minha localização” fica no painel inferior. Resultados e atalhos por tipo aparecem em um painel arrastável, com rolagem ao expandir. A barra inferior flutua sobre o painel e se oculta enquanto o teclado está aberto. Configurações (Automático, Claro e Escuro) fica na barra inferior; Orçamentos demonstrativos está disponível no painel da tela inicial.

## Navegação

- **Explorar:** buscar por cidade ou localização, filtrar os resultados e alternar entre lista e mapa. Selecione um resultado para ver endereço, telefone, horário informado e contato disponível.
- **Favoritos:** recupera dados básicos salvos no dispositivo, mesmo depois de outra busca. Dados antigos que continham apenas IDs não incluem informações suficientes para serem exibidos fora da busca original.
- **Veículos:** cadastro e seleção locais.
- **Orçamentos demonstrativos:** acessados pelo painel da tela inicial; criam e removem simulações locais sem enviar pedidos ou oferecer preços reais.

A busca usa Nominatim e Overpass, num raio de 8 km. Resposta vazia e falha são distintas. Os dados são colaborativos, podem estar incompletos ou desatualizados e devem ser confirmados com o estabelecimento. A atribuição do OpenStreetMap aparece no mapa.

## Executar e verificar

Requer Flutter com Dart 3.6 ou superior, dependências obtidas com `flutter pub get` e conexão com a internet para busca e mapa. Plataformas presentes no repositório: Android, iOS e Web.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Na revisão de 06/11/2026, `flutter analyze` passou e `flutter test --no-pub` passou com 18 testes, incluindo busca via lupa/teclado enquanto o GPS está pendente, fallback Overpass, notificações e troca de tema. Os widgets principais também foram verificados em viewports de 360×640 e 320×568. `flutter build web --release --no-pub` compilou. O teste Flutter no Chrome ficou sem saída e foi interrompido; a inspeção visual do navegador não foi concluída.

Teste de disponibilidade externa no mesmo dia: Nominatim encontrou Campinas e retornou coordenadas. A consulta de oficinas recebeu HTTP 502 do endpoint principal por capacidade; os outros endpoints públicos tentados expiraram sem resposta. A busca mantém o mapa na cidade e apresenta notificação de falha com opção de tentar novamente, mas resultados ao vivo dependem da disponibilidade desses serviços.

## Organização atual e próximos passos

`providers/` contém estado compartilhado e persistência local via SharedPreferences; `services/` reúne localização e acesso a fontes externas; `models/` descreve os dados; `screens/`, `widgets/` e `theme/` compõem a apresentação. Provider foi mantido. A separação em módulos por funcionalidade e repositórios explícitos ainda não foi concluída. Revisar também o fluxo de veículos, tratamento de erros de persistência, migração dos favoritos antigos e testes em telas pequenas, texto ampliado e plataformas reais.

As APIs públicas têm limites e políticas de uso. Antes de uma publicação, configure identificação e serviços adequados à escala e consulte as políticas do [Nominatim](https://operations.osmfoundation.org/policies/nominatim/) e dos [tiles do OpenStreetMap](https://operations.osmfoundation.org/policies/tiles/).

## Referências de design

- [Arquitetura Flutter](https://docs.flutter.dev/app-architecture/guide): separar apresentação, estado e fontes de dados; usar camadas adicionais quando houver responsabilidade concreta.
- [Acessibilidade Flutter](https://docs.flutter.dev/ui/accessibility): áreas de toque, contraste, rótulos e teste com ampliação de texto.
- [Layouts adaptáveis Flutter](https://docs.flutter.dev/ui/adaptive-responsive/best-practices): adaptar o espaço disponível e verificar a interface em diferentes tamanhos.
- [ThemeMode](https://api.flutter.dev/flutter/material/ThemeMode.html): `ThemeMode.system` acompanha a configuração de aparência do dispositivo.
