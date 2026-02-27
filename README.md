SETaP coursework

## Setup to help you all get started, lets get full marks!

### Backend (Python FastAPI)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # then fill in your values
```

Run the server:
```bash
uvicorn main:app --reload
```
API runs at http://localhost:8000

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
```

Run the app:
```bash
flutter run
```

Run the flutter unit tests:
```bash
flutter test test/models/ test/providers/ test/services/
```

Run python unit tests in backend folder:
```bash
pytest -v
```

## Project Structure

```
backend/   - Python FastAPI server
frontend/  - Flutter application
```
