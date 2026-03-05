# ------------------------------------------------------------------
# Função: processa_bioma
#
# Objetivo:
#   Executar o pipeline completo de processamento para um único bioma,
#   desde o arquivo bruto até a base estruturada final.
#
# Fluxo lógico:
#   1) Parsing do texto bruto em blocos por UP
#   2) Extração dos componentes (Fauna, Flora, etc.)
#   3) Explosão dos alvos em formato longo (1 alvo por linha)
#   4) Normalização opcional via tabela externa de correções
#   5) Inclusão da variável identificadora do bioma
#
# Parâmetros:
#   caminho_alvos      -> caminho do arquivo bruto de entrada
#   bioma              -> nome do bioma (string)
#   caminho_correcoes  -> CSV opcional com correções taxonômicas
#
# Retorno:
#   Dataframe estruturado contendo:
#     UP | COMPONENTE | ALVO | BIOMA
# ------------------------------------------------------------------
processa_bioma <- function(caminho_alvos, bioma, caminho_correcoes = NULL) {
  # ==============================================================
  # ETAPA 1 — Parsing estrutural do arquivo bruto
  #
  # Converte texto contínuo em blocos identificados por UP.
  # Resultado:
  #   UP | texto
  # ==============================================================
  parsed <- parse_alvos_brutos(caminho_alvos)
  # ==============================================================
  # ETAPA 2 — Extração dos componentes internos
  #
  # Separa o texto de cada UP em:
  #   Fauna, Flora, Fitofisionomias, Patrimonio
  #
  # Resultado:
  #   UP | texto | Fauna | Flora | ...
  # ==============================================================
  componentes <- extrai_componentes(parsed)
  # ==============================================================
  # ETAPA 3 — Explosão estrutural dos alvos
  #
  # Transforma listas textuais em estrutura relacional:
  #
  # Resultado:
  #   UP | COMPONENTE | ALVO
  #
  # Cada linha representa uma entidade individual.
  # ==============================================================
  long <- explode_alvos(componentes)
  # ==============================================================
  # ETAPA 4 — Normalização opcional
  #
  # Se for fornecido caminho de correções:
  #   aplica padronização adicional via tabela externa.
  #
  # Isso permite:
  #   - corrigir erros ortográficos
  #   - unificar sinônimos
  #   - padronizar grafia taxonômica
  #
  # Caso NULL:
  #   mantém apenas a normalização estrutural anterior.
  # ==============================================================
  if (!is.null(caminho_correcoes)) {
    long <- normaliza_alvos(long, caminho_correcoes)
  }
  # ==============================================================
  # ETAPA 5 — Inclusão da variável BIOMA
  #
  # Adiciona coluna identificadora para permitir:
  #   - consolidação multi-bioma posterior
  #   - análises comparativas
  #   - rastreabilidade de origem
  #
  # Não altera estrutura prévia, apenas acrescenta metadado.
  # ==============================================================
  long |>
    mutate(BIOMA = bioma)
}
