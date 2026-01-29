
from alembic.config import Config
from alembic import command
from sqlalchemy import text, inspect
from db import engine, Base
import os

def drop_tables():
    print("Dropping tables...")

    with engine.connect() as conn:

        conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))

        conn.execute(text("CREATE SCHEMA public"))

        conn.execute(text("GRANT ALL ON SCHEMA public to postgres"))
        conn.execute(text("GRANT ALL ON SCHEMA public to public"))

        conn.commit()

    print("All tables dropped")

def run_migrations():
    print("Running migrations")

    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
    print("Migration completed")


if __name__ == '__main__':
    drop_tables()
    run_migrations()
