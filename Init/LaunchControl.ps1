<#
___________________________________________
__ Nom : 	 	LaunchControl.
__ Autheur :	MMI
__ Version :	6.6.6.6 (v1.0)
__ Date :		20/11/2026
__ Update :		.
___________________________________________
#>

# Configuration de la fenêtre
$host.UI.RawUI.WindowTitle = "BeneLauncher.exe"
Clear-Host

# Variables générales
$NAME = "BeneLauncher"
$BUILD = "v1.0"
$SOUND = "$PSScriptRoot\..\Content\BeneWelcome.mp3"


# Bannière
Write-Host @"

   -=-
(\  _  /)
( \( )/ )
(       )
 `>   <'
 /     \  Benedictus
 `-._.-'



"@

function Addios {
$SOUND = "$PSScriptRoot\..\Content\Monkey.mp3"; $global:player.Open($SOUND); $global:player.Play()
Write-Host @"



 Action annulée sale mécréant.
 Chiffe molle !

   toi:
           .---.
       .-./ _=_ \.-.
      {  (,(oYo),) }}
      {{ ^|   "   ^|}}
      { { \(---)/  }}
      {{  }'-=-'{ } }
      { { }._:_.{  }}
      {{  } -:- { } }
      {_{ }`===`{  _}
     ((((\)     (/))))

"@
Start-Sleep -Seconds 5
if ($global:player) { $global:player.Stop(); $global:player.Close() }   # Stopper la lecture
Stop-Process -Id $PID -Force
}

# Bande originale du Bene-Launcher
if (-not $global:player) { Add-Type -AssemblyName PresentationCore; $global:player = New-Object System.Windows.Media.MediaPlayer }; $global:player.Open($SOUND); $global:player.Play()

# Presentation divine
$texte = "Bonjour, bienvenue !"
$alea  = [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&@*+=?<>'
$rnd   = New-Object Random
[Console]::CursorVisible = $false

try {
    for ($fixe = 0; $fixe -le $texte.Length; $fixe++) {
        for ($f = 0; $f -lt 5; $f++) {
            [Console]::SetCursorPosition(0, [Console]::CursorTop)
            Write-Host $texte.Substring(0, $fixe) -NoNewline -ForegroundColor White
            $reste = -join ($texte.Substring($fixe).ToCharArray() | ForEach-Object {
                if ($_ -eq ' ') { ' ' } else { $alea[$rnd.Next($alea.Length)] }
            })
            Write-Host $reste -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 15
        }
    }
}
finally {
    [Console]::CursorVisible = $true
    Write-Host ""
}
Start-Sleep 1

function Menu {
Write-Host @"



 ♥        ♥        ♥        ♥        ♥        ♥        ♥        ♥        ♥

    ___       ____  _____ _   _ _____ ____  ___ ____ _____ _   _ ____        ___
   (___)     | __ )| ____| \ | | ____|  _ \|_ _/ ___|_   _| | | / ___|      (___)
   (o.o)     |  _ \|  _| |  \| |  _| | | | || | |     | | | | | \___ \      (o.o)
 /\_)|(_/\   | |_) | |___| |\  | |___| |_| || | |___  | | | |_| |___) |   /\_)|(_/\
/_/ /_\ \_\  |____/|_____|_| \_|_____|____/|___\____| |_|  \___/|____/   /_/ /_\ \_\

            ♥ ───────────── ✧  Sois bénit et choisis  ✧ ───────────── ♥

        +--------------------------------------------------------------+
        |  [1] ♥ Benedictus    -   Le Saint-Editeur de Bénédictions    |
        |                                                              |
        |  [2] ✧ BeneQuizz     -   Le Quizz des saints d'esprit        |
        |  [3] ♔ BeneRoulette  -   La roulette de l'infortune (wip)   |
        |  [4] ♪ BeneHero       -   Les saints réflexes (wip)          |
        |                                                              |
        |  [0] ☼ Quitter       -   Parce que tu ne vaux rien           |
        +--------------------------------------------------------------+

   Votre choix :
"@
    $Go = Read-Host
    switch ($Go) {
        '0' { Addios }
        '1' { $Execute = "powershell.exe"; $Arg = '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSScriptRoot\..\Main\Benedictus.ps1`""; Send }
        '2' { BeneQUizz }
        # TODO: EXPLOITER LE SEND
        '3' { $Execute = "powershell.exe"; $Arg = '-WindowStyle', 'Hidden', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSScriptRoot\..\Run\POC_BeneRoulette.ps1`""; Send }
        '4' { $Execute = "powershell.exe"; $Arg = '-WindowStyle', 'Hidden', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSScriptRoot\..\Run\POC_BeneHero.ps1`""; Send }
        default {
            Addios
        }
    }
}

function BeneQUizz {
    $SONG = "$PSScriptRoot\..\Content\Wow.mp3"; $global:player.Open($SONG); $global:player.Play()
Write-Host @"

 ♥     ♥     ♥     ♥     ♥     ♥     ♥     ♥     ♥     ♥

 ____                       ___        _
| __ )   ___  _ __    ___  / _ \  _   _(_) ____ ____
|  _ \  / _ \| '_ \  / _ \| | | || | | || ||_  /|_  /
| |_) ||  __/| | | ||  __/| |_| || |_| || | / /  / /
|____/  \___||_| |_| \___| \__\_\ \__,_||_|/___|/___|

        ♥ ─── ✧  Choisis ton niveau  ✧ ─── ♥

        +--------------------------------------+
        |  [1] ♥ Fun      - Pour le plaisir    |
        |  [2] ✧ Casual   - Tranquille         |
        |  [3] ♠ Deadly   - Une erreur = bye   |
        |                                      |
        |  [0] ☼ Menu     - Retour             |
        +--------------------------------------+

   Votre choix :
"@
$Mode = Read-Host
switch ($Mode) {
    '1' { $Difficulty = 'Fun'; $SONG = "$PSScriptRoot\..\Content\Tuturu.mp3" }
    '2' { $Difficulty = 'Casual'; $SONG = "$PSScriptRoot\..\Content\Meow.mp3" }
    '3' { $Difficulty = 'Deathmatch'; $SONG = "$PSScriptRoot\..\Content\UndertakerBell.mp3" }
    '0' { Menu }
    default { $Difficulty = 'Fun' }
}
    $global:player.Open($SONG); $global:player.Play()
    Write-Host "Let's a go ! Mode: `"$Difficulty`""
    Start-Sleep 3

    $Script = "BeneQuizz.ps1"
    $Action = "$PSScriptRoot\..\Run\$Script"
    $Execute = "powershell.exe"
    $Arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Action`" -Mode `"$Difficulty`""

    Send
}

function Send {
    # Start new
    Start-Process -FilePath $Execute -ArgumentList $Arg
    Write-Host "Lancement, veuillez patienter..."

    # Stop current
    if ($global:player) { $global:player.Stop(); $global:player.Close() }
    Stop-Process -Id $PID -Force
}

function Addios {

    if ($global:player) { $global:player.Stop(); $global:player.Close() }
    Stop-Process -Id $PID -Force    
}

# Lancement
Menu