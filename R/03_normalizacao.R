# ------------------------------------------------------------------
# Função: normaliza_alvos
#
# Objetivo:
#   Realizar a padronização final da coluna ALVO após o processo
#   de parsing e explosão estrutural.
#
#   A função executa:
#     1) Limpeza estrutural básica
#     2) Aplicação opcional de tabela externa de correções
#     3) Remoção de duplicatas finais
#
# Parâmetros:
#   df                -> dataframe contendo ao menos a coluna ALVO
#   caminho_correcoes -> caminho opcional para CSV com duas colunas:
#                        ALVO_antigo | ALVO_novo
#
# Retorno:
#   Dataframe com ALVO padronizado e sem duplicatas.
# ------------------------------------------------------------------
normaliza_alvos <- function(df, caminho_correcoes = NULL) {
  # ==============================================================
  # ETAPA 1 — Limpeza estrutural básica
  #
  # Objetivo:
  #   Remover ruído residual que pode gerar duplicação artificial.
  #
  # Essa etapa é deliberadamente conservadora:
  #   não altera grafia científica,
  #   apenas remove problemas estruturais.
  # ==============================================================
  df <- df |>
    dplyr::mutate(
      # Remove espaços no início e no fim da string
      # Evita duplicatas como:
      #   "Panthera onca"
      #   "Panthera onca "
      ALVO = stringr::str_trim(ALVO),
      # Remove ponto-e-vírgula residual no final
      # Exemplo:
      #   "Cedrela fissilis;"
      #   → "Cedrela fissilis"
      ALVO = stringr::str_remove(ALVO, ";+$"),
      # Remove múltiplos espaços internos
      # Exemplo:
      #   "Panthera   onca"
      #   → "Panthera onca"
      ALVO = stringr::str_squish(ALVO)
    ) |>
    # Remove entradas inválidas
    dplyr::filter(
      !is.na(ALVO), # Remove NAs
      ALVO != "", # Remove strings vazias
      ALVO != ";" # Remove delimitador isolado
    )
  
  # ==============================================================
  # ETAPA 2 — Aplicação opcional de correções manuais
  #
  # Essa etapa permite:
  #   - corrigir erros ortográficos
  #   - unificar sinônimos
  #   - resolver divergências taxonômicas
  #
  # A lógica é controlada externamente via CSV,
  # garantindo reprodutibilidade.
  # ==============================================================
  if (!is.null(caminho_correcoes)) {
    # Lê arquivo de correções
    # Força todas as colunas como character
    # para evitar coerção indevida de strings
    correcoes <- readr::read_csv(
      caminho_correcoes,
      col_types = readr::cols(.default = readr::col_character())
    )
    # Estrutura esperada do CSV:
    #   ALVO_antigo | ALVO_novo
    #
    # Exemplo:
    #   Cedrela fissilis; Cedrela fissilis Vell.
    #   Panthera Onca; Panthera onca
    df <- df |>
      # Junta tabela original com tabela de correções
      # Se houver correspondência em ALVO_antigo,
      # ALVO_novo será preenchido.
      dplyr::left_join(
        correcoes,
        by = c("ALVO" = "ALVO_antigo")
      ) |>
      dplyr::mutate(
        # coalesce() retorna o primeiro valor não-NA
        #
        # Se houver correção → usa ALVO_novo
        # Caso contrário → mantém ALVO original
        ALVO = dplyr::coalesce(ALVO_novo, ALVO)
      ) |>
      # Remove colunas auxiliares vindas do join
      dplyr::select(-dplyr::any_of(c("ALVO_antigo", "ALVO_novo")))
  }
  
  # ==============================================================
  # ETAPA 3 — Remoção de duplicatas finais
  #
  # distinct():
  #   Remove linhas idênticas considerando todas as colunas.
  #
  # Isso é essencial após:
  #   - normalização estrutural
  #   - aplicação de correções
  #
  # Pode ocorrer que duas grafias diferentes
  # passem a apontar para o mesmo nome válido.
  # ==============================================================
  df |>
    dplyr::distinct()
}