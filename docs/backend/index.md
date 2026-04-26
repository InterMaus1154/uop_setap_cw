# Backend Documentation

This document covers the CampusConnect backend — its structure and how the pieces fit together. It is aimed at developers working on or reviewing the backend codebase.

## Overview

The backend is a REST API built with [FastAPI](https://fastapi.tiangolo.com/) and [SQLAlchemy](https://www.sqlalchemy.org/), running on Python 3.12+. It stores data in a PostgreSQL database and is consumed by the CampusConnect Flutter frontend.

## Project Structure

```
backend/
├── main.py          # App entry point — routers, middleware, config
├── database/        # Database engine, migrations, and seed data
├── models/          # SQLAlchemy ORM models (one per database table)
├── schemas/         # Pydantic request/response schemas
├── routes/          # FastAPI routers (one file per resource)
├── middleware/      # Authentication
├── checkpins/       # Background task: auto-expire old pins
├── alembic/         # Database migration history
├── uploads/         # Uploaded pin images
└── tests/           # pytest tests
```

## Routers

Each resource has its own router file under `routes/`. All routers are registered in `main.py`.

| File | URL Prefix | Description |
|------|-----------|-------------|
| `routes/auth.py` | `/auth` | Login, logout, and invitation-code login |
| `routes/users.py` | `/users` | User profiles, search, and account management |
| `routes/pins.py` | `/pins` | Create, read, update, delete, react to, and report pins |
| `routes/categories.py` | `/categories` | Category, category level, and subcategory listings |
| `routes/friends.py` | `/friends` | Friend requests and relationship management |
| `routes/invitations.py` | `/invitation-codes` | Generate and list guest invitation codes |
| `routes/user_locations.py` | `/user-locations` | GPS location sharing between friends |
| `routes/user_locations.py` | `/location-permissions` | Per-friend location sharing permissions |

## Models

Models are Python classes that map to PostgreSQL tables. They are defined using SQLAlchemy and live in `models/`. See [models.md](models.md) for a full breakdown of every model and its fields.

## Authentication

Authentication is handled by two dependency functions in `middleware/auth.py`. Routes that require a logged-in user use `require_auth`. Routes that work with or without a login (e.g. viewing pins) use `optional_auth`. See the [API documentation](../api/index.md) for which endpoints require authentication.

## Database

The `database/` folder contains the SQLAlchemy setup and helper scripts:

| File | Description |
|------|-------------|
| `db.py` | Database connection and session setup |
| `migrate.py` | Drops and recreates all tables |
| `seed.py` | Inserts test data |
| `ms.py` | Runs migrate and seed together |

## Background Tasks

`checkpins/checkpinactivity.py` is a background task that runs while the server is live. It automatically marks pins as inactive once their expiry time has passed, so they no longer appear in the `GET /pins` response.

## Static Files

Pin images uploaded through `POST /pins` are saved to `uploads/pins/` and served publicly at `/uploads/pins/<filename>`.

## Running the Backend

From inside the `backend/` directory:

**Install dependencies**
```bash
pip install -r requirements.txt
```

**Configure environment variables** — copy `.env.example` to `.env` and fill in your values:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/campus_connect` |
| `BASE_URL` | Public URL of the backend (used to build image URLs) | `http://localhost:8000` |

**Set up the database** (drops existing data and seeds test data)
```bash
python database/ms.py
```

**Start the server**
```bash
uvicorn main:app --reload --port=8000
```

The API will be available at `http://localhost:8000` and the auto-generated docs at `http://localhost:8000/docs`.