FROM apache/superset:4.1.1

USER root

# pymysql: driver usado na URI de conexão (mysql+pymysql://...)
# mysqlclient: faz o MySQL aparecer na lista de bancos da interface
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential pkg-config default-libmysqlclient-dev \
    && pip install --no-cache-dir pymysql mysqlclient \
    && apt-get purge -y --auto-remove build-essential pkg-config \
    && apt-get install -y --no-install-recommends libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

USER superset
