# Installation Guide

This guide walks you through setting up the CampusConnect project locally for development. Follow the steps from top to bottom and you should have the full stack running.

## Prerequisites

Before you begin, make sure you have the following installed:

| Tool | Version | Download |
|------|---------|----------|
| Git | Any recent version | [git-scm.com](https://git-scm.com/) |
| Python | 3.12 or higher | [python.org](https://www.python.org/downloads/) |
| PostgreSQL | 14 or higher | [postgresql.org](https://www.postgresql.org/download/) |
| Flutter SDK | 3.38 or higher | [flutter.dev](https://docs.flutter.dev/get-started/install) |

```{note}
You can verify your installed versions with:
`python3 --version` (or `python --version` on Windows),
`psql --version`,
`flutter --version`
```

## Clone the Repository

```bash
git clone https://github.com/InterMaus1154/uop_setap_cw.git
cd uop_setap_cw
```

## Backend Setup

The backend is a Python FastAPI application located in the `backend/` directory.

### 1. Create a Virtual Environment

Navigate to the backend directory and create a Python virtual environment:

```bash
cd backend
```

````{tab-set}

```{tab-item} macOS / Linux
    python3 -m venv venv
    source venv/bin/activate
```

```{tab-item} Windows (CMD)
    python -m venv venv
    venv\Scripts\activate
```

```{tab-item} Windows (PowerShell)
    python -m venv venv
    venv\Scripts\Activate.ps1
```

````

Once activated, you should see `(venv)` at the start of your terminal prompt.

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Copy the example environment file and fill in your database credentials:

````{tab-set}

```{tab-item} macOS / Linux
cp .env.example .env
```

```{tab-item} Windows (CMD / PowerShell)
copy .env.example .env
```

````

Open `.env` and set your PostgreSQL connection string:

```
DATABASE_URL=postgresql://your_user:your_password@localhost:5432/campus_connect
```

```{important}
Make sure your PostgreSQL server is running and the database `campus_connect` exists before proceeding. You can create it with:
`createdb campus_connect` or via psql: `CREATE DATABASE campus_connect;`
```

### 4. Set Up the Database

The project includes migration and seeding scripts to set up tables and populate test data.

The easiest approach is to run the combined migrate and seed script:

```bash
python database/ms.py
```

```{note}
On macOS/Linux, you may need to use `python3` instead of `python` for all database commands.
```

This will:
- Drop all existing tables (fresh start)
- Create all tables from the SQLAlchemy models
- Seed the database with test users, categories, pins, and other sample data

```{warning}
`ms.py` drops all existing data. Only use this for initial setup or when you need a clean reset.
```

If you need to run them separately:

```bash
# Drop and recreate tables only
python database/migrate.py

# Seed data only (run on an empty database to avoid primary key conflicts)
python database/seed.py
```

### 5. Start the Backend Server

```bash
uvicorn main:app --reload --port=8000
```

The API will be available at [http://localhost:8000](http://localhost:8000).

You can view the auto-generated API documentation at [http://localhost:8000/docs](http://localhost:8000/docs).

## Frontend Setup

The frontend is a Flutter application located in the `frontend/` directory.

### 1. Install Dependencies

From the project root directory:

```bash
cd frontend
flutter pub get
```

### 2. Run the Application

```bash
flutter run -d chrome
```

Other supported targets:

```bash
# macOS desktop (macOS only)
flutter run -d macos

# Windows desktop (Windows only)
flutter run -d windows
```

```{note}
The frontend connects to the backend at `http://localhost:8000`. This works out of the box for Chrome and desktop targets. If you are running on an Android emulator, the backend URL would need to be changed to `http://10.0.2.2:8000` in `lib/services/api_service.dart`.
```

### 3. Verify Everything Works

Once both the backend and frontend are running:

1. The app should load with a user selection screen
2. Select any test user to log in
3. The map should display centred on the University of Portsmouth campus
4. Seed data pins should be visible on the map

## Troubleshooting

### Backend won't start — database connection refused
Make sure PostgreSQL is running and the `DATABASE_URL` in your `.env` file is correct. Verify you can connect manually:
```bash
psql -h localhost -U your_user -d campus_connect
```

### `psycopg2` fails to install on Apple Silicon (M1/M2/M3)
If `pip install` fails on the `psycopg2-binary` package, install the PostgreSQL client library first:
```bash
brew install libpq
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
pip install -r requirements.txt
```

### CORS errors in the browser console
This means the backend is either not running or not reachable at `localhost:8000`. Start the backend server first, then refresh the frontend.

### Flutter version mismatch
The project requires Flutter 3.38+ and Dart SDK 3.10+. If you get SDK constraint errors:
```bash
flutter upgrade
flutter pub get
```

### Seed script throws primary key errors
The seed script expects an empty database. Run the full migrate and seed to reset:
```bash
python database/ms.py
```
