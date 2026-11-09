# Correção do site: consulta de estabelecimentos e localização inicial

Etapa posterior: [busca automática com cache e proteção de requisições](BUSCA_AUTOMATICA_2026-11-09.md), publicada no mesmo dia.

Data: 2026-11-09, America/Sao_Paulo. Origem: relato do usuário com captura de tela e confirmação de que usa o site publicado.

## Causas confirmadas

- O Overpass principal respondeu HTTP 406 inclusive a uma consulta simples; as tentativas aos outros serviços usados para estabelecimentos expiraram neste ambiente. A consulta de região continuava funcionando. A contingência anterior não tinha uma fonte acessível que retornasse resultados neste cenário.
- `MapOptions.initialCenter` só era usado ao montar o mapa. Quando o GPS chegava depois, o provider mudava, mas a câmera não acompanhava essa mudança. A sincronização com Firestore também era aguardada antes de restaurar a posição e iniciar a localização.
- No plugin web, `requestPermission()` já obtém uma posição. O app em seguida pedia outra posição, com um prazo de seis segundos na etapa de permissão. Isso tornava o fluxo frágil enquanto o usuário respondia ao navegador.

## Correções publicadas

- A câmera acompanha a posição inicial assim que ela chega, antes de terminar a consulta de estabelecimentos. Restaura a posição salva enquanto aguarda a atualização. Ao arrastar o mapa ou pesquisar outro local, o acompanhamento inicial é interrompido.
- A referência fixa a Brasília foi removida. Enquanto não há localização conhecida, a interface orienta a usar a localização ou informar uma cidade, sem apresentar Brasília como localização do usuário.
- Firestore sincroniza em segundo plano, com prazo máximo, sem bloquear o início do GPS ou a restauração local.
- Na web, uma única chamada de geolocalização pede a permissão nativa do navegador e obtém a posição. `WebSettings` permite aproveitar uma posição recente e dá mais tempo ao navegador. Permissão negada continua gerando uma orientação explícita.
- Se os servidores de descoberta falham, uma contingência Nominatim busca um conjunto limitado de correspondências de oficinas, pneus e lava-jatos. Usa até dez resultados por consulta, sem paginação ou varredura em grade, valida as atividades e aplica o recorte geográfico. A lista continua marcada como parcial.
- A fila Nominatim compartilha o limite entre geocodificação e contingência, espaçando requisições em pelo menos um segundo nesta instância do app. Servidores indisponíveis entram em espera por 45 segundos; a movimentação do mapa não dispara consultas automáticas enquanto a lista é parcial.

## Validação

- Análise estática: sem problemas.
- Suíte completa: **57 testes aprovados**. Inclui GPS que chega após a montagem, câmera atualizada antes de a consulta terminar, câmera mantida mesmo com falha da consulta, restauração da posição salva, geolocalização web sem Permissions API e contingência tipada com espaçamento de requisições.
- Teste real da contingência em Belo Horizonte, simulando os outros servidores indisponíveis e consultando Nominatim pela implementação Dart: **21 estabelecimentos em 2.366 ms**, com oficinas, pneus e lava-jatos, todos tratados como lista parcial. Esse tempo corresponde à contingência testada; não inclui espera por GPS ou por servidores sem resposta.
- Consulta pública de pneus confirmou MINAS PNEUS e Brutos Pneus. Resposta incluiu `access-control-allow-origin: *`, permitindo leitura pelo site.
- `flutter build web --no-pub` concluído; permanece aviso não bloqueante de fonte Cupertino.
- Publicado em **https://mecloc.web.app**, aproximadamente às **15:02**, somente Hosting. Versão Firebase: `0c2a72249359f9ba`.
- Verificação após publicação: HTTP 200 para `main.dart.js`; SHA-256 servido idêntico ao da compilação local: `6007759CAA5E1407839E6485B9988389DEED586965E4A5C2F5CF42795FA1A0BF`.
- Automação de navegador indisponível por erro de inicialização das ferramentas; não houve teste interativo em um iPhone. A verificação combinou testes de widgets, integração HTTP real e conferência do arquivo publicado.

## Limites e próximo passo

Reabrir/recarregar o site no aparelho e permitir localização se o navegador solicitar. A posição real depende dessa permissão e da disponibilidade da localização do dispositivo. A contingência fornece correspondências relevantes, não cobertura completa da região.

O Nominatim público possui [política de uso](https://operations.osmfoundation.org/policies/nominatim/) com capacidade limitada: máximo de uma requisição por segundo para o aplicativo agregado e proibição de coleta sistemática de todos os POIs. A implementação não tenta obter um conjunto completo; uso em escala exige proxy com controle agregado ou serviço próprio/contratado. A limitação local da fila não controla vários usuários simultâneos.

Esta etapa complementa e atualiza as decisões de [correção da busca](CORRECAO_BUSCA_2026-11-09.md). Não foram alteradas regras ou dados Firestore de produção.
