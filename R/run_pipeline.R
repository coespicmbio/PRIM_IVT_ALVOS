# ------------------------------------------------------------------
# RESET COMPLETO DO AMBIENTE
#
# Remove todos os objetos existentes na sessão, incluindo objetos
# ocultos (all.names = TRUE).
#
# Objetivo:
#   Garantir que o script rode em ambiente limpo,
#   evitando efeitos colaterais de execuções anteriores.
#
# Implicação:
#   Qualquer objeto não recriado explicitamente será perdido.
# ------------------------------------------------------------------
rm(list = base::ls(all.names = TRUE))
# ------------------------------------------------------------------
# CARREGAMENTO MODULAR DO PIPELINE
#
# Cada source() carrega um módulo do processamento.
#
# A ordem é importante, pois há dependência entre funções.
# ------------------------------------------------------------------
source("R/01_parse_alvos.R") # Contém parse_alvos_brutos()
source("R/02_transforma_long.R") # Contém extrai_componentes() e explode_alvos()
source("R/03_normalizacao.R") # Contém normaliza_alvos()
source("R/04_pipeline_bioma.R")  # Contém processa_bioma()
# ------------------------------------------------------------------
# CARREGAMENTO DE PACOTES
#
# tidyverse fornece:
#   - dplyr
#   - readr
#   - purrr
#   - stringr
#   - tibble
#
# glue será usado implicitamente no write_csv via glue::glue().
# ------------------------------------------------------------------
library(tidyverse)
# ------------------------------------------------------------------
# IDENTIFICAÇÃO AUTOMÁTICA DOS ARQUIVOS DE ENTRADA
#
# list.files():
#   - Procura dentro da pasta "data_raw"
#   - pattern filtra apenas arquivos que começam com "IVT_"
#     e terminam com ".csv"
#   - full.names = TRUE retorna o caminho completo
#
# Exemplo capturado:
#   data_raw/IVT_Amazonia.csv
#   data_raw/IVT_Cerrado.csv
#
# Isso permite escalabilidade:
#   novos biomas entram automaticamente no pipeline.
# ------------------------------------------------------------------
arquivos <- list.files(
  "data_raw",
  pattern = "^IVT_.*\\.csv$",
  full.names = TRUE
)
# ------------------------------------------------------------------
# PROCESSAMENTO ITERATIVO DOS BIOMAS
#
# purrr::walk():
#   Itera sobre cada elemento de 'arquivos'
#   Executa a função definida
#   Não retorna objeto (usado para efeitos colaterais: escrita em disco)
# ------------------------------------------------------------------
purrr::walk(
  arquivos,
  function(caminho) {
    # --------------------------------------------------------------
    # EXTRAÇÃO DO NOME DO BIOMA A PARTIR DO NOME DO ARQUIVO
    #
    # basename() remove o caminho e mantém apenas o nome do arquivo.
    #
    # stringr::str_remove("^IVT_")
    #   remove prefixo "IVT_"
    #
    # stringr::str_remove("\\.csv$")
    #   remove extensão .csv no final
    #
    # Exemplo:
    #   "data_raw/IVT_Amazonia.csv"
    #   → "Amazonia"
    # --------------------------------------------------------------
    bioma <- caminho |>
      basename() |>
      stringr::str_remove("^IVT_") |>
      stringr::str_remove("\\.csv$")
    # --------------------------------------------------------------
    # EXECUÇÃO DO PIPELINE COMPLETO PARA O BIOMA
    #
    # processa_bioma executa:
    #   1) Parsing
    #   2) Extração de componentes
    #   3) Explosão estrutural
    #   4) Normalização
    #   5) Inclusão do identificador BIOMA
    #
    # caminho_correcoes:
    #   Aplica tabela padronizada de correções taxonômicas
    #   compartilhada entre todos os biomas.
    # --------------------------------------------------------------
    resultado <- processa_bioma(
      caminho_alvos = caminho,
      bioma = bioma,
      caminho_correcoes = "data_reference/correcoes_padrao.csv"
    )
    # --------------------------------------------------------------
    # ESCRITA DO RESULTADO EM DISCO
    #
    # Nome do arquivo segue padrão:
    #   alvos_processados_<bioma>.csv
    #
    # glue::glue permite interpolação segura da string.
    #
    # Cada bioma gera um arquivo independente em data_output.
    # --------------------------------------------------------------
    readr::write_csv(
      resultado,
      file = glue::glue("data_output/alvos_processados_{bioma}.csv")
    )
  }
)

