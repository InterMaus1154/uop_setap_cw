from models.user import User

from database.db import SessionLocal
def seed_users():
    db = SessionLocal()

    users = [
        User(user_fname="John", user_lname="Doe", user_email="johndoe@port.ac.uk")
    ]

    db.add_all(users)
    db.commit()
    db.close()

if __name__ == '__main__':
    seed_users()