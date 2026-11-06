@echo off
setlocal
cd /d "%~dp0"

set "GH_USER=TheProfessionalYoupi"

rem --- Recupere l'ID numerique du compte pour construire l'email noreply ---
for /f %%i in ('powershell -NoProfile -Command "(Invoke-RestMethod https://api.github.com/users/%GH_USER%).id"') do set "GH_ID=%%i"
if not defined GH_ID (
    echo Impossible de recuperer l'ID GitHub. Verifie ta connexion.
    pause
    exit /b 1
)

rem --- Identite anonyme, uniquement pour CE depot (pas de --global) ---
git config user.name "%GH_USER%"
git config user.email "%GH_ID%+%GH_USER%@users.noreply.github.com"

echo.
echo Identite utilisee :
git config user.name
git config user.email
echo.

rem --- Etat du depot ---
git add -A
git diff --cached --quiet
if not errorlevel 1 (
    echo Aucun changement a commiter.
    pause
    exit /b 0
)
git status --short
echo.

rem --- Message de commit ---
set "MSG="
set /p "MSG=Message du commit (vide = Update) : "
if not defined MSG set "MSG=Update"

git commit -m "%MSG%"
if errorlevel 1 (
    echo Echec du commit.
    pause
    exit /b 1
)

git push origin HEAD
if errorlevel 1 (
    echo Echec du push.
    pause
    exit /b 1
)

echo.
echo Mise a jour terminee.
pause