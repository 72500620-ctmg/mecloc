# Reavaliação e correção da busca — 2026-11-09

Registro da primeira etapa. A correção de inicialização, a contingência limitada e a publicação posteriores estão em [Correção do site e localização inicial](CORRECAO_SITE_LOCALIZACAO_2026-11-09.md).

Origem: pedido do usuário ao Codex para verificar novamente e corrigir a descoberta de oficinas, pneus, lava-jatos e outros cuidados com carros, excluindo concessionárias. Fuso: America/Sao_Paulo. Base inicial desta etapa: commit `662d36a`.

## Resultado

Correção aplicada no código local. A busca agora valida a atividade dos estabelecimentos em todos os caminhos externos, exclui concessionárias/revendas e mecânica exclusiva de motos/caminhões, mantém as categorias recebidas e diferencia respostas completas, parciais e falhas.

O aumento anterior do limite para 400 não resolvia os problemas da auditoria. Nesta etapa, o corte foi removido da consulta Overpass. A área continua explícita: raio de 8 km por padrão ou os limites escolhidos no mapa. Isso não equivale a um levantamento completo de uma cidade inteira.

## Alterações

- `Workshop.acceptsOsmTags` centraliza a aceitação por atividade e a exclusão de venda de veículos, nomes explicitamente identificados como concessionárias/revendas e atividades fora do escopo. Uma tag de serviço com valor `no` não basta para incluir um comércio.
- Overpass consulta oficinas, pneus, lavagem, peças/acessórios e serviços automotivos declarados. Seletores por nome também exigem atividade válida. Aspas e operadores em nomes são escapados como texto literal.
- Photon recebe filtros por atividade e área, e seus resultados passam pela mesma validação local. Tipos OSM node/way/relation são preservados. Resultados sem atividade automotiva identificável são descartados.
- A busca literal de nome usa Overpass; se ela não encontra correspondência, Photon pode recuperar variações como `Joao`/`João`. Esse conjunto é sinalizado como parcial. O parceiro local já existente continua sujeito ao limite geográfico.
- Oficinas podem atender várias categorias, com persistência de `additionalCategories`. Tags de óleo, funilaria, pintura, estética, pneus, elétrica, vidros e outros serviços alimentam a classificação. `craft=car_repair` sozinho não é tratado como funilaria.
- Filtros normalizam acentos e pontuação, reconhecem termos comuns de categorias e consultam serviços adicionais. Uma localidade geocodificada define a área; ela não permanece exigindo que todos os cadastros tenham a cidade no endereço.
- Uma correspondência local deixa de interromper a consulta remota de outros resultados. Ao trocar de área, a lista passa a refletir a consulta atual; cadastros próprios distantes não são misturados à região. Favoritos permanecem persistidos.
- Ordenação usa a distância sem arredondamento prévio. Antes, o cálculo padrão arredondava quilômetros e empatava muitos estabelecimentos próximos.
- Cache por área exata, validade de cinco minutos, até 32 entradas e compartilhamento de chamadas simultâneas da mesma área. Respostas parciais não são guardadas como completas.
- Dois endpoints Overpass distintos substituem a sequência com dois endereços do mesmo serviço. Prazo padrão do cliente de 7 s e prazo do servidor de 5 s; timeout dispara cancelamento HTTP. O mínimo de `http` passou para `^1.5.0`, que inclui suporte a cancelamento; a versão resolvida existente, 1.6.0, foi mantida.
- Respostas com `remark` tentam outra fonte e preservam dados parciais quando disponíveis. A interface exibe “Busca incompleta” e “Tentar novamente”; nova tentativa repete os argumentos da busca anterior, incluindo a área do mapa.
- Nominatim é mantido para geocodificar localidades/endereços; deixou de ser usado para enumerar estabelecimentos como último fallback.

## Validação

- `flutter analyze --no-pub`: sem problemas encontrados.
- `flutter test --no-pub --reporter expanded`: 52 testes aprovados, incluindo 18 novos testes de regressão da busca e um teste adicional da interface de aviso parcial.
- Caso com 450 estabelecimentos verifica ausência do antigo corte e ordenação correta por proximidade.
- Casos específicos verificam rejeição de concessionárias/restaurantes/motos, categorias e persistência, nomes com aspas e sem acento, falhas e respostas parciais, cancelamento, validade do cache, chamadas simultâneas, troca de região e repetição da área no retry.
- Compilação web validada nesta sessão com `flutter build web --no-pub`; artefatos em `build/web`. O build emite aviso de fonte Cupertino não encontrada, sem impedir a compilação.
- Testes usam dados controlados; os avisos de Firebase não inicializado durante os testes são dos caminhos de fallback locais. Não houve modificação dos dados ou das regras do Firestore de produção.

## Limites ainda presentes

- As fontes externas continuam dependentes dos estabelecimentos cadastrados e corretamente classificados no OpenStreetMap. Comércios ausentes ou marcados incorretamente podem continuar faltando ou exigir revisão cadastral.
- Photon é uma contingência por relevância e possui limite próprio; seus resultados não são apresentados como conjunto completo.
- Tentativas públicas nesta sessão: Overpass principal respondeu HTTP 406 em uma consulta via curl; Photon e Overpass private.coffee expiraram em cerca de 15 s. Não foi possível concluir uma medição ao vivo da cobertura ou da latência do app. Esses resultados não identificam a causa nem provam indisponibilidade geral dos serviços.
- Não houve publicação/deploy, execução interativa em dispositivo real ou validação de cobertura contra uma lista independente de estabelecimentos por cidade.
- Para uso em maior escala, permanece necessário avaliar infraestrutura dos provedores, controle agregado de requisições e amostragem regional de cobertura.

## Fontes técnicas

- [Photon: filtros por tags, área e limites](https://github.com/komoot/photon/blob/master/docs/api-v1.md).
- [OSM: serviços automotivos](https://wiki.openstreetmap.org/wiki/Key:service:vehicle).
- [HTTP: cancelamento a partir de 1.5.0](https://pub.dev/packages/http/changelog).

Próximo passo recomendado: executar o app na região do usuário com acesso às APIs e comparar oficinas, pneus e lava-jatos conhecidos com os resultados retornados. A correção local elimina os defeitos reproduzidos, mas não constitui garantia de cobertura total dos estabelecimentos reais.
