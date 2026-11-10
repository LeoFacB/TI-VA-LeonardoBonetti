# TI-VA — Business Intelligence com Apache Superset

Trabalho de SBD2 (TI-VA, tecnologia Business Intelligence): Apache Superset
conectado à base MySQL `leonardobonetti` (MovieLens 1M), tudo em Docker.

## Arquitetura

| Serviço    | Imagem                                   | Acesso                              |
|------------|------------------------------------------|-------------------------------------|
| `mysql`    | `mysql:8.0.40`                           | só na rede interna (`mysql:3306`)   |
| `superset-init` | mesma imagem do Superset            | roda na subida e termina            |
| `superset` | `apache/superset:4.1.1` + `pymysql`/`mysqlclient` | http://localhost:8088      |

- O dump `dados/01-leonardobonetti.zip` é descompactado para `initdb/` e
  carregado automaticamente na **primeira** subida do MySQL.
- `initdb/02-usuario-superset.sh` cria o usuário **só-leitura** `superset`
  (apenas `SELECT` em `leonardobonetti.*`) com a senha do `.env`.
- O MySQL **não** publica a porta 3306 no host (evita conflito com um MySQL
  local). O healthcheck só fica verde depois que a carga terminou; o Superset
  espera por isso.
- O serviço `superset-init` roda a cada `docker compose up`, antes do
  Superset: atualiza os metadados, cria o admin, cadastra a conexão com o
  MySQL, importa `export/dashboard.zip` (se existir) e cria um dataset virtual
  e uma Saved Query para cada consulta marcada com `-- @dataset:` em
  `sql/consultas.sql`. Todos os passos podem ser repetidos sem duplicar nada.
- Dados ficam em volumes nomeados (`mysql_data`, `superset_home`).

```
├── docker-compose.yml
├── Dockerfile
├── superset_config.py
├── superset_init/                   inicialização automática do Superset
├── .env.example
├── dados/01-leonardobonetti.zip     dump completo compactado
├── initdb/                          scripts executados pelo MySQL na 1ª subida
├── scripts/preparar_dados.sh        descompacta o dump para initdb/
├── sql/consultas.sql                consultas de BI
├── export/                          dashboard exportado do Superset
└── docs/                            formulário e roteiro do vídeo
```

## Pré-requisitos

- **Windows 11 + WSL2:** Docker Desktop com integração WSL ativada para a
  distro. Rode todos os comandos dentro do WSL, com o projeto no sistema de
  arquivos Linux (ex.: `~/code/...`, não em `/mnt/c`).
- **Linux Mint:** Docker Engine + plugin compose
  (`docker compose version` deve funcionar) e o usuário no grupo `docker`.
- `git` e `unzip` (`sudo apt install git unzip`).

## Subindo do zero

```bash
git clone <url-do-repositorio> TI-VA-LeonardoBonetti
cd TI-VA-LeonardoBonetti

# 1. Extrai o dump para initdb/
./scripts/preparar_dados.sh

# 2. Configura senhas, chave e usuário admin
cp .env.example .env
#    edite o .env; para a SECRET_KEY: openssl rand -base64 42

# 3. Sobe tudo (a 1ª subida leva ~2–5 min: carga do MySQL + init do Superset)
docker compose up -d --build
docker compose ps -a       # mysql (healthy), superset-init Exited (0), superset Up
```

Acompanhe com `docker compose logs -f mysql superset-init`. O init termina
com `>> Superset pronto.`

Acesse http://localhost:8088 e entre com `SUPERSET_ADMIN_USER` /
`SUPERSET_ADMIN_PASSWORD` do `.env`. A conexão `leonardobonetti`, os 6
datasets e as Saved Queries (SQL → Saved Queries) já estarão cadastrados.

### Conferir os dados

```bash
docker compose exec mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" leonardobonetti -e "
  SELECT COUNT(*) FROM usuario; SELECT COUNT(*) FROM filme;
  SELECT COUNT(*) FROM avaliacao; SELECT COUNT(*) FROM genero;"'
```

Esperado: usuario 6040, filme 3883, avaliacao 1000209, genero 18
(filme_genero 6408).

## Conexão do Superset com o MySQL

A conexão é criada automaticamente pelo `superset-init`. Para cadastrar à mão
(**Settings → Database Connections → + Database → MySQL**), use
*Connect this database with a SQLAlchemy URI string instead* e informe:

```
mysql+pymysql://superset:<SUPERSET_DB_PASSWORD>@mysql:3306/leonardobonetti
```

(`<SUPERSET_DB_PASSWORD>` é o valor do seu `.env`; o host é `mysql`, o nome
do serviço no compose.)

Para adicionar uma consulta aos datasets automáticos, coloque em
`sql/consultas.sql`, logo antes do comentário dela, uma linha
`-- @dataset: nome_do_dataset | Título` e rode `docker compose up -d`.

## Exportar e importar o dashboard

Exportar (gera um zip em `export/`, que é montado no container):

```bash
docker compose exec superset superset export-dashboards -f /app/export/dashboard.zip
```

Ou pela interface: **Dashboards → ⋮ → Export**, e salve o zip como
`export/dashboard.zip`.

Importar: é automático. Se `export/dashboard.zip` existir, o `superset-init`
importa o dashboard (com gráficos e datasets) a cada `docker compose up` e,
em seguida, recoloca na conexão a senha do `.env` (o zip não leva senha).
Para importar manualmente:

```bash
docker compose exec superset superset import-dashboards -p /app/export/dashboard.zip -u admin
```

## Problemas comuns

- **"Either the username or the password is incorrect"** ao cadastrar o banco:
  confira se a senha foi colada sem espaços e se nenhum gerenciador de senhas
  do navegador alterou o campo. Em caso de dúvida, use a opção de URI.
- **"Unable to migrate query editor state to backend"** no SQL Lab: acontece
  quando o SQL Lab foi aberto antes de existir uma conexão cadastrada. Limpe
  os dados do site no navegador (F12 → Application → Storage →
  *Clear site data*), recarregue e selecione o banco antes de digitar.
  Com o `superset-init`, a conexão já existe na primeira abertura, então
  isso só deve ocorrer em navegadores que acessaram uma instalação antiga.

## Resetar tudo

```bash
docker compose down -v        # remove containers E volumes (dados e Superset)
./scripts/preparar_dados.sh   # garante que o dump está em initdb/
docker compose up -d --build  # recarrega o dump do zero
```

O `superset-init` recria admin, conexão, datasets e dashboard sozinho.
