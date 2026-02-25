import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from models.user_relationship import UserRelationship, UserRelationshipType
from models.pin_report import PinReport, PinReportType
from models.admin import Admin
from models.user_ban import UserBan, UserBanType
from models.pin_reaction import PinReaction
from models.sub_category import SubCategory
from models.category import Category
from models.category_level import CategoryLevel
from models.user import User
from models.user_report import UserReport, UserReportType

from models.pin import Pin

from database.db import SessionLocal


def seed_users():
    print("Seeding users")

    users = [
        User(user_fname="John", user_lname="Doe", user_email="johndoe@port.ac.uk", user_displayname="JDoe92", user_use_displayname=True),
        User(user_fname="Jane", user_lname="Doe", user_email="janedoe@port.ac.uk", user_displayname="JaneDoe23", user_use_displayname=False),
        User(user_fname="Carl", user_lname="Johnson", user_email="carljohnson@port.ac.uk", user_displayname="CJ_Da_Great", user_use_displayname=True),
        User(user_fname="Alice", user_lname="Smith", user_email="alicesmith@port.ac.uk", user_displayname="AliceS", user_use_displayname=False),
        User(user_fname="Michael", user_lname="Brown", user_email="michaelbrown@port.ac.uk", user_displayname="MikeBrown88", user_use_displayname=True),
        User(user_fname="Sarah", user_lname="Wilson", user_email="sarahwilson@port.ac.uk"),
        User(user_fname="James", user_lname="Davis", user_email="jamesdavis@port.ac.uk", user_displayname="JDavis_", user_use_displayname=True),
        User(user_fname="Emma", user_lname="Miller", user_email="emmamiller@port.ac.uk", user_displayname="EmmaMiller", user_use_displayname=False),
        User(user_fname="David", user_lname="Taylor", user_email="davidtaylor@port.ac.uk", user_displayname="Taylor_D", user_use_displayname=True),
        User(user_fname="Lisa", user_lname="Anderson", user_email="lisaanderson@port.ac.uk"),

    ]
    seed_template(users)

    print("Users seeded")


def seed_user_reports():
    print("Seeding user reports")

    user_reports = [
        UserReport(reported_user_id=1, report_type=UserReportType.SPAM),
        UserReport(reported_user_id=1, report_type=UserReportType.SPAM),
        UserReport(reported_user_id=2, report_type=UserReportType.HARASSMENT),
        UserReport(reported_user_id=3, report_type=UserReportType.IMPERSONATION),

    ]

    seed_template(user_reports)
    print("User reports seeded")


def seed_admins():
    print("Seeding admins")

    admins = [
        Admin(admin_fname="Admin", admin_lname="User", admin_email="admin@port.ac.uk", admin_password="adminpassword"),
        Admin(admin_fname="Super", admin_lname="Admin", admin_email="superadmin@port.ac.uk",
              admin_password="superadminpassword"),
    ]
    seed_template(admins)

    print("Admins seeded")


def seed_user_bans():
    print("Seeding user bans")

    bans = [
        UserBan(user_id=3, admin_id=1, ban_reason="Spamming", ban_expiry="2024-12-31 23:59:59",
                ban_type=UserBanType.TEMPORARY),
        UserBan(user_id=2, admin_id=2, ban_reason="Inappropriate content", ban_type=UserBanType.PERMANENT),
    ]

    seed_template(bans)
    print("User bans seeded")


def seed_category_levels():
    print("Seeding category levels")

    category_levels = [
        CategoryLevel(cat_level_id=1, cat_level_name="Information", cat_level_color="#3B82F6", cat_level_ttl_mins=1440),
        # 1 day,
        CategoryLevel(cat_level_id=2, cat_level_name="Warning", cat_level_color="#F59E0B", cat_level_ttl_mins=1440),
        # 1 day
        CategoryLevel(cat_level_id=3, cat_level_name="Danger", cat_level_color="#EF4444", cat_level_ttl_mins=180),
        # 3 hours
    ]

    seed_template(category_levels)
    print("Category levels seeded")


def seed_categories():
    print("Seeding categories")

    categories = [
        # information
        Category(cat_id=1, cat_name="Event", cat_level_id=1),
        Category(cat_id=11, cat_name="Free Items!", cat_level_id=1),

        # warning
        Category(cat_id=2, cat_name="Theft", cat_level_id=2),
        Category(cat_id=3, cat_name="Anti-Social Behaviour", cat_level_id=2),
        Category(cat_id=4, cat_name="Suspicious Activity", cat_level_id=2),
        Category(cat_id=5, cat_name="Facility & Other Safety Hazard", cat_level_id=2),
        Category(cat_id=10, cat_name="Construction", cat_level_id=2),
        Category(cat_id=12, cat_name="Transportation Disruption", cat_level_id=2),

        # danger
        Category(cat_id=6, cat_name="Assault", cat_level_id=3),
        Category(cat_id=7, cat_name="Hazard", cat_level_id=3),
        Category(cat_id=9, cat_name="Weapon Sighting", cat_level_id=3)
    ]
    seed_template(categories)

    print("Categories seeded")


def seed_sub_categories():
    print("Seeding sub categories")

    sub_categories = [
        # event
        SubCategory(sub_cat_id=1, cat_id=1, sub_cat_name="Campus Event"),
        SubCategory(sub_cat_id=2, cat_id=1, sub_cat_name="Public Social Event"),
        SubCategory(sub_cat_id=3, cat_id=1, sub_cat_name="Sport Event"),
        SubCategory(sub_cat_id=4, cat_id=1, sub_cat_name="Store Discount"),

        # Free Items
        SubCategory(sub_cat_id=5, cat_id=11, sub_cat_name="Free Food"),
        SubCategory(sub_cat_id=6, cat_id=11, sub_cat_name="Free Pen"),
        SubCategory(sub_cat_id=7, cat_id=11, sub_cat_name="Random Free Stuff"),

        # Theft
        SubCategory(sub_cat_id=8, cat_id=2, sub_cat_name="Mugging"),
        SubCategory(sub_cat_id=9, cat_id=2, sub_cat_name="Bag Snatch"),
        SubCategory(sub_cat_id=10, cat_id=2, sub_cat_name="Pickpocketing"),
        SubCategory(sub_cat_id=11, cat_id=2, sub_cat_name="Bike Theft"),
        SubCategory(sub_cat_id=12, cat_id=2, sub_cat_name="Vehicle Break-in"),

        # Anti-Social Behaviour
        SubCategory(sub_cat_id=13, cat_id=3, sub_cat_name="Loud Groups"),
        SubCategory(sub_cat_id=14, cat_id=3, sub_cat_name="Vandalism"),
        SubCategory(sub_cat_id=15, cat_id=3, sub_cat_name="Trespassing"),
        SubCategory(sub_cat_id=16, cat_id=3, sub_cat_name="Harassment"),

        # Suspicious Activity
        SubCategory(sub_cat_id=17, cat_id=4, sub_cat_name="Suspicious Person"),
        SubCategory(sub_cat_id=18, cat_id=4, sub_cat_name="Suspicious Vehicle"),
        SubCategory(sub_cat_id=19, cat_id=4, sub_cat_name="Suspicious Group of People"),

        # Facility & Other Safety Hazard
        SubCategory(sub_cat_id=20, cat_id=5, sub_cat_name="Broken Streetlight"),
        SubCategory(sub_cat_id=21, cat_id=5, sub_cat_name="Broken Crossing Light"),
        SubCategory(sub_cat_id=22, cat_id=5, sub_cat_name="Lift Out of Service"),
        SubCategory(sub_cat_id=23, cat_id=5, sub_cat_name="Slippery Path/Stairs"),

        # Construction
        SubCategory(sub_cat_id=24, cat_id=10, sub_cat_name="Footpath Closed"),
        SubCategory(sub_cat_id=25, cat_id=10, sub_cat_name="Road Closed"),
        SubCategory(sub_cat_id=26, cat_id=10, sub_cat_name="Pedestrian Crossing Closed"),
        SubCategory(sub_cat_id=27, cat_id=10, sub_cat_name="Bike Lane Blocked/Closed"),

        # Transportation Disruption
        SubCategory(sub_cat_id=28, cat_id=12, sub_cat_name="University Bus Stop Closed"),
        SubCategory(sub_cat_id=29, cat_id=12, sub_cat_name="University Bus Disrupted/Diverted"),
        SubCategory(sub_cat_id=30, cat_id=12, sub_cat_name="Public Bus Stop Closed"),
        SubCategory(sub_cat_id=31, cat_id=12, sub_cat_name="Public Bus Disrupted/Diverted"),
        SubCategory(sub_cat_id=32, cat_id=12, sub_cat_name="Train Station Closed"),

        # Assault
        SubCategory(sub_cat_id=33, cat_id=6, sub_cat_name="Physical Assault"),
        SubCategory(sub_cat_id=34, cat_id=6, sub_cat_name="Verbal Assault"),
        SubCategory(sub_cat_id=35, cat_id=6, sub_cat_name="Sexual Harassment"),
        SubCategory(sub_cat_id=36, cat_id=6, sub_cat_name="Stabbing"),
        SubCategory(sub_cat_id=37, cat_id=6, sub_cat_name="Police On Scene"),

        # Hazard
        SubCategory(sub_cat_id=38, cat_id=7, sub_cat_name="Gas Leak"),
        SubCategory(sub_cat_id=39, cat_id=7, sub_cat_name="Structural/Building Hazard"),
        SubCategory(sub_cat_id=40, cat_id=7, sub_cat_name="Dangerous Park"),
        SubCategory(sub_cat_id=41, cat_id=7, sub_cat_name="Dangerous Footpath"),

        # Weapon sighting
        SubCategory(sub_cat_id=42, cat_id=9, sub_cat_name="Person with Knife"),
        SubCategory(sub_cat_id=43, cat_id=9, sub_cat_name="Person with Gun"),
        SubCategory(sub_cat_id=44, cat_id=9, sub_cat_name="Person with any Dangerous Object"),

        # SubCategory(sub_cat_name="Burglary - Theft", cat_id=1),
        # SubCategory(sub_cat_name="Burglary - Mugging", cat_id=1),
        # SubCategory(sub_cat_name="Anti-Social Behaviour - Street", cat_id=2),
        # SubCategory(sub_cat_name="Anti-Social Behaviour - Park", cat_id=2),
        # SubCategory(sub_cat_name="Assault - Physical", cat_id=3),
        # SubCategory(sub_cat_name="Assault - Verbal", cat_id=3),
    ]

    seed_template(sub_categories)
    print("Sub categories seeded")


def seed_pins():
    print("Seeding pins")
    pins = [
        # === INFORMATION - Event (cat_id=1) ===
        Pin(cat_id=1, sub_cat_id=1, user_id=1, pin_title="Freshers Fair - Guildhall Square",
            pin_description="Annual freshers fair with stalls and freebies",
            pin_latitude=50.7981, pin_longitude=-1.0927,
            pin_isactive=True, pin_expire_at="2026-05-20 18:00:00"),
        Pin(cat_id=1, sub_cat_id=3, user_id=3, pin_title="5-a-side Football - Southsea Common",
            pin_description="Open football session on the common",
            pin_latitude=50.7891, pin_longitude=-1.0889,
            pin_isactive=True, pin_expire_at="2026-05-15 20:00:00"),
        Pin(cat_id=1, sub_cat_id=2, user_id=5, pin_title="Student Night - Pryzm",
            pin_description="Student night with discounted entry before 11pm",
            pin_latitude=50.7960, pin_longitude=-1.0930,
            pin_isactive=True, pin_expire_at="2026-04-25 03:00:00"),
        # expired
        Pin(cat_id=1, sub_cat_id=4, user_id=8, pin_title="Store Discount - Cascades",
            pin_description="Student discount weekend at various Cascades stores",
            pin_latitude=50.8060, pin_longitude=-1.0775,
            pin_isactive=False, pin_expire_at="2025-12-10 20:00:00"),
        Pin(cat_id=1, sub_cat_id=1, user_id=6, pin_title="Campus Open Day",
            pin_description="University open day for prospective students",
            pin_latitude=50.7975, pin_longitude=-1.0998,
            pin_isactive=False, pin_expire_at="2026-01-15 17:00:00"),

        # === INFORMATION - Free Items (cat_id=11) ===
        Pin(cat_id=11, sub_cat_id=5, user_id=2, pin_title="Free Pizza - Student Union",
            pin_description="Leftover pizza from society event, come quick!",
            pin_latitude=50.7975, pin_longitude=-1.0998,
            pin_isactive=True, pin_expire_at="2026-05-01 14:00:00"),
        Pin(cat_id=11, sub_cat_id=7, user_id=6, pin_title="Free Merch - Library Entrance",
            pin_description="University branded tote bags and stickers being given away",
            pin_latitude=50.7970, pin_longitude=-1.0992,
            pin_isactive=True, pin_expire_at="2026-04-28 16:00:00"),
        Pin(cat_id=11, sub_cat_id=6, user_id=9, pin_title="Free Pens - Freshers Week Stall",
            pin_description="Society stall handing out branded pens near the main entrance",
            pin_latitude=50.7978, pin_longitude=-1.0985,
            pin_isactive=True, pin_expire_at="2026-05-10 13:00:00"),
        # expired
        Pin(cat_id=11, sub_cat_id=5, user_id=3, pin_title="Free Sandwiches - SU Bar",
            pin_description="Leftover catering from an event",
            pin_latitude=50.7973, pin_longitude=-1.0995,
            pin_isactive=False, pin_expire_at="2025-11-22 15:00:00"),

        # === WARNING - Theft (cat_id=2) ===
        Pin(cat_id=2, sub_cat_id=11, user_id=1, pin_title="Bike Theft - Elm Grove",
            pin_description="Two bikes stolen overnight from the rack outside Lidl",
            pin_latitude=50.8190, pin_longitude=-1.0600,
            pin_isactive=True, pin_expire_at="2026-05-10 12:00:00"),
        Pin(cat_id=2, sub_cat_id=10, user_id=2, pin_title="Pickpocketing - Commercial Road",
            pin_description="Multiple reports of pickpocketing near the shopping centre entrance",
            pin_latitude=50.7964, pin_longitude=-1.0887,
            pin_isactive=True, pin_expire_at="2026-04-30 18:00:00"),
        Pin(cat_id=2, sub_cat_id=8, user_id=4, pin_title="Mugging - Guildhall Walk",
            pin_description="Student mugged late at night near the nightclub strip",
            pin_latitude=50.7988, pin_longitude=-1.0921,
            pin_isactive=True, pin_expire_at="2026-05-07 23:00:00"),
        Pin(cat_id=2, sub_cat_id=12, user_id=7, pin_title="Vehicle Break-in - Palmerston Road",
            pin_description="Several cars broken into overnight, avoid leaving valuables",
            pin_latitude=50.8072, pin_longitude=-1.0640,
            pin_isactive=True, pin_expire_at="2026-05-03 09:00:00"),
        # expired
        Pin(cat_id=2, sub_cat_id=9, user_id=5, pin_title="Bag Snatch - Southsea Seafront",
            pin_description="Bag snatched near the pier, suspect fled on bicycle",
            pin_latitude=50.7833, pin_longitude=-1.0875,
            pin_isactive=False, pin_expire_at="2026-01-05 21:00:00"),
        Pin(cat_id=2, sub_cat_id=11, user_id=10, pin_title="Bike Theft - Gunwharf Quays",
            pin_description="Bike lock cut, bike stolen from outdoor rack",
            pin_latitude=50.7976, pin_longitude=-1.1085,
            pin_isactive=False, pin_expire_at="2025-12-28 10:00:00"),

        # === WARNING - Anti-Social Behaviour (cat_id=3) ===
        Pin(cat_id=3, sub_cat_id=13, user_id=3, pin_title="Loud Groups - Southsea Common",
            pin_description="Large groups being disruptive near the bandstand late evening",
            pin_latitude=50.7915, pin_longitude=-1.0889,
            pin_isactive=True, pin_expire_at="2026-05-12 02:00:00"),
        Pin(cat_id=3, sub_cat_id=14, user_id=1, pin_title="Vandalism - Fratton Road",
            pin_description="Bus shelter windows smashed, glass on pavement",
            pin_latitude=50.8055, pin_longitude=-1.0712,
            pin_isactive=True, pin_expire_at="2026-04-27 10:00:00"),
        Pin(cat_id=3, sub_cat_id=16, user_id=5, pin_title="Harassment - Gunwharf Quays",
            pin_description="Groups of individuals harassing shoppers near the waterfront",
            pin_latitude=50.7976, pin_longitude=-1.1085,
            pin_isactive=True, pin_expire_at="2026-05-08 22:30:00"),
        Pin(cat_id=3, sub_cat_id=15, user_id=9, pin_title="Trespassing - Ravelin Park",
            pin_description="Individuals climbing fences and trespassing after hours",
            pin_latitude=50.7972, pin_longitude=-1.0941,
            pin_isactive=True, pin_expire_at="2026-05-01 23:59:00"),
        # expired
        Pin(cat_id=3, sub_cat_id=13, user_id=2, pin_title="Loud Groups - Old Portsmouth",
            pin_description="Noisy groups near the cathedral causing disturbance",
            pin_latitude=50.7989, pin_longitude=-1.1066,
            pin_isactive=False, pin_expire_at="2026-02-14 03:00:00"),

        # === WARNING - Suspicious Activity (cat_id=4) ===
        Pin(cat_id=4, sub_cat_id=17, user_id=2, pin_title="Suspicious Person - Victoria Park",
            pin_description="Individual loitering near the park gates for several hours",
            pin_latitude=50.8110, pin_longitude=-1.0905,
            pin_isactive=True, pin_expire_at="2026-05-09 20:00:00"),
        Pin(cat_id=4, sub_cat_id=18, user_id=6, pin_title="Suspicious Vehicle - Elm Grove",
            pin_description="Unmarked van parked for 3+ days with no movement",
            pin_latitude=50.8185, pin_longitude=-1.0608,
            pin_isactive=True, pin_expire_at="2026-05-06 08:00:00"),
        Pin(cat_id=4, sub_cat_id=19, user_id=4, pin_title="Suspicious Group - Cascades Car Park",
            pin_description="Group of individuals acting suspiciously in the multi-storey car park",
            pin_latitude=50.8058, pin_longitude=-1.0768,
            pin_isactive=True, pin_expire_at="2026-04-29 22:00:00"),
        # expired
        Pin(cat_id=4, sub_cat_id=17, user_id=8, pin_title="Suspicious Person - Southsea Seafront",
            pin_description="Individual approaching lone walkers late at night",
            pin_latitude=50.7840, pin_longitude=-1.0860,
            pin_isactive=False, pin_expire_at="2025-10-31 01:00:00"),

        # === WARNING - Facility & Safety Hazard (cat_id=5) ===
        Pin(cat_id=5, sub_cat_id=20, user_id=3, pin_title="Broken Streetlight - Palmerston Road",
            pin_description="Streetlight out, very dark stretch of road at night",
            pin_latitude=50.8079, pin_longitude=-1.0635,
            pin_isactive=True, pin_expire_at="2026-05-14 00:00:00"),
        Pin(cat_id=5, sub_cat_id=23, user_id=7, pin_title="Slippery Path - Old Portsmouth",
            pin_description="Cobblestones extremely slippery after rain near the cathedral",
            pin_latitude=50.7989, pin_longitude=-1.1066,
            pin_isactive=True, pin_expire_at="2026-04-26 15:00:00"),
        Pin(cat_id=5, sub_cat_id=21, user_id=4, pin_title="Broken Crossing Light - Winston Churchill Ave",
            pin_description="Pedestrian crossing light stuck on red, use alternative crossing",
            pin_latitude=50.8002, pin_longitude=-1.0871,
            pin_isactive=True, pin_expire_at="2026-05-11 18:00:00"),
        Pin(cat_id=5, sub_cat_id=22, user_id=10, pin_title="Lift Out of Service - Cascades Car Park",
            pin_description="Main lift broken, stairs only. Difficult for wheelchair users",
            pin_latitude=50.8060, pin_longitude=-1.0773,
            pin_isactive=True, pin_expire_at="2026-05-02 09:00:00"),
        # expired
        Pin(cat_id=5, sub_cat_id=20, user_id=1, pin_title="Broken Streetlight - Fratton Road",
            pin_description="Dark stretch near the junction, reported to council",
            pin_latitude=50.8052, pin_longitude=-1.0718,
            pin_isactive=False, pin_expire_at="2026-01-30 00:00:00"),

        # === WARNING - Construction (cat_id=10) ===
        Pin(cat_id=10, sub_cat_id=25, user_id=1, pin_title="Road Closed - Museum Road",
            pin_description="Roadworks causing full closure, use alternative routes",
            pin_latitude=50.7998, pin_longitude=-1.0950,
            pin_isactive=True, pin_expire_at="2026-05-20 17:00:00"),
        Pin(cat_id=10, sub_cat_id=24, user_id=8, pin_title="Footpath Closed - Southsea Seafront",
            pin_description="Path closed due to sea defence works, diversion in place",
            pin_latitude=50.7833, pin_longitude=-1.0875,
            pin_isactive=True, pin_expire_at="2026-05-18 12:00:00"),
        Pin(cat_id=10, sub_cat_id=27, user_id=5, pin_title="Bike Lane Blocked - Commercial Road",
            pin_description="Bike lane coned off due to utility works",
            pin_latitude=50.7960, pin_longitude=-1.0895,
            pin_isactive=True, pin_expire_at="2026-04-30 17:00:00"),
        # expired
        Pin(cat_id=10, sub_cat_id=26, user_id=3, pin_title="Pedestrian Crossing Closed - London Road",
            pin_description="Crossing closed for resurfacing, temporary crossing nearby",
            pin_latitude=50.8100, pin_longitude=-1.0750,
            pin_isactive=False, pin_expire_at="2025-11-15 18:00:00"),

        # === WARNING - Transportation Disruption (cat_id=12) ===
        Pin(cat_id=12, sub_cat_id=29, user_id=2, pin_title="University Bus Diverted - Ravelin Park",
            pin_description="U1 bus diverted due to road closure, check for updated stops",
            pin_latitude=50.7972, pin_longitude=-1.0941,
            pin_isactive=True, pin_expire_at="2026-05-05 20:00:00"),
        Pin(cat_id=12, sub_cat_id=31, user_id=9, pin_title="Bus Service Disrupted - Commercial Road",
            pin_description="First Bus services 1 and 2 delayed due to traffic incident",
            pin_latitude=50.7960, pin_longitude=-1.0900,
            pin_isactive=True, pin_expire_at="2026-04-28 19:00:00"),
        Pin(cat_id=12, sub_cat_id=32, user_id=6, pin_title="Portsmouth Harbour Station Disruption",
            pin_description="Delays on South Western Railway services, check National Rail for updates",
            pin_latitude=50.7981, pin_longitude=-1.1072,
            pin_isactive=True, pin_expire_at="2026-05-13 21:00:00"),
        # expired
        Pin(cat_id=12, sub_cat_id=28, user_id=4, pin_title="University Bus Stop Closed - Guildhall",
            pin_description="Stop temporarily closed due to roadworks",
            pin_latitude=50.7982, pin_longitude=-1.0922,
            pin_isactive=False, pin_expire_at="2026-02-01 17:00:00"),

        # === DANGER - Assault (cat_id=6) ===
        Pin(cat_id=6, sub_cat_id=33, user_id=4, pin_title="Physical Assault - Fratton Park Area",
            pin_description="Victim attacked after match, police called, avoid area",
            pin_latitude=50.8072, pin_longitude=-1.0628,
            pin_isactive=True, pin_expire_at="2026-05-08 21:00:00"),
        Pin(cat_id=6, sub_cat_id=35, user_id=3, pin_title="Sexual Harassment - Guildhall Walk",
            pin_description="Incident reported outside venue, police aware",
            pin_latitude=50.7985, pin_longitude=-1.0915,
            pin_isactive=True, pin_expire_at="2026-04-27 02:30:00"),
        Pin(cat_id=6, sub_cat_id=36, user_id=5, pin_title="Stabbing - Mile End Road",
            pin_description="Serious incident reported, police on scene, avoid area",
            pin_latitude=50.8225, pin_longitude=-1.0612,
            pin_isactive=True, pin_expire_at="2026-05-04 23:00:00"),
        Pin(cat_id=6, sub_cat_id=37, user_id=7, pin_title="Police on Scene - Copnor Road",
            pin_description="Multiple police units present, road partially blocked",
            pin_latitude=50.8420, pin_longitude=-1.0380,
            pin_isactive=True, pin_expire_at="2026-05-02 18:00:00"),
        # expired
        Pin(cat_id=6, sub_cat_id=34, user_id=2, pin_title="Verbal Assault - Commercial Road",
            pin_description="Aggressive individual shouting and threatening passersby",
            pin_latitude=50.7962, pin_longitude=-1.0882,
            pin_isactive=False, pin_expire_at="2026-01-20 23:00:00"),
        Pin(cat_id=6, sub_cat_id=33, user_id=9, pin_title="Assault - Southsea Common",
            pin_description="Fight broke out near the skate park",
            pin_latitude=50.7920, pin_longitude=-1.0878,
            pin_isactive=False, pin_expire_at="2025-12-05 01:00:00"),

        # === DANGER - Hazard (cat_id=7) ===
        Pin(cat_id=7, sub_cat_id=38, user_id=6, pin_title="Gas Leak - Copnor Road",
            pin_description="Gas engineers on site, road cordoned off, do not approach",
            pin_latitude=50.8420, pin_longitude=-1.0380,
            pin_isactive=True, pin_expire_at="2026-05-09 16:00:00"),
        Pin(cat_id=7, sub_cat_id=41, user_id=1, pin_title="Dangerous Footpath - Hilsea",
            pin_description="Path collapsed near lido, serious fall risk",
            pin_latitude=50.8490, pin_longitude=-1.0680,
            pin_isactive=True, pin_expire_at="2026-05-15 00:00:00"),
        Pin(cat_id=7, sub_cat_id=39, user_id=10, pin_title="Structural Hazard - Fratton",
            pin_description="Part of a wall has collapsed onto the pavement, area taped off",
            pin_latitude=50.8068, pin_longitude=-1.0700,
            pin_isactive=True, pin_expire_at="2026-04-29 12:00:00"),
        # expired
        Pin(cat_id=7, sub_cat_id=40, user_id=5, pin_title="Dangerous Park - Victoria Park",
            pin_description="Broken glass reported on the grass near the playground",
            pin_latitude=50.8112, pin_longitude=-1.0910,
            pin_isactive=False, pin_expire_at="2026-02-10 10:00:00"),

        # === DANGER - Weapon Sighting (cat_id=9) ===
        Pin(cat_id=9, sub_cat_id=42, user_id=2, pin_title="Knife Sighting - Cascades Shopping Centre",
            pin_description="Individual seen with knife near food court, police called",
            pin_latitude=50.8060, pin_longitude=-1.0770,
            pin_isactive=True, pin_expire_at="2026-05-07 17:00:00"),
        Pin(cat_id=9, sub_cat_id=44, user_id=7, pin_title="Dangerous Object - Southsea Seafront",
            pin_description="Person brandishing object near the pier, avoid area",
            pin_latitude=50.7840, pin_longitude=-1.0860,
            pin_isactive=True, pin_expire_at="2026-04-26 21:00:00"),
        Pin(cat_id=9, sub_cat_id=43, user_id=3, pin_title="Gun Sighting - Fratton Road",
            pin_description="Witness reported seeing a firearm, armed police en route",
            pin_latitude=50.8058, pin_longitude=-1.0725,
            pin_isactive=True, pin_expire_at="2026-05-03 22:30:00"),
        # expired
        Pin(cat_id=9, sub_cat_id=42, user_id=8, pin_title="Knife Sighting - Guildhall Walk",
            pin_description="Individual with knife seen near nightclub, dispersed by security",
            pin_latitude=50.7990, pin_longitude=-1.0918,
            pin_isactive=False, pin_expire_at="2026-01-11 03:00:00"),
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


def seed_user_relationships():
    print("Seeding user relationships")

    user_relationships = [
        UserRelationship(user_id=1, target_user_id=2, user_rel_status=UserRelationshipType.BLOCKED),
        UserRelationship(user_id=1, target_user_id=3, user_rel_status=UserRelationshipType.REJECTED),
        UserRelationship(user_id=2, target_user_id=3, user_rel_status=UserRelationshipType.ACCEPTED),
        UserRelationship(user_id=2, target_user_id=4, user_rel_status=UserRelationshipType.BLOCKED),
        UserRelationship(user_id=3, target_user_id=4, user_rel_status=UserRelationshipType.PENDING),
    ]
    seed_template(user_relationships)

    print("User relationships seeded")



def seed_template(data_to_seed):
    db = SessionLocal()
    db.add_all(data_to_seed)
    db.commit()
    db.close()


def seed_all():
    print("Start seeding")
    seed_users()
    seed_user_reports()
    seed_admins()
    seed_user_bans()
    seed_category_levels()
    seed_categories()
    seed_sub_categories()
    seed_pins()
    seed_pin_reactions()
    seed_pin_reports()
    seed_user_relationships()
    print("Finished seeding")


if __name__ == '__main__':
    seed_all()
