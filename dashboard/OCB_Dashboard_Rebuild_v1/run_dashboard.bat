@echo off
cd /d "%~dp0"
set OCB_DATA_SOURCE=sql
set OCB_SQL_SERVER=.
set OCB_SQL_DATABASE=ocb_platform
set OCB_SQL_TRUSTED_CONNECTION=true
if not exist ".venv\Scripts\python.exe" (
  echo Creating the dashboard virtual environment...
  py -3.14 -m venv .venv
  if errorlevel 1 py -3 -m venv .venv
)
if not exist ".venv\Scripts\python.exe" (
  echo Could not create .venv. Install Python and try again.
  pause
  exit /b 1
)
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
echo Opening OCB dashboard at http://localhost:8502
.venv\Scripts\python.exe -m streamlit run app.py --server.port 8502
pause
