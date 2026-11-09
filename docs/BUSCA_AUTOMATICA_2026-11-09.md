# Busca automática com cache e proteção de requisições

Data: 2026-11-09, America/Sao_Paulo. Origem: usuário autorizou a implementação da navegação automática, preservando simplicidade e ausência de infraestrutura paga adicional.

## Comportamento

- Após aproximadamente 1,1 segundo sem movimento, o mapa busca a última posição escolhida. Um novo movimento cancela o temporizador anterior.
- Pequenos deslocamentos não disparam uma busca: o limiar considera 25% da menor dimensão da área visível, limitado entre 200 e 1.800 metros. Alterações de zoom relevantes também são consideradas.
- Abaixo do zoom 12 não há consulta automática; a interface orienta aproximar o mapa e mantém os dados disponíveis.
- O botão “Buscar nesta área” permanece como opção. Resultados parciais não desativam mais a navegação automática.
- A câmera e o GPS conservam as correções anteriores. Respostas de buscas substituídas não assumem o controle da tela.

## Cache e atualização progressiva

- Cache local persistente em SharedPreferences, sem criar banco, API própria ou Cloud Functions.
- Respostas completas são reutilizadas por seis horas; parciais, por quinze minutos, mantendo sua identificação. Dados antigos podem ser reaproveitados por até sete dias quando uma atualização falha, com indicação de dados salvos.
- Áreas já consultadas são comparadas com a nova área visível. Se uma área salva contém a nova, os dados são recortados localmente sem nova chamada externa.
- Consultas de viewport incluem margem de 20% em cada direção para aproveitar pequenos deslocamentos; a exibição continua limitada à área solicitada. Mantido o limite de 80 km de diagonal para consultas muito amplas.
- Até doze áreas são mantidas; o cache reduz entradas antigas quando o conjunto ultrapassa 1.500 registros, preservando uma resposta individual sem truncá-la artificialmente.
- Resultados já visíveis permanecem durante a atualização. Cada lote válido da contingência pode atualizar mapa/lista antes de terminar a busca inteira, sem gerar chamadas adicionais para isso.
- O cache preserva categoria, serviços adicionais e cobertura. Restaurar oficinas OSM sem avaliações não inventa nota 5 ou quantidade de avaliações.

## Controle de tráfego

- Uma requisição HTTP de descoberta ativa por vez, com intervalo mínimo de um segundo entre inícios nesta instância do app.
- Novas consultas automáticas de área têm intervalo mínimo de oito segundos; leituras do cache não precisam esperar. Se o usuário navegar durante a espera, a última posição permanece pendente.
- Buscas iguais em andamento compartilham a mesma consulta. Pesquisas substituídas sinalizam cancelamento HTTP e não iniciam suas contingências restantes.
- Falhas aplicam espera crescente por servidor. `Retry-After` em segundos ou data HTTP é respeitado, inclusive em atualização explícita.
- Photon passou de sete termos paralelos para até três consultas sequenciais na descoberta por área. A navegação automática tenta no máximo dois Overpass e três Photon, frequentemente menos por cache ou espera de servidor.
- **A navegação automática não aciona Nominatim.** A contingência limitada desse serviço permanece nas buscas explícitas, respeitando a fila local, sem paginação ou varredura automática em grade.
- A fila e os limites são locais ao navegador/app. Não representam controle agregado entre todos os usuários. As políticas e a disponibilidade dos serviços públicos continuam sendo limitações reais.

## Interface

- “Buscando nesta região…” durante atualização; “Cobertura limitada” ou “Dados salvos” quando aplicável.
- Status compacto com informação acessível e ação “Atualizar”, substituindo o cartão grande de busca incompleta.
- Erros de atualização automática não bloqueiam a lista com um cartão grande. Falhas explícitas sem resultados disponíveis continuam recebendo uma mensagem de erro.

## Validação

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --reporter expanded`: **72 testes aprovados**, incluindo quinze novos casos nesta etapa.
- Casos novos verificam persistência de parciais, cobertura espacial, margem de consulta, ausência de Nominatim automático, limite de concorrência, cancelamento HTTP, resultados progressivos, intervalo automático, `Retry-After`, dados antigos e navegação rápida para a última posição.
- Os testes de interface detectaram e corrigiram uma combinação inválida de `shape` e `borderRadius` no botão “Buscar nesta área”.
- Nenhuma busca adicional foi enviada às APIs públicas de estabelecimentos durante essa validação; os testes usam respostas controladas. Disponibilidade externa não foi presumida a partir desses testes.
- Commits anteriores preservados. Cópia de segurança do estado inicial em `.dart_tool/before_automatic_search.zip`.

## Publicação

- Build web concluído; permanece o aviso não bloqueante de fonte Cupertino.
- Publicação somente Hosting em `https://mecloc.web.app`, aproximadamente às 16:12. Versão Firebase `799adfb9d208a502`.
- Arquivo remoto `main.dart.js` retornou HTTP 200 e SHA-256 igual ao build local: `7F10A43A239ACAD9BA4998805079701BAC8C88019745F3EED1A28DA5C35228C7`.
- Confirmação interativa no iPhone permanece pendente. A publicação e os testes não comprovam disponibilidade permanente das APIs externas.

## Infraestrutura e limites

A implementação permanece Flutter + Firebase existente, sem habilitar plano de faturamento, funções, servidores ou serviços pagos novos. Não garante cobertura completa ou ausência de bloqueios das fontes gratuitas; melhora a experiência e reduz chamadas dispensáveis.

Fontes: [política Nominatim](https://operations.osmfoundation.org/policies/nominatim/), [API Photon](https://github.com/komoot/photon/blob/master/docs/api-v1.md), [limites Overpass](https://dev.overpass-api.de/overpass-doc/en/preface/commons.html).

## Etapa posterior: estabilidade no zoom

O relato de estabelecimentos desaparecendo em níveis específicos levou à separação entre locais conhecidos e cobertura das áreas, com preservação dos dados em respostas parciais. Detalhes e validação posterior: [correção do zoom](CORRECAO_ZOOM_2026-11-09.md).
