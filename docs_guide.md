# ReadTheDocs Guide

## Where is it?

The documentation sits right here: [https://campusconnect.readthedocs.io/en/latest/](https://campusconnect.readthedocs.io/en/latest/)

Whenever you push changes to `master` branch on GitHub, it will rebuild the docs - do not need to do anything manually.

## What to use to write it?

We use Markdown - you may find this basic md syntax useful [https://www.markdownguide.org/basic-syntax/](https://www.markdownguide.org/basic-syntax/)

## How to live preview the documentation locally - like it would be on live page

(Do these steps once for initial setup)

1. Go to the `docs/` folder in your terminal
```bash
# from project root
cd docs
```
2. Type the following command creating a virtual environment (similarly to backend)
```bash
# make sure you are in the docs/ folder, not in root or other folder
python -m venv venv 
```
3. Activate the virtual environment from the terminal
```bash
venv\Scripts\Activate
```
4. Install the packages
```bash
# you should see a (venv) in your terminal now
pip install -r requirements.txt
```

To run the live preview:
```bash
sphinx-autobuild . /_build/html
```
It will run a live preview on `127.0.0.1:8000`. If you have port conflict, add the `--port` flag to the command. Example:
```bash
sphinx-autobuild . /_build/html --port=8001
```
Whenever you make changes to the documentation files, and save them, it will reload the preview.

**Note: you need to be in the virtual environment to run this command, do not forget**

Alternatively, you can preview individual markdown files using a VS Code markdown preview extension. However, readthedocs is using some extra styles, so they will not render correctly. For the best experience, and to get the feel how the documentation will look like on live, use the live preview as I described above. 

