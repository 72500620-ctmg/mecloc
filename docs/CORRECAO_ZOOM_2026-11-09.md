# Estabilidade dos estabelecimentos ao alterar o zoom

Data: 2026-11-09, America/Sao_Paulo. Origem: relato do usuário de locais que desapareciam em níveis específicos de zoom e reapareciam ao afastar o mapa.

## Causa encontrada no código

O cache escolhia uma única resposta por área. Uma resposta parcial mais recente de uma área pequena podia esconder locais presentes em outra área salva que também cobria o mapa. Além disso, o provider substituía a lista por cada atualização parcial. Isso permitia que um estabelecimento ainda dentro da área visível desaparecesse quando uma consulta retornava menos dados.

Não há uma regra intencional de esconder categorias de estabelecimentos por nível de zoom. O recorte geográfico normal e os filtros continuam aplicáveis.

## Correção

- Os estabelecimentos conhecidos são mantidos por ID, separadamente dos metadados de cobertura das consultas. Atualizações parciais acrescentam ou atualizam dados sem apagar ausências.
- A leitura do cache e os lotes progressivos combinam os locais conhecidos da área solicitada. Cobertura completa ainda válida tem preferência sobre uma parcial mais recente.
- O provider preserva os locais já recebidos dentro da área atual durante respostas parciais ou antigas. Uma resposta completa e atual pode substituir os dados da sua área.
- A migração do cache anterior é automática. O novo formato persiste os locais e sua última confirmação individual, evitando ressuscitar cadastros removidos por uma atualização completa.
- Dados não confirmados expiram em até sete dias; uma parcial que não inclua um local não renova sua validade. Mantidos os limites de áreas e registros históricos, preservando os registros das coberturas mantidas e uma resposta individual grande sem truncamento.
- Nenhuma nova consulta externa, temporizador ou serviço foi acrescentado. Debounce, intervalos, cancelamento, espera após falhas e restrições de Nominatim permanecem iguais.

## Verificação

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --reporter expanded`: **82 testes aprovados**, dez novos casos nesta etapa.

Testes controlados verificam alternância entre áreas e zooms 13, 14, 15 e 17, respostas parciais sucessivas, recorte geográfico, reutilização sem HTTP, migração e reabertura do cache, atualização completa, expiração individual e respostas acima de 1.500 registros. Não foram feitas consultas de diagnóstico às APIs públicas de estabelecimentos.

Os testes de interface não equivalem à validação interativa no iPhone. As fontes gratuitas ainda podem ter cobertura limitada; preservar dados conhecidos não torna uma resposta parcial completa.

## Publicação

- `flutter build web --no-pub`: concluído. Permanece o aviso não bloqueante de fonte Cupertino.
- Publicado somente Firebase Hosting em `https://mecloc.web.app` em 2026-11-09, aproximadamente às 16:47. Versão `42d113882a7ae7a3`.
- `main.dart.js` remoto: HTTP 200; SHA-256 igual ao build local, `C570645AFC10C0F9E5D2DA6C597E45200F398056610E9ED76C212C5EF7ACD8B8`.
- Nenhum serviço pago, função ou alteração de faturamento foi introduzido.
