@echo off
rem taste-judge score [--domain flux^|studio] [--no-wall] <img>...  -> JSON (see taste_judge.py)
rem Lives in C:\Users\ejfox\farm\taste\ next to the CLIP venv; source ~/.dotfiles/computah/.
"%~dp0venv\Scripts\python.exe" "%~dp0taste_judge.py" %*
