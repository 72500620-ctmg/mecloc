# Instruções do projeto MecLoc

- Mantenha a implementação em Dart/Flutter e prefira soluções simples, adequadas a um projeto acadêmico.
- Deixe widgets e validação de formulário nas telas, chamadas HTTP em `lib/services`, estado compartilhado em `lib/providers` e parsing em `lib/models`.
- Preserve os estados de carregamento, erro e lista vazia na busca Places, além da persistência dos favoritos com SharedPreferences.
- Nunca inclua chaves do Google no código ou em arquivos versionados. A chave local é recebida por `--dart-define=GOOGLE_PLACES_API_KEY=...`.
- Centralize alterações de identidade visual em `lib/theme/app_theme.dart` e mantenha os diretórios de assets declarados no `pubspec.yaml`.
- Orçamentos são dados demonstrativos até existir um serviço/backend real.
