# MecLoc

Aplicativo Flutter para localização de oficinas automotivas via OpenStreetMap, cálculo de compatibilidade por modelo de veículo, solicitação de orçamentos via WhatsApp e controle de revisões preventivas com persistência no Firebase.

---

## 1. Identificação
- **Aplicativo:** MecLoc
- **Squad:** Mobizados
- **Integrantes:**
  - [MATHEUS GARCIA CORGOSINHO] - Matrícula: [72500298] - Contato: [72500298@aluno.faculdadecotemig.br]
  - [LUIZ FELIPE LOURENCO SANTOS] - Matrícula: [72500620] - Contato: [72500620@aluno.faculdadecotemig.br]
  - [HUGO BAPTISTA DE OLIVEIRA LOPES] - Matrícula: [72500239] - Contato: [72500239@aluno.faculdadecotemig.br]
  - [PEDRO PAULO RODRIGUES VELOSO] - Matrícula: [72501111] - Contato: [72501111@aluno.faculdadecotemig.br]
  - [RAFAEL DE OLIVEIRA CARVALHO MILAGRE VIANA] - Matrícula: [72500654] - Contato: [72500654@aluno.faculdadecotemig.br]

---

## 2. Sobre o Projeto
O **MecLoc** é uma plataforma móvel e web desenvolvida em Flutter voltada a motoristas que buscam oficinas mecânicas de confiança e a proprietários de oficinas que desejam receber cotações qualificadas. O motorista pode buscar estabelecimentos próximos via GPS ou pesquisar por cidade, aplicar filtros por especialidade (mecânica, autoelétrica, pneus, funilaria) e calcular compatibilidade com seu veículo. O fluxo principal permite solicitar orçamentos padronizados diretamente no WhatsApp da oficina, registrar o resultado e gerenciar revisões preventivas por quilometragem em sua garagem digital. Para donos de oficinas, o app disponibiliza o cadastro de parceiros com persistência em nuvem.

---

## 3. Requisitos Atendidos

| # | Requisito Obrigatório | Onde está implementado no app |
|---|---|---|
| **1** | **Pelo menos 4 telas com `Navigator.push` e `pop`** | Implementado com fluxo completo de ida e volta em: <br>• [`WorkshopDetailScreen`](lib/screens/workshop_detail_screen.dart) (detalhes da oficina)<br>• [`WorkshopRegistrationScreen`](lib/screens/workshop_registration_screen.dart) (cadastro de oficina parceira)<br>• [`QuotesScreen`](lib/screens/quotes_screen.dart) (histórico de cotações)<br>• [`LoginScreen`](lib/screens/auth/login_screen.dart) (login)<br>• [`RegisterScreen`](lib/screens/auth/register_screen.dart) (cadastro de usuário)<br>• [`SettingsScreen`](lib/screens/settings_screen.dart) e [`VehicleScreen`](lib/screens/vehicle_screen.dart). |
| **2** | **API REST com `http` e `async/await`; dados dinâmicos** | Centralizado em [`lib/services/open_street_map_service.dart`](lib/services/open_street_map_service.dart) usando o pacote `http` (`Client.get` e `Client.post`) com `async/await` consultando as APIs públicas Nominatim, Photon e Overpass para geocodificação e busca em tempo real de estabelecimentos automotivos. |
| **3** | **Loading e erro visíveis na UI** | • **Loading:** Indicadores circulares (`CircularProgressIndicator`) na busca de oficinas ([`ExploreScreen`](lib/screens/explore_screen.dart)), nos botões de formulário e no carregamento da geolocalização.<br>• **Erro:** Componente dedicado [`AppNotice`](lib/widgets/app_notice.dart) com botão "Tentar novamente" em falhas de conexão/rede e `SnackBar` informativos com mensagens amigáveis em erros de autenticação e validação. |
| **4** | **Formulário com `Form` e `validator`** | • Cadastro de oficina parceira em [`WorkshopRegistrationScreen`](lib/screens/workshop_registration_screen.dart) utilizando `Form`, `GlobalKey<FormState>()`, e `TextFormField` com validadores de nome, telefone WhatsApp e endereço.<br>• Formulário de cadastro de veículos com validação de campos obrigatórios em [`VehicleScreen`](lib/screens/vehicle_screen.dart). |
| **5** | **Lista dinâmica com `ListView.builder`** | • Histórico dinâmico de cotações e status em [`QuotesScreen`](lib/screens/quotes_screen.dart) (`ListView.builder`).<br>• Linha do tempo de atividades e revisões em [`ActivityScreen`](lib/screens/activity_screen.dart) (`ListView.builder`).<br>• Lista de oficinas filtradas dentro do painel arrastável (`DraggableScrollableSheet`). |
| **6** | **`SharedPreferences` com persistência ao reiniciar** | Persistência local comprovada em 4 providers independentes:<br>• [`WorkshopProvider`](lib/providers/workshop_provider.dart): salva oficinas favoritas e histórico de termos pesquisados.<br>• [`VehicleProvider`](lib/providers/vehicle_provider.dart): salva os veículos da garagem, veículo ativo e odômetro/km.<br>• [`ThemeProvider`](lib/providers/theme_provider.dart): persiste a escolha de tema (Claro, Escuro ou Sistema).<br>• [`QuotesProvider`](lib/providers/quotes_provider.dart): armazena o histórico e status de cotações solicitadas. |
| **7** | **Provider: Telas, HTTP e Prefs separados** | Arquitetura desacoplada em 3 camadas limpas:<br>• **Apresentação:** `lib/screens/` e `lib/widgets/`<br>• **Gerenciamento de Estado:** `lib/providers/` (`WorkshopProvider`, `VehicleProvider`, `QuotesProvider`, `ThemeProvider`, `AuthProvider`)<br>• **Serviços & HTTP:** `lib/services/` (`OpenStreetMapService`, `LocationService`) |
| **8** | **App abre e percorre o fluxo sem crashar** | Suíte de testes com **24 testes automatizados aprovados** (`flutter test`), análise estática sem erros (`dart analyze`) e compilação de release web/mobile validada sem exceções de renderização. |

---

## 4. API e Dados Remotos
O aplicativo consome **APIs públicas REST** (sem necessidade de chave de API privada para a avaliação acadêmica) e sincronização na nuvem com **Firebase**:

1. **Nominatim API (OpenStreetMap):**
   - **URL Base:** `https://nominatim.openstreetmap.org/search`
   - **Método:** `GET`
   - **Função:** Geocodificação de cidades e bairros digitados pelo usuário.
2. **Photon Geocoder (Komoot):**
   - **URL Base:** `https://photon.komoot.io/api`
   - **Método:** `GET`
   - **Função:** Contingência rápida quando o Nominatim apresenta limitação de taxa.
3. **Overpass API:**
   - **URL Base:** `https://overpass-api.de/api/interpreter` (com fallbacks para `kumi.systems` e `openstreetmap.fr`)
   - **Método:** `POST`
   - **Função:** Consulta geoespacial (raio de 8 km) buscando tags automotivas (`shop=car_repair`, `amenity=car_wash`, etc.).
4. **Google Firebase (Cloud Firestore & Auth):**
   - **Auth:** E-mail/Senha e Google Sign-In.
   - **Firestore:** Coleções `workshops` (oficinas parceiras cadastradas) e `quotes` (cotações na nuvem).

---

## 5. Como Rodar o Projeto

### Pré-requisitos
- Flutter SDK (versão 3.6.0 ou superior)
- Dart SDK integrado
- Navegador Google Chrome (para Web) ou emulador Android / dispositivo físico conectado.

### Passos de execução
```bash
# 1. Clonar o repositório e entrar na pasta
git clone https://github.com/72500620-ctmg/mecloc.git
cd mecloc

# 2. Baixar as dependências do Flutter
flutter pub get

# 3. Executar a análise de código (0 erros)
flutter analyze

# 4. Rodar todos os testes automatizados
flutter test

# 5. Executar o aplicativo no navegador (ou emulador)
flutter run -d chrome
```

---

## 6. Backend Local
> **API Pública:** O aplicativo utiliza exclusivamente APIs públicas abertas (OpenStreetMap / Overpass / Nominatim) e Firebase Serverless (Firestore e Authentication). Portanto, **não é necessário subir nenhum servidor ou backend local** para executar e testar o fluxo de ponta a ponta.

---

## 7. Estrutura do Código
```text
lib/
├── firebase_options.dart         # Configuração multiplataforma do Firebase Core
├── main.dart                     # Ponto de entrada, inicialização e MultiProvider
├── models/                       # Modelos de dados imutáveis com serialização JSON
│   ├── maintenance_item.dart     # Itens de revisão preventiva e intervalos de km
│   ├── quote_request.dart        # Modelo de solicitação e status de cotação
│   ├── vehicle.dart              # Dados do veículo e motorização
│   └── workshop.dart             # Dados da oficina, geolocalização e cálculo de compatibilidade
├── providers/                    # Estado da aplicação (ChangeNotifier / Provider)
│   ├── auth_provider.dart        # Autenticação Firebase e perfil de usuário
│   ├── quotes_provider.dart      # Gestão de cotações e formatação WhatsApp
│   ├── theme_provider.dart       # Alternância e persistência de temas
│   ├── vehicle_provider.dart     # Gestão dos veículos da garagem
│   └── workshop_provider.dart    # Busca de oficinas, filtros e favoritos
├── screens/                      # Telas da aplicação
│   ├── auth/                     # Telas de Login e Cadastro
│   ├── explore_screen.dart       # Mapa interativo, busca e listagem
│   ├── favorites_screen.dart     # Lista de oficinas favoritas salvas
│   ├── main_shell.dart           # Barra de navegação inferior flutuante
│   ├── profile_screen.dart       # Gestão de conta, perfil e acessos
│   ├── quotes_screen.dart        # Histórico de cotações com filtros
│   ├── settings_screen.dart      # Configurações de tema e sistema
│   ├── vehicle_screen.dart       # Garagem inteligente e revisões preventivas
│   ├── workshop_detail_screen.dart # Detalhes da oficina e atalho de rotas
│   └── workshop_registration_screen.dart # Formulário com validação para oficinas
├── services/                     # Serviços de rede e sensores externos
│   ├── location_service.dart     # Serviço de captura de coordenadas GPS
│   └── open_street_map_service.dart # Cliente HTTP REST com Overpass e Nominatim
├── theme/                        # Design System e paleta de cores (MecLoc Theme)
└── widgets/                      # Componentes reutilizáveis (Liquid Glass, Modais SOS, etc.)
```

---

## 8. Observações, Bônus e Destaques
- **Autenticação Real (Bônus):** Suporte completo a login e cadastro via Firebase Authentication (E-mail/Senha e Google Sign-In) integrado ao perfil de motorista ou oficina parceira no Firestore.
- **GPS e Geolocalização (Bônus):** Integração com `geolocator` para centralizar a busca na posição exata do usuário.
- **Disparos WhatsApp com `url_launcher` (Bônus):** Geração automática de mensagens formais de cotação com dados do carro e do defeito para abertura direta no WhatsApp.
- **Botão de Emergência SOS 24h (Bônus):** Acesso rápido aos telefones de socorro público (SAMU 192, Bombeiros 193, Polícia 190, Rodoviária Federal 191).
- **Tema Claro / Escuro (Bônus):** Design responsivo com suporte a modo escuro, modo claro e sincronização automática com o sistema operacional.
- **Design Moderno:** Utilização de componentes com efeito Liquid Glass e navegação fluida em painel deslizante (`DraggableScrollableSheet`).
