# Backend
We are using FastAPI with Python for our backend rest api. We are creating an API for our frontend application. We will communicate with this API to get data and send data.
## How to install
1. Go into the backend folder and open cmd
2. It is easier if we use a virtual environment.
3. Type in order:
4. `python -m venv .venv`
5. If you open the backend folder directly in vscode, it should automatically detect the virtual environment (you see a .venv in front of the folder in terminal)
6. If not, then to activate it: .venv\Scripts\activate in cmd, or in powershell .venc\Scripts\Activate.ps1
7. Install dependencies: `pip install -r requirements.txt`
8. After it finished, you can run the app `uvicorn main:app --reload --port=8001`.