# ------------------------------------------------------------------
# Função: explode_alvos
# Objetivo:
#   Receber um dataframe já estruturado por UP e componentes
#   (Fauna, Flora, Fitofisionomias, Patrimonio)
#   e transformar o conteúdo textual em estrutura totalmente normalizada,
#   com um ALVO por linha.
#
# Resultado final:
#   Estrutura longa (long format) com colunas:
#     - UP
#     - COMPONENTE
#     - ALVO
#
# Essa função é o ponto de transição entre:
#   texto semi-estruturado
#   → base relacional utilizável para análise.
# ------------------------------------------------------------------
explode_alvos <- function(df_componentes) {
  
  df_componentes |>
  # --------------------------------------------------------------
  # Etapa 0 — Seleção explícita das colunas relevantes
  # Garante que apenas as colunas esperadas entrem no pipeline.
  # Evita que colunas auxiliares interfiram no pivot.
  # --------------------------------------------------------------
    dplyr::select(UP, Fauna, Flora, Fitofisionomias, Patrimonio) |>
  # --------------------------------------------------------------
  # Etapa 1 — Transformação para formato longo
  #
  # pivot_longer:
  #   - Converte colunas de componentes em linhas.
  #   - Cada linha passa a representar:
  #       uma UP + um COMPONENTE + um texto bruto.
  #
  # cols = -UP:
  #   Todas as colunas exceto UP serão pivotadas.
  #
  # names_to:
  #   Nome da nova coluna que armazenará o nome do componente.
  #
  # values_to:
  #   Nome da nova coluna que armazenará o conteúdo textual.
  #
  # Estrutura antes:
  #   UP | Fauna | Flora | Fitofisionomias | Patrimonio
  #
  # Estrutura depois:
  #   UP | COMPONENTE | ALVO
  #
  # Onde ALVO ainda contém uma string longa com múltiplos itens.
  # --------------------------------------------------------------
    tidyr::pivot_longer(
      cols = -UP,
      names_to = "COMPONENTE",
      values_to = "ALVO"
    ) |>
    # Remove componentes que estavam ausentes (NA)
    # Evita gerar linhas vazias artificiais.
    dplyr::filter(!is.na(ALVO)) |>
  # --------------------------------------------------------------
  # Etapa 2 — Separação estrutural completa dos alvos
  #
  # separate_rows:
  #   Divide o conteúdo textual em múltiplas linhas,
  #   usando vírgula ou ponto-e-vírgula como delimitadores.
  #
  # sep = "\\s*[,;]\\s*"
  #
  # Interpretação da regex:
  #   [,;]    → vírgula OU ponto-e-vírgula
  #   \\s*     → remove espaços antes/depois do delimitador
  #
  # Isso resolve:
  #   "Panthera onca; Puma concolor, Leopardus pardalis"
  #
  # Transformando em:
  #   uma linha por espécie.
  #
  # Este é o momento em que o banco deixa de ser texto
  # e passa a ser entidade individualizável.
  # --------------------------------------------------------------
    tidyr::separate_rows(ALVO, sep = "\\s*[,;]\\s*") |>
  # --------------------------------------------------------------
  # Etapa 3 — Normalização estrutural de texto
  #
  # Aqui ocorre a limpeza crítica para evitar
  # duplicação por ruído de formatação.
  #
  # Cada mutação corrige um tipo específico de erro estrutural.
  # --------------------------------------------------------------
  dplyr::mutate(
    # 3.1 — Inserção de espaço entre minúscula seguida de maiúscula
    #
    # Exemplo:
    #   "PantheraOnca"
    #   → "Panthera Onca"
    #
    # Regex:
    #   ([[:lower:]])([[:upper:]])
    # Captura:
    #   letra minúscula seguida de maiúscula
    #
    # Substituição:
    #   "\\1 \\2"
    # Insere espaço entre elas.
      ALVO = stringr::str_replace_all(ALVO, "([[:lower:]])([[:upper:]])", "\\1 \\2"),
      # 3.2 — Padronização de hífens
      #
      # Remove espaços ao redor de hífens:
      #   "Area - Núcleo"
      #   → "Area-Núcleo"
      #
      # Evita que variações com espaço gerem duplicatas.
      ALVO = stringr::str_replace_all(ALVO, "\\s*-\\s*", "-"),
      # 3.3 — Remove múltiplos espaços internos
      # e espaços no início/fim.
      ALVO = stringr::str_squish(ALVO),
      # 3.4 — Remove pontos no final
      #
      # "\\.+$"
      #   um ou mais pontos no final da string
      #
      # Evita duplicata:
      #   "Panthera onca."
      #   "Panthera onca"
      ALVO = stringr::str_remove(ALVO, "\\.+$"),
      # 3.5 — Remove ponto-e-vírgula residual no final
      #
      # ";+$"
      #   um ou mais ; no final
      #
      # Segurança adicional caso algum delimitador
      # não tenha sido removido antes.
      ALVO = stringr::str_remove(ALVO, ";+$")
    ) |>
  # --------------------------------------------------------------
  # Etapa 4 — Remoção final de lixo estrutural
  #
  # Remove strings vazias geradas por:
  #   - delimitadores duplicados
  #   - texto mal formatado
  #   - ruído removido nas etapas anteriores
  #
  # Garante que cada linha contenha
  # um alvo semanticamente válido.
  # --------------------------------------------------------------
    dplyr::filter(ALVO != "")
}