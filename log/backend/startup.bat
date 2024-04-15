@echo off
@setlocal enabledelayedexpansion
IF "%CURRENT%"=="" SET CURRENT=%~dp0
SET PYTHON_BASE_DIR=%CURRENT%
CD /d %PYTHON_BASE_DIR%
SET VENV_DIR=%PYTHON_BASE_DIR%\.venv
SET VENV_BAT=%VENV_DIR%\Scripts\activate
SET PYTHON_VER=3.11-64
SET PIP_VER=24.0
SET POETRY_VER=1.6.1


REM set variable for ColorText, CALL :ColorText %GREEN% "message"
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "DEL=%%a"
)
SET GREEN=0a
SET RED=0C
SET BLUE=09


:CLEAN_VENV
IF "%1" equ "clean" (
  CALL :ColorText %BLUE% "Clean venv."
  IF EXIST "%VENV_DIR%" RMDIR /S /Q "%VENV_DIR%"
  IF EXIST poetry.lock DEL poetry.lock
  SHIFT
)


:SETUP_PYTHON
IF NOT EXIST %VENV_DIR%\* (
  CALL :CHECK_SYSTEM_PYTHON
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
  CALL :CHECK_SYSTEM_PIP
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
  CALL :CHECK_SYSTEM_POETRY
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
  CALL :ACTIVATE_VENV
  CALL :CHECK_VENV_PIP
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
  CALL :CHECK_VENV_POETRY
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
  CALL :CHECK_SYNC
  IF NOT !ERRORLEVEL! equ 0 GOTO :END
)
cmd /k %VENV_BAT%
EXIT

:END
cmd /k
EXIT


:CHECK_SYSTEM_PYTHON
CALL :CHECK_BIN "Python" py %PYTHON_VER:-64=%
EXIT /b %ERRORLEVEL%


:CHECK_SYSTEM_PIP
CALL :CHECK_PYSCRIPT "pip" pip %PIP_VER% "pip install --upgrade pip"
EXIT /b %ERRORLEVEL%


:CHECK_SYSTEM_POETRY
CALL :CHECK_PYSCRIPT "poetry" poetry %POETRY_VER% "pip install poetry"
CALL :ColorText %BLUE% "Configuring poetry."
py -%PYTHON_VER% -m poetry config virtualenvs.in-project true
CALL :ColorText %GREEN% "  Done."
EXIT /b %ERRORLEVEL%


:CHECK_PYSCRIPT
CALL :ColorText %BLUE% "Checking System %~1 version..."
py -%PYTHON_VER% -m %2 --version | find /i "%3" > nul
IF %ERRORLEVEL% equ 0 (
  CALL :ColorText %GREEN% "  OK. %~1 is ready"
  EXIT /b 0
)
IF "%~4" equ "" (
  CALL :ColorText %RED% "  NG, Please install %~1 v%3"
  EXIT /b -1
) ELSE (
  CALL :ColorText %RED% "  NG, Now trying to install %~1 v%3"
  py -%PYTHON_VER% -m %~4
)
EXIT /b %ERRORLEVEL%


:CHECK_BIN
CALL :ColorText %BLUE% "Checking %~1 version..."
where %2 2> nul > nul
IF %ERRORLEVEL% equ 0 (
  IF "%2" equ "py" (
    py -%PYTHON_VER% --version | find /i "%3" > nul
  ) ELSE (
    %2 --version | find /i "%3" > nul
  )
  IF !ERRORLEVEL! equ 0 (
    CALL :ColorText %GREEN% "  OK. %~1 is ready"
    EXIT /b 0
  )
)
IF "%~4" equ "" (
  CALL :ColorText %RED% "  NG, Please install %~1 v%3"
  EXIT /b -1
) ELSE (
  CALL :ColorText %RED% "  NG, Now trying to install %~1 v%3"
  %~4
)
EXIT /b %ERRORLEVEL%


:ACTIVATE_VENV
IF NOT EXIST .venv (
  CALL :ColorText %BLUE% "Creating python venv."
  py -%PYTHON_VER% -m venv .venv
  CALL :ColorText %BLUE% "  Done."
)
CALL :ColorText %BLUE% "Activating Python venv."
CALL %VENV_BAT%
CALL :ColorText %GREEN% "Python venv is activated."
EXIT /b %ERRORLEVEL%


:CHECK_VENV_PIP
CALL :CHECK_BIN "pip" pip %PIP_VER% "python -m pip install --upgrade pip"
EXIT /b %ERRORLEVEL%


:CHECK_VENV_POETRY
CALL :CHECK_BIN "poetry" poetry %POETRY_VER% "pip install poetry==%POETRY_VER%"
EXIT /b %ERRORLEVEL%


:CHECK_SYNC
CALL :ColorText %BLUE% "Synchronizing venv library."
IF EXIST poetry.lock (
  poetry install
  IF NOT !ERRORLEVEL! equ 0 PAUSE
) ELSE (
  IF EXIST pyproject.toml (
    poetry install
    IF NOT !ERRORLEVEL! equ 0 PAUSE
  ) ELSE (
    poetry init
    CALL :ColorText %BLUE% "Install libraries for developing."
    poetry add --group dev pytest pytest-cov
    IF NOT !ERRORLEVEL! equ 0 PAUSE
  )
)
IF NOT %ERRORLEVEL% equ 0 (
  CALL :ColorText %RED% "  Sync has error!!"
) ELSE (
  CALL :ColorText %GREEN% "  Done."
)
EXIT /b %ERRORLEVEL%


:ColorText
echo off
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1
ECHO.
EXIT /b 0
