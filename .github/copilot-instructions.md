# Instruções do projeto MecLoc

- Mantenha a implementação em Dart/Flutter e prefira soluções simples, adequadas a um projeto acadêmico.
- Deixe widgets e validação de formulário nas telas, chamadas HTTP em `lib/services`, estado compartilhado em `lib/providers` e parsing em `lib/models`.
- Preserve os estados de carregamento, erro e lista vazia na busca Places/Overpass, além da persistência dos favoritos com SharedPreferences.
- Nunca inclua chaves sensíveis no código ou em arquivos versionados.
- Centralize alterações de identidade visual em `lib/theme/app_theme.dart` e mantenha os diretórios de assets declarados no `pubspec.yaml`.
- Orçamentos são dados demonstrativos até existir um serviço/backend real.

## Conexão com o Obsidian (Memória das IAs)
- A base de conhecimento e registro do projeto fica em `C:\Users\mathe\Documents\Memoria-IA`.
- Ao documentar ou registrar sessões deste projeto no Obsidian:
  - Crie a nota de sessão em `03 Sessoes/` conectando-a explicitamente ao projeto: `Projeto: [[02 Projetos/Mecloc]]`.
  - Atualize a nota principal `02 Projetos/Mecloc.md` adicionando o link para a nova sessão no histórico: `- [[03 Sessoes/<NomeDaNota>|Descrição]]`.
  - Garanta que todos os links utilizem o padrão wikilink do Obsidian (`[[...]]`) para manter o grafo relacional conectado.
