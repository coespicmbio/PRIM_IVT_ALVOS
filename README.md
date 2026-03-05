# PRIM_IVT_ALVOS

Estruturação automatizada dos **alvos de conservação** presentes no
Plano de Redução de Impactos de Infraestruturas Viárias Terrestres sobre
a Biodiversidade - PRIM-IVT.

Este repositório contém um pipeline em R desenvolvido para extrair,
padronizar e organizar os alvos de conservação (Fauna, Flora,
Fitofisionomias e Patrimônio Espeleológico) a partir dos arquivos brutos
disponíveis no Material Suplementar do PRIM IVT, transformando o
conteúdo textual em uma base de dados estruturada.

O objetivo é permitir análise, revisão técnica e integração com outras
bases utilizadas nas análises da COESP/CGCON/ICMBio e possíveis
interessados no uso dos dados.

------------------------------------------------------------------------

## Contexto

Nos arquivos originais, os alvos de conservação aparecem como blocos de
texto associados a cada **Unidade de Planejamento (UP)**.

Esses blocos possuem características que podem dificultar análise
direta:

-   texto contínuo
-   separadores inconsistentes
-   pequenas variações de grafia

Este projeto resolve esse problema criando um **pipeline reprodutível**
que transforma os dados em uma base tabular limpa.

------------------------------------------------------------------------

## Estrutura do pipeline

O fluxo de processamento ocorre em cinco etapas principais:

1.  **Parse dos blocos brutos**

    Função: `parse_alvos_brutos()`

    -   lê o arquivo de entrada em formato \*.csv gerado a partir do
        material suplementar
    -   identifica os blocos de texto associados a cada Unidade de
        Planejamento (UP)
    -   produz uma tabela inicial contendo:

    UP \| texto

------------------------------------------------------------------------

2.  **Extração dos componentes**

    Função: `extrai_componentes()`

    -   identifica e separa os blocos:

        -   Fauna
        -   Flora
        -   Fitofisionomias
        -   Patrimônio Espeleológico

    -   produz uma tabela com colunas estruturais:

    UP \| Fauna \| Flora \| Fitofisionomias \| Patrimonio

------------------------------------------------------------------------

3.  **Explosão dos alvos**

    Função: `explode_alvos()`

    -   transforma os componentes em formato **long** (transposto)
    -   separa alvos individuais
    -   remove separadores e ruído textual

    Resultado:

    UP \| COMPONENTE \| ALVO

------------------------------------------------------------------------

4.  **Normalização**

    Função: `normaliza_alvos()`

    -   limpeza estrutural final
    -   aplicação opcional de tabela de correções de grafia

    Arquivo de referência:

    data_reference/correcoes_padrao.csv

------------------------------------------------------------------------

5.  **Pipeline por bioma**

    Função: `processa_bioma()`

    Executa todas as etapas anteriores e adiciona a coluna:

    BIOMA

------------------------------------------------------------------------

## Estrutura do repositório

```         
PRIM_IVT_ALVOS
│
├── .gitgnore
├── PRIM_IVT_ALVOS.Rproj
├── README.md
├── processamento_alvos.Rmd
├── processamento_alvos.html
│
├── R
│   ├── 01_parse_alvos.R
│   ├── 02_transforma_long.R
│   ├── 03_normalizacao.R
│   ├── 04_pipeline_bioma.R
│   └── run_pipeline.R
│
├── data_raw
│   ├── IVT_amazonia.csv
│   ├── IVT_caatinga.csv
│   ├── IVT_cerrado.csv
│   ├── IVT_mata_atlantica.csv
│   ├── IVT_pampa.csv
│   └── IVT_pantanal.csv
│
├── data_reference
│   └── correcoes_padrao.csv
│
└── data_output
    ├── alvos_processados_amazonia.csv
    ├── alvos_processados_caatinga.csv
    ├── alvos_processados_cerrado.csv
    ├── alvos_processados_mata_atlantica.csv
    ├── alvos_processados_pampa.csv
    └── alvos_processados_pantanal.csv
```

------------------------------------------------------------------------

## Disponibilidade dos arquivos de dados

Os arquivos .csv utilizados como entrada no processamento não estão
incluídos neste repositório.

Isso ocorre principalmente por dois motivos:

Tamanho dos arquivos – os arquivos originais possuem grande volume de
dados, o que ultrapassa ou se aproxima dos limites recomendados para
versionamento em repositórios Git.

Boas práticas de versionamento – repositórios de código devem priorizar
scripts, funções e documentação, evitando incluir grandes bases de dados
que podem dificultar o clone, aumentar o histórico do repositório e
comprometer a performance do Git.

Assim, este repositório contém apenas o código necessário para processar
os dados, assumindo que os arquivos de entrada estejam disponíveis
localmente no diretório:

data_raw/

Pesquisadores ou equipes que necessitem acessar os arquivos de dados
utilizados neste pipeline podem solicitá-los diretamente à Coordenação
de Análises Geoespaciais para Conservação de Espécies (COESP/ICMBio).

Após obter os arquivos, basta colocá-los nos respectivos diretórios para
que o pipeline possa ser executado normalmente.

## Execução

Execução (script principal):

```         
R/run_pipeline.R
```

O script principal percorre automaticamente todos os arquivos \*.csv
separados por biomas na pasta `data_raw`.

Arquivos esperados:

```         
IVT_amazonia.csv
IVT_caatinga.csv
IVT_cerrado.csv
IVT_mata_atlantica.csv
IVT_pampa.csv
IVT_pantanal.csv
```

Saída gerada:

```         
data_output/alvos_processados_amazonia.csv
data_output/alvos_processados_caatinga.csv
data_output/alvos_processados_cerrado.csv
data_output/alvos_processados_mata_atlantica.csv
data_output/alvos_processados_pampa.csv
data_output/alvos_processados_pantanal.csv
```

Checagem geral:

Verificação e ajustes finos:

```         
processamento_alvos_IVT.Rmd
```

------------------------------------------------------------------------

## Estrutura da base final

Cada linha representa **um alvo de conservação associado a uma UP**.

Colunas:

UP COMPONENTE ALVO BIOMA

Exemplo:

| UP  | ALVO                 | COMPONENTE | BIOMA    |
|-----|----------------------|------------|----------|
| 101 | Leopardus wiedii     | Fauna      | amazonia |
| 101 | Bertholletia excelsa | Flora      | amazonia |

------------------------------------------------------------------------

## Dependências

Pacotes utilizados:

```         
tidyverse
stringr
purrr
readr
glue
```

Instalação:

```         
install.packages("tidyverse")
install.packages("glue")
```

------------------------------------------------------------------------

## Objetivo

Criar uma base consistente de alvos de conservação para:

-   revisão técnica
-   análise espacial
-   integração com dados geoespaciais
-   suporte a análises do PRIM-IVT
-   padronização metodológica interna

------------------------------------------------------------------------

## Autoria

COESP/CGCON/DIBIO/ICMBio

Coordenação de Análises Geoespaciais para Conservação de Espécies -
COESP

Coordenação Geral de Estratégias para Conservação - CGCON

Diretoria de Pesquisa, Avaliação e Monitoramento da Biodiversidade -
DIBIO

Instituto Chico Mendes de Conservação da Biodiversidade - ICMBio

[coesp\@icmbio.gov.br](mailto:coesp@icmbio.gov.br){.email}
