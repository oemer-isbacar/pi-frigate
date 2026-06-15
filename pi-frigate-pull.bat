@echo off

:: Gerät erkennen
if "%USERNAME%"=="IsbacarO" (
    set PROJEKTE=C:\Users\IsbacarO\Schule\FIS\Projekte
) else if "%USERNAME%"=="oemer" (
    set PROJEKTE=C:\Users\oemer\Documents\Schule\FIS\Projekte
) else if "%USERNAME%"=="oemer.isbacar" (
    set PROJEKTE=C:\Users\user\Documents\Schule\FIS\Projekte
) else (
    echo Unbekannter Computer ^(%USERNAME%^) - Abbruch!
    pause
    exit
)

echo.
echo === pi-frigate wird aktualisiert ===
cd /d "%PROJEKTE%\pi-frigate"
git pull gitea master

echo.
echo Fertig!
pause
