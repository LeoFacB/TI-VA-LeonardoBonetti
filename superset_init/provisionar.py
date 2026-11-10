"""Cadastra no Superset as consultas marcadas com "-- @dataset:" em
sql/consultas.sql, como dataset virtual e como Saved Query.

Idempotente: o que ja existe (pelo nome) e mantido como esta.
"""
import os
import re
import sys

from superset.app import create_app

ARQUIVO_SQL = "/app/sql/consultas.sql"
NOME_BANCO = "leonardobonetti"
SCHEMA = "leonardobonetti"
MARCA = re.compile(r"^--\s*@dataset:\s*(?P<nome>[\w]+)\s*\|\s*(?P<titulo>.+?)\s*$")


def ler_consultas(caminho):
    consultas = []
    atual = None
    with open(caminho, encoding="utf-8") as f:
        for linha in f:
            m = MARCA.match(linha)
            if m:
                atual = {"nome": m["nome"], "titulo": m["titulo"], "linhas": []}
                consultas.append(atual)
            elif atual is not None and not linha.lstrip().startswith("--"):
                atual["linhas"].append(linha.rstrip())
    for c in consultas:
        c["sql"] = "\n".join(c.pop("linhas")).strip().rstrip(";").strip()
    return consultas


def main():
    app = create_app()
    with app.app_context():
        from superset import db, security_manager
        from superset.connectors.sqla.models import SqlaTable
        from superset.models.core import Database
        from superset.models.sql_lab import SavedQuery

        banco = db.session.query(Database).filter_by(database_name=NOME_BANCO).one_or_none()
        if banco is None:
            sys.exit(f"Conexao '{NOME_BANCO}' nao encontrada no Superset.")

        admin = security_manager.find_user(username=os.environ["SUPERSET_ADMIN_USER"])

        for c in ler_consultas(ARQUIVO_SQL):
            dataset = (
                db.session.query(SqlaTable)
                .filter_by(database_id=banco.id, schema=SCHEMA, table_name=c["nome"])
                .one_or_none()
            )
            if dataset is None:
                dataset = SqlaTable(
                    table_name=c["nome"],
                    database=banco,
                    schema=SCHEMA,
                    sql=c["sql"],
                    description=c["titulo"],
                    owners=[admin] if admin else [],
                )
                db.session.add(dataset)
                db.session.flush()
                dataset.fetch_metadata()
                print(f"dataset criado: {c['nome']}")
            else:
                print(f"dataset ja existe: {c['nome']}")

            # A lista de Saved Queries mostra apenas as do usuario criador.
            dono = admin.id if admin else None
            consulta = db.session.query(SavedQuery).filter_by(label=c["titulo"]).one_or_none()
            if consulta is None:
                db.session.add(
                    SavedQuery(
                        label=c["titulo"],
                        description=f"Dataset: {c['nome']}",
                        sql=c["sql"],
                        db_id=banco.id,
                        schema=SCHEMA,
                        user_id=dono,
                        created_by_fk=dono,
                        changed_by_fk=dono,
                    )
                )
                print(f"saved query criada: {c['titulo']}")
            elif consulta.created_by_fk is None:
                consulta.created_by_fk = consulta.changed_by_fk = dono
                print(f"saved query ajustada: {c['titulo']}")

        db.session.commit()


if __name__ == "__main__":
    main()
