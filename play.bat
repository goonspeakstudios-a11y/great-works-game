@echo off
rem Great Works launcher: gets the latest version from GitHub (main), imports any new
rem assets, then starts the game. Point your desktop shortcut at this file.
rem Set GODOT to use a different Godot; the default is the one in Desktop\Tools\godot.
setlocal
cd /d "%~dp0"
if "%GODOT%"=="" set "GODOT=%USERPROFILE%\Desktop\Tools\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%". Set GODOT to its path.
	pause
	exit /b 1
)

if not exist ".git" (
	echo Not a git checkout ^(for example a GitHub "Download ZIP"^): starting the files here.
	goto import
)
echo Updating from GitHub...
git fetch origin main
if errorlevel 1 (
	echo Could not reach GitHub; starting the version already here.
	goto import
)
git checkout main
if errorlevel 1 (
	echo Could not switch to main; you have local changes. Starting the version already here.
	goto import
)
git pull --ff-only origin main
if errorlevel 1 echo Could not update cleanly; you have local changes. Starting the version already here.

:import
echo Importing new assets ^(the first time takes a minute^)...
"%GODOT%" --headless --path . --import >nul 2>&1

start "" "%GODOT%" --path .
endlocal
