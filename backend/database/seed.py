import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from models.sub_category import SubCategory
from models.category import Category
from models.category_level import CategoryLevel
from models.user import User

from models.pin import Pin

from database.db import SessionLocal



def seed_users():
    print("Seeding users")
    db = SessionLocal()

    users = [
        User(user_fname="John", user_lname="Doe", user_email="johndoe@port.ac.uk"),
        User(user_fname="Jane", user_lname="Doe", user_email="janedoe@port.ac.uk"),
        User(user_fname="Carl", user_lname="Johnson", user_email="carljohnson@port.ac.uk"),
        User(user_fname="Alice", user_lname="Smith", user_email="alicesmith@port.ac.uk"),
    ]

    db.add_all(users)
    db.commit()
    db.close()
    print("Users seeded")


def seed_category_levels():
    print("Seeding category levels")
    db = SessionLocal()

    category_levels = [
        CategoryLevel(cat_level_name="Danger", cat_level_ttl_mins=60),
        CategoryLevel(cat_level_name="Information", cat_level_ttl_mins=120),
        CategoryLevel(cat_level_name="Level 3", cat_level_ttl_mins=180),
    ]

    db.add_all(category_levels)
    db.commit()
    db.close()
    print("Category levels seeded")

def seed_categories():
    print("Seeding categories")
    db = SessionLocal()

    categories = [
        Category(cat_name="Theft", cat_level_id=1),
        Category(cat_name="Anti-Social Behaviour", cat_level_id=2),
        Category(cat_name="Assault", cat_level_id=3),
    ]

    db.add_all(categories)
    db.commit()
    db.close()
    print("Categories seeded")

def seed_sub_categories():
    print("Seeding sub categories")
    db = SessionLocal()

    sub_categories = [
        SubCategory(sub_cat_name="Burglary - Theft", cat_id=1),
        SubCategory(sub_cat_name="Burglary - Mugging", cat_id=1),
        SubCategory(sub_cat_name="Anti-Social Behaviour - Street", cat_id=2),
        SubCategory(sub_cat_name="Anti-Social Behaviour - Park", cat_id=2),
        SubCategory(sub_cat_name="Assault - Physical", cat_id=3),
        SubCategory(sub_cat_name="Assault - Verbal", cat_id=3),
    ]

    db.add_all(sub_categories)
    db.commit()
    db.close()
    print("Sub categories seeded")

def seed_pins():
    print("Seeding pins")
    db = SessionLocal()
    pins = [
        Pin(cat_id =1, user_id=1, pin_title="Sample Pin 1", pin_latitude=50.8198, pin_longitude=-1.0880, pin_expire_at="2024-12-31 23:59:59"), #minimum amount of data required for a pin
        Pin(cat_id = 2, sub_cat_id=1, user_id=2, pin_title="Sample Pin 2", pin_description="This is a sample pin description", pin_picture_path="/images/pin2.jpg", pin_latitude=50.8200, pin_longitude=-1.0900, pin_isactive=True, pin_expire_at="2024-11-30 23:59:59"),

    ]

    db.add_all(pins)
    db.commit()
    db.close()
    print("Pins seeded")


def seed_all():
    print("Start seeding")
    seed_users()
    seed_category_levels()
    seed_categories()
    seed_sub_categories()
    seed_pins()


if __name__ == '__main__':
    seed_all()
