import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from models.pin_report import PinReport, PinReportType
from models.admin import Admin
from models.user_ban import UserBan, UserBanType
from models.pin_reaction import PinReaction
from models.sub_category import SubCategory
from models.category import Category
from models.category_level import CategoryLevel
from models.user import User

from models.pin import Pin

from database.db import SessionLocal



def seed_users():
    print("Seeding users")

    users = [
        User(user_fname="John", user_lname="Doe", user_email="johndoe@port.ac.uk"),
        User(user_fname="Jane", user_lname="Doe", user_email="janedoe@port.ac.uk"),
        User(user_fname="Carl", user_lname="Johnson", user_email="carljohnson@port.ac.uk"),
        User(user_fname="Alice", user_lname="Smith", user_email="alicesmith@port.ac.uk"),
    ]
    seed_template(users)
    
    print("Users seeded")

def seed_admins():
    print("Seeding admins")

    admins = [
        Admin(admin_fname="Admin", admin_lname="User", admin_email="admin@port.ac.uk", admin_password="adminpassword"),
        Admin(admin_fname="Super", admin_lname="Admin", admin_email="superadmin@port.ac.uk", admin_password="superadminpassword"),
    ]
    seed_template(admins)
    
    print("Admins seeded")

def seed_user_bans():
    print("Seeding user bans")

    bans = [
        UserBan(user_id=3, admin_id=1, ban_reason="Spamming", ban_expiry="2024-12-31 23:59:59", ban_type=UserBanType.TEMPORARY),
        UserBan(user_id=2, admin_id=2, ban_reason="Inappropriate content", ban_type=UserBanType.PERMANENT),
    ]

    seed_template(bans)
    print("User bans seeded")




def seed_category_levels():
    print("Seeding category levels")

    category_levels = [
        CategoryLevel(cat_level_name="Danger", cat_level_ttl_mins=60),
        CategoryLevel(cat_level_name="Information", cat_level_ttl_mins=120),
        CategoryLevel(cat_level_name="Level 3", cat_level_ttl_mins=180),
    ]

    seed_template(category_levels)
    print("Category levels seeded")

def seed_categories():
    print("Seeding categories")

    categories = [
        Category(cat_name="Theft", cat_level_id=1),
        Category(cat_name="Anti-Social Behaviour", cat_level_id=2),
        Category(cat_name="Assault", cat_level_id=3),
    ]
    seed_template(categories)
   
    print("Categories seeded")

def seed_sub_categories():
    print("Seeding sub categories")

    sub_categories = [
        SubCategory(sub_cat_name="Burglary - Theft", cat_id=1),
        SubCategory(sub_cat_name="Burglary - Mugging", cat_id=1),
        SubCategory(sub_cat_name="Anti-Social Behaviour - Street", cat_id=2),
        SubCategory(sub_cat_name="Anti-Social Behaviour - Park", cat_id=2),
        SubCategory(sub_cat_name="Assault - Physical", cat_id=3),
        SubCategory(sub_cat_name="Assault - Verbal", cat_id=3),
    ]

    seed_template(sub_categories)
    print("Sub categories seeded")

def seed_pins():
    print("Seeding pins")
    pins = [
        Pin(cat_id=1, user_id=1, pin_title="Sample Pin 1", pin_latitude=50.8198, pin_longitude=-1.0880, pin_expire_at="2024-12-31 23:59:59"), #minimum amount of data required for a pin
        Pin(cat_id=2, sub_cat_id=1, user_id=2, pin_title="Sample Pin 2", pin_description="This is a sample pin description", pin_picture_path="/images/pin2.jpg", pin_latitude=50.8200, pin_longitude=-1.0900, pin_isactive=True, pin_expire_at="2024-11-30 23:59:59"),
        Pin(cat_id=1, user_id=3, pin_title="Southsea Seafront Report", pin_latitude=50.7833, pin_longitude=-1.0875, pin_expire_at="2025-01-15 12:00:00"),
        Pin(cat_id=3, sub_cat_id=6, user_id=4, pin_title="Fratton Park Incident", pin_description="Reported altercation near stadium", pin_latitude=50.8072, pin_longitude=-1.0628, pin_isactive=True, pin_expire_at="2024-12-01 18:00:00"),
        Pin(cat_id=2, sub_cat_id=3, user_id=1, pin_title="Old Portsmouth ASB", pin_description="Loud groups in the evening", pin_picture_path="/images/asb1.jpg", pin_latitude=50.7989, pin_longitude=-1.1066, pin_isactive=False, pin_expire_at="2025-02-20 08:00:00"),
        Pin(cat_id=1, sub_cat_id=2, user_id=2, pin_title="Mugging - Commercial Road", pin_latitude=50.7964, pin_longitude=-1.0887, pin_expire_at="2024-10-15 09:30:00"),
        Pin(cat_id=3, user_id=4, pin_title="Assault - Palmerston Road", pin_description="Victim injured, seeking witnesses", pin_latitude=50.8079, pin_longitude=-1.0635, pin_isactive=True, pin_expire_at="2025-03-01 00:00:00"),
        Pin(cat_id=2, sub_cat_id=4, user_id=3, pin_title="Park ASB - Victoria Park", pin_picture_path="/images/park1.jpg", pin_latitude=50.8110, pin_longitude=-1.0905, pin_isactive=True, pin_expire_at="2024-12-15 23:59:59"),
        Pin(cat_id=1, user_id=4, pin_title="Bicycle Theft - Elm Grove", pin_latitude=50.8190, pin_longitude=-1.0600, pin_expire_at="2025-01-01 00:00:00"),
        Pin(cat_id=2, sub_cat_id=3, user_id=2, pin_title="Street Nuisance - Cascades", pin_description="Ongoing nuisance at night", pin_latitude=50.8055, pin_longitude=-1.0782, pin_expire_at="2024-11-20 07:00:00"),
        Pin(cat_id=1, sub_cat_id=1, user_id=1, pin_title="Burglary - Copnor", pin_description="Break-in reported", pin_latitude=50.8420, pin_longitude=-1.0380, pin_isactive=False, pin_expire_at="2025-04-10 12:00:00"),
        Pin(cat_id=3, sub_cat_id=5, user_id=3, pin_title="Assault - Portsmouth Road", pin_latitude=50.8225, pin_longitude=-1.0612, pin_expire_at="2024-12-05 20:00:00"),
        Pin(cat_id=2, user_id=4, pin_title="ASB - Gunwharf", pin_description="Groups causing disturbance near waterfront", pin_picture_path="/images/gunwharf.jpg", pin_latitude=50.7976, pin_longitude=-1.1085, pin_isactive=True, pin_expire_at="2025-02-28 22:30:00"),
        Pin(cat_id=1, sub_cat_id=2, user_id=2, pin_title="Theft - Gun Street Market", pin_latitude=50.7998, pin_longitude=-1.0950, pin_expire_at="2024-11-01 10:00:00"),
        Pin(cat_id=3, user_id=1, pin_title="Assault - Mile End", pin_description="Verbal altercation escalated", pin_latitude=50.8280, pin_longitude=-1.0605, pin_isactive=True, pin_expire_at="2024-12-20 23:00:00"),
        Pin(cat_id=2, sub_cat_id=4, user_id=4, pin_title="Park Trouble - Hilsea Lido", pin_latitude=50.8490, pin_longitude=-1.0680, pin_expire_at="2025-05-05 09:00:00"),
        Pin(cat_id=1, user_id=3, pin_title="Shoplifting - Cascades", pin_description="Suspected shoplifting reported", pin_picture_path="/images/shoplift1.jpg", pin_latitude=50.8060, pin_longitude=-1.0770, pin_isactive=False, pin_expire_at="2024-10-25 14:00:00"),
        Pin(cat_id=2, user_id=1, pin_title="ASB - Southsea Common", pin_latitude=50.7915, pin_longitude=-1.0889, pin_expire_at="2025-03-15 18:30:00"),

    ]
    

    seed_template(pins)
    print("Pins seeded")

def seed_pin_reactions():
    print("Seeding pin reactions")
    reactions = [
        PinReaction(pin_id=1, user_id=2, reaction_value=1),
        PinReaction(pin_id=1, user_id=3, reaction_value=1),
        PinReaction(pin_id=2, user_id=1, reaction_value=-1),
        PinReaction(pin_id=3, user_id=4, reaction_value=1),
        PinReaction(pin_id=4, user_id=1, reaction_value=-1),
    ]
    seed_template(reactions)
    print("Pin reactions seeded")




def seed_pin_reports():
    print("Seeding pin reports")
    

    reports = [
        PinReport(pin_id=1, user_id=2, report_type=PinReportType.INACCURATE),
        PinReport(pin_id=2, user_id=3, report_type=PinReportType.RESOLVED),
        PinReport(pin_id=3, user_id=1, report_type=PinReportType.DUPLICATE),
        PinReport(pin_id=4, user_id=4, report_type=PinReportType.EXPIRED),
        PinReport(pin_id=5, user_id=1, report_type=PinReportType.MISLEADING),
        PinReport(pin_id=6, user_id=2, report_type=PinReportType.SPAM),
        PinReport(pin_id=7, user_id=3, report_type=PinReportType.INAPPROPRIATE),
        PinReport(pin_id=8, user_id=4, report_type=PinReportType.SPAM),
        PinReport(pin_id=9, user_id=1, report_type=PinReportType.RESOLVED),
        PinReport(pin_id=10, user_id=2, report_type=PinReportType.DUPLICATE),
    ]

    seed_template(reports)
    print("Pin reports seeded")

def seed_template(data_to_seed):
    db = SessionLocal()
    db.add_all(data_to_seed)
    db.commit()
    db.close()


def seed_all():
    print("Start seeding")
    seed_users()
    seed_admins()
    seed_user_bans()
    seed_category_levels()
    seed_categories()
    seed_sub_categories()
    seed_pins()
    seed_pin_reactions()
    seed_pin_reports()
    print("Finished seeding")

if __name__ == '__main__':
    seed_all()
