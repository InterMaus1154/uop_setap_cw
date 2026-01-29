# run this file to migrate and seed the database

from migrate import drop_tables, run_migrations
from seed import seed_all

def migrate_seed():
    drop_tables()
    run_migrations()
    seed_all()

if __name__ == '__main__':
    migrate_seed()