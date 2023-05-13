@echo off
SETLOCAL

REM Define the function to remove Python Virtual Environment
:removeVenv
if defined VIRTUAL_ENV (
    echo Detected virtual environment. Attempting to deactivate.
    for %%A in ("%path:;=" "%") do (
        if not "%%~A"=="%VIRTUAL_ENV%\Scripts" (
            set "newpath=!newpath!;%%~A"
        )
    )
    set "path=%newpath:~1%"
    set "VIRTUAL_ENV="
    set "_OLD_VIRTUAL_PATH="
)
goto :eof

REM Define the function to find Python3.10 binary
:findPythonBin
for %%B in (python3.10.exe python310.exe python3.exe python.exe) do (
    for /f "tokens=2 delims= " %%C in ('%%B --version 2^>^&1') do (
        for /f "tokens=1,2 delims=." %%D in ("%%C") do (
            if "%%D"=="3" if "%%E"=="10" (
                set "pythonBin=%%B"
                goto :eof
            )
        )
    )
)
echo No suitable Python binary found. Checked binaries: python3.10.exe, python310.exe, python3.exe, python.exe
exit /b 1

REM Detect and deactivate a Python virtual environment if it's activated
call :removeVenv

REM Find Python 3.10 binary
call :findPythonBin

if not defined pythonBin (
    echo Python 3.10 is not found on this system.
    exit /b 1
)

echo Selected Python binary: %pythonBin%

REM Ensure Torch is in PATH
set PATH=%PATH%;%~dp0venv\Lib\site-packages\torch\lib

REM Read arguments from gui_parameters.txt if it exists
if exist gui_parameters.txt (
    for /f "usebackq delims=" %%A in ("gui_parameters.txt") do (
        set "args=!args! %%A"
    )
)

REM Determine if --update or --repair or -u or -r is in the arguments
echo.%args%|findstr /C:"--update" /C:"--repair" /C:"-u" /C:"-r" >nul
if errorlevel 1 (
    REM Run the launcher script with the selected Python binary and --no-setup
    if exist launcher.py (
        %pythonBin% launcher.py --no-setup %args%
    ) else (
        echo Sorry, launcher.py not found.
    )
) else (
    REM Run the launcher script with the selected Python binary
    if exist launcher.py (
        %pythonBin% launcher.py %args%
    ) else (
        echo Sorry, launcher.py not found.
    )
)

ENDLOCAL