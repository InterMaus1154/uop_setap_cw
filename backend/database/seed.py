import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from models.user import User

from database.db import SessionLocal


def seed_users():
    print("Seeding users")
    db = SessionLocal()

    users = [
        User(user_fname="John", user_lname="Doe", user_email="johndoe@port.ac.uk"),
        User(user_fname="Jane", user_lname="Doe", user_email="janedoe@port.ac.uk"),
        User(user_fname="Carl", user_lname="Johnson", user_email="carljohnson@port.ac.uk")
    ]

    db.add_all(users)
    db.commit()
    db.close()
    print("Users seeded")


def seed_pins():
    print("Seeding pins")
    print("Pins seeded")


def seed_all():
    print("Start seeding")
    seed_users()
    seed_pins()


if __name__ == '__main__':
    seed_all()
