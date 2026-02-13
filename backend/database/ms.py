# run this file to migrate and seed the database

from migrate import drop_tables, create_tables
from seed import seed_all

def migrate_seed():
    drop_tables()
    create_tables()
    seed_all()

if __name__ == '__main__':
    migrate_seed()