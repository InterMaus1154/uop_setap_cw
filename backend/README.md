# Git setup locally
1. Clone this repository - go where you want to clone it (it will create a folder with the repo name) `git clone https://github.com/InterMaus1154/uop_setap_cw.git`
2. If you are working on a new feature, do not work directly in `master`, create a new branch `git branch <branch_name>` then `git checkout <branch_name>`
3. Make sure you commit BEFORE switching to another branch, otherwise good luck
4. You can push that local branch into github (recommended) by `git push`. Follow the commands prompted to you.
5. You can merge into `master` by switching to it first `git checkout master`, then `git merge <your_branch>`. Please do not merge broken features into it.
6. If any doubt, ask in the groupchat before messing up the whole repo on github.
7. Use `git status` to check which branch you are on and which stage
8. 

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