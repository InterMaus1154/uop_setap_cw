import os
import sys

from alembic.config import Config
from alembic import command
from sqlalchemy import text, inspect

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.user import User
from database.db import engine, Base

def drop_tables():
    print("Dropping tables...")

    with engine.connect() as conn:

        conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))

        conn.execute(text("CREATE SCHEMA public"))

        conn.execute(text("GRANT ALL ON SCHEMA public to postgres"))
        conn.execute(text("GRANT ALL ON SCHEMA public to public"))

        conn.commit()

    print("All tables dropped")

def create_tables():
    print("Creating tables")
    Base.metadata.create_all(engine)
    print("Tables created")

if __name__ == '__main__':
    drop_tables()
    create_tables()
