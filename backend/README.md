# Backend
We are using FastAPI with Python for our backend rest api. We are creating an API for our frontend application. We will communicate with this API to get data and send data.
## How to install
1. Go into the backend folder and open cmd
2. It is easier if we use a virtual environment.
3. Type in order:
4. `python -m venv venv`
5. If you open the backend folder directly in vscode, it should automatically detect the virtual environment (you see a .venv in front of the folder in terminal)
6. If not, then to activate it: venv\Scripts\activate in cmd, or in powershell venv\Scripts\Activate.ps1
7. Install dependencies: `pip install -r requirements.txt`
8. After it finished, you can run the app `uvicorn main:app --reload --port=8000`.

## How to run migrations and seed
The goal of migrations and seeding is to have a basic state of the database we can always go back to with some dummy data for testing.
1. You can recreate the tables by running the `database/migrate.py` file from the terminal `python database/migrate.py` - THIS WILL DELETE ALL DATA
2. You can run the seeders separately by running `python database/seed.py` - it will throw an error if data already exists due to PK violations, so only run it in empty database.
3. Easiest is to run `python database/ms.py` that first runs the migrations, then the seed