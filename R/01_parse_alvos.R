library(tidyverse)
library(stringr)

# ------------------------------------------------------------------
# Função: parse_alvos_brutos
# Objetivo:
#   Ler um arquivo texto bruto (ex: extraído de PDF) e separar blocos
#   identificados por um número inicial (UP) seguido de seu conteúdo.
# Retorno:
#   Tibble com duas colunas:
#     - UP    : identificador numérico da unidade de planejamento
#     - texto : conteúdo bruto associado àquela UP
# ------------------------------------------------------------------
parse_alvos_brutos <- function(caminho_arquivo) {
  # Lê todas as linhas do arquivo e armazena em uma tibble
  # Cada linha do arquivo vira uma observação  
  raw <- tibble(
    linha = read_lines(caminho_arquivo)
  )
  # Une todas as linhas em um único texto contínuo
  # str_squish() remove espaços extras e quebras redundantes
  # str_c(..., collapse = " ") concatena tudo em uma única string
  texto_unico <- raw$linha |>
    str_squish() |>
    str_c(collapse = " ")
  # Expressão regular:
  # (\\b\\d+\\b)  -> captura um número inteiro isolado (UP)
  # \\s+          -> um ou mais espaços
  # (.*?)         -> captura o texto associado de forma não gulosa
  # (?=...)       -> lookahead positivo: para a captura quando encontrar
  #                  outro número seguido de Fauna: ou fim do texto
  padrao <- "(\\b\\d+\\b)\\s+(.*?)(?=\\s+\\d+\\s+(Fauna:|$)|$)"
  # Aplica a regex e retorna todas as ocorrências encontradas
  # [[1]] extrai a matriz principal de resultados
  matches <- str_match_all(texto_unico, padrao)[[1]]
  # Constrói a tibble final:
  # matches[,2] -> grupo 1 da regex (UP)
  # matches[,3] -> grupo 2 da regex (texto associado)
  tibble(
    UP = matches[,2],
    texto = str_squish(matches[,3])
  ) |>
    distinct() # Remove possíveis duplicatas
}
# ------------------------------------------------------------------
# Função: extrai_componentes
# Objetivo:
#   Receber os blocos já estruturados por UP e separar os
#   componentes internos:
#     - Fauna
#     - Flora
#     - Fitofisionomias
#     - Patrimônio Espeleológico
# Retorno:
#   Tibble com colunas adicionais correspondentes a cada componente
# ------------------------------------------------------------------
extrai_componentes <- function(df_blocos) {
  
  df_blocos <- df_blocos |>
    # ----------------------------------------------------------------
  # Etapa 1: Normalização textual
  # Corrige inconsistências estruturais antes de extrair componentes
  # ----------------------------------------------------------------
    mutate(
      texto = texto |>
        # Corrige casos onde algo antes de ":" deveria ser Flora
        # Exemplo: "Alguma coisa: Flora;"
        # Reorganiza para "Flora: Alguma coisa;"
        str_replace_all(
        "([^;]+?)\\s*:\\s*Flora;",
        "Flora: \\1;"
      ) |>
        # Remove trecho fixo redundante encontrado no texto bruto de Mata Atlântica
        str_replace_all(
        "Áreas das Formações Pioneiras Vegetação, , ",
        ""
      ) |>
        # Remove ocorrência literal de "up mata"
        # alguma coisa intruziva em Mata Atlântica
        str_replace_all(
        "up mata",
        ""
      ) |>
        # Corrige caso específico onde texto vinha colado após espécie
        # Mano do céu, uma manhã tentando achar esse troço
        str_replace_all(
        "Xiphorhynchus atlanticus, Áreas das Formações Pioneiras Vegetação",
        "Xiphorhynchus atlanticus"
      ) |>
        # Padroniza grafia de Patrimônio Espeleológico
        # (?i) torna a regex case-insensitive
        # tem grafias diferentes nos pdfs
        str_replace_all(
        "(?i)patrim[oô]nio\\s+espeleol[oó]gico:",
        "Patrimônio Espeleológico:"
      ) |>
        # Junta quebras de linha indevidas entre palavras
        # Exemplo:
        # Genus
        # species  -> Genus species
        str_replace_all(
        "([A-Z][a-z]+)\\n\\s*([a-z])",
        "\\1 \\2"
      )
    ) |>
    # ----------------------------------------------------------------
  # Etapa 2: Extração dos blocos por componente
  # Cada str_extract captura o trecho entre um rótulo e o próximo
  # ----------------------------------------------------------------
    mutate(
      Fauna = str_extract(texto, "Fauna:.*?(?=Flora:|Fitofisionomias?:|Patrimônio Espeleológico:|$)"),
      Flora = str_extract(texto, "Flora:.*?(?=Fauna:|Fitofisionomias?:|Patrimônio Espeleológico:|$)"),
      Fitofisionomias = str_extract(texto, "Fitofisionomias?:.*?(?=Fauna:|Flora:|Patrimônio Espeleológico:|$)"),
      Patrimonio = str_extract(texto, "Patrimônio Espeleológico:.*?(?=Fauna:|Flora:|Fitofisionomias?:|$)")
    ) |>
    # ----------------------------------------------------------------
  # Etapa 3: Remoção dos rótulos dos componentes
  # Mantém apenas o conteúdo interno de cada seção
  # ----------------------------------------------------------------
    mutate(
      Fauna = str_remove(Fauna, "^Fauna:\\s*"),
      Flora = str_remove(Flora, "^Flora:\\s*"),
      Fitofisionomias = str_remove(Fitofisionomias, "^Fitofisionomias?:\\s*"),
      Patrimonio = str_remove(Patrimonio, "^Patrimônio Espeleológico:\\s*")
    )
}
