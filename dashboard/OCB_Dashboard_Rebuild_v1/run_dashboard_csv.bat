@echo off
setlocal
cd /d "%~dp0"
set OCB_DATA_SOURCE=csv
if not exist ".venv\Scripts\python.exe" (
  echo ERROR: Run run_dashboard_sql.bat once to create the virtual environment, or create .venv manually.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" -m streamlit run app.py --server.port 8502
endlocal
