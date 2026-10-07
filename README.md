# MecLoc

Aplicativo Flutter para localizar oficinas cadastradas no OpenStreetMap, exibi-las em um mapa, salvar favoritas e organizar veículos. As telas de orçamento usam propostas demonstrativas locais; elas não enviam pedidos reais às oficinas.

## Requisitos

- Flutter com Dart 3.6 ou superior.
- Flutter com suporte às plataformas desejadas (Android, iOS ou Web).
- Conexão com a internet para consultar o OpenStreetMap.

## Preparar e executar

Na raiz do projeto, baixe as dependências:

```powershell
flutter pub get
```

Este workspace contém o código Dart e a configuração de pacotes. Se o projeto ainda não tiver as pastas de plataforma do Flutter, gere-as uma vez:

```powershell
flutter create --platforms=android,ios,web .
```

Execute o aplicativo sem chave de API:

```powershell
flutter run
```

Para testar no Chrome:

```powershell
flutter run -d chrome
```

Para conferir o código e executar os testes:

```powershell
flutter analyze
flutter test
```

## OpenStreetMap

O app usa a localização do dispositivo (com permissão) ou geocodifica uma cidade informada pelo usuário com o Nominatim. Em seguida, consulta oficinas marcadas como `shop=car_repair` ou `craft=car_repair` no Overpass API e mostra os pontos sobre tiles do OpenStreetMap. Não é necessária chave do Google nem configuração de faturamento.

Os dados do OpenStreetMap são colaborativos e podem estar incompletos: oficinas sem as etiquetas esperadas não aparecerão, e avaliações, especialidades, preços e horários não são fornecidos. A busca cobre um raio limitado ao redor do ponto selecionado.

O uso dos serviços públicos está sujeito às políticas e limites de cada serviço. O Nominatim público deve ser usado com baixa frequência, identificação do aplicativo e respeito ao limite de solicitações; o app consulta apenas após ação explícita do usuário e mantém em memória as cidades já geocodificadas. Os servidores públicos do Overpass e de tiles não oferecem garantia de disponibilidade ou capacidade para uso comercial intenso. Para uma publicação com tráfego significativo, contrate ou hospede serviços próprios.

Mantenha a atribuição visível no mapa. Consulte as [políticas do Nominatim](https://operations.osmfoundation.org/policies/nominatim/), do [servidor de tiles do OpenStreetMap](https://operations.osmfoundation.org/policies/tiles/) e os [termos do Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API#Public_Overpass_API_instances).

## Estrutura

```text
lib/
  main.dart
  models/       # Modelo Workshop e leitura do JSON
  providers/    # Estado de busca e favoritos
  screens/      # Início, Oficina, Orçamentos e Meu veículo
  services/     # Localização, geocodificação e consulta ao Overpass
  theme/        # Identidade visual e tema
assets/
  branding/     # Marca e identidade visual
  icons/        # Ícones fornecidos pelo projeto
  images/       # Imagens do app
```

As cores principais ficam em `lib/theme/app_theme.dart`. Adicione imagens, ícones e materiais de marca nas pastas correspondentes de `assets/`; elas já estão declaradas no `pubspec.yaml`.

## O que é local/demonstrativo

- Favoritos de oficinas e veículos ficam no `SharedPreferences` do dispositivo.
- Orçamentos e confirmação de proposta são mockados em memória e reiniciam ao fechar a tela.
- Horários, preços e especialidades não são inventados: a tela de detalhe informa que devem ser confirmados diretamente com a oficina.
