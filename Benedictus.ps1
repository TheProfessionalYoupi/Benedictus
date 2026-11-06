<#
___________________________________________
__ Nom : 	 	Benedictus.
__ Autheur :	MMI
__ Version :	6.6.6.6 (v2.0)
__ Date :		04/11/2026
__ Update :		.
___________________________________________
#>

# Configuration de la fenêtre
$host.UI.RawUI.WindowTitle = "Benedictus.exe"
# $host.UI.RawUI.BackgroundColor = "DarkBlue"
Clear-Host

# Variables générales
$NAME = "Benedictus"
$BUILD = "v2.0"
$SONG = "$PSScriptRoot\Content\BenedictusSong.mp3"

# Bande originale du Saint-Editeur
if (-not $global:player) { Add-Type -AssemblyName PresentationCore; $global:player = New-Object System.Windows.Media.MediaPlayer }; $global:player.Open($SONG); $global:player.Play()

# Menu principal (Menu du jour)
function MenuDuJour {
Write-Host @"

          /^\                   /^\
        /     \     )   (     /     \
      /         \ )\(-+-)/( /         \
    /            )-/ 0:0 \-(            \
  /         ____ )--\~-~/--( ____        \
 (/)  +*****\/\/****(o:o)****\/\/****+  (\)
  / /)*              \-/             *(\ \
 (/   *                              *   \)
      *    EDITEUR DE BENEDICTION    *
      *                              *
      *           / $BUILD \           *
      +******************************+

 1. Creer un mantra
 2. Jouer un Requiem
 3. You are an idiot
 4. ___
 5. ___
 6. Ecran de la mort
 7. ___

 0. Exhorciser "Benedictus"
 9. Abandonner

"@
    $Go = Read-Host; if ([string]::IsNullOrWhiteSpace($Go)) { $Go = 1..9 | Get-Random }
    switch ($Go) {
        '0' { Delivrance }
        '1' { Mantra }
        '2' { Requiem }
        '3' { Idiot }
        '4' { Quizz }
        '6' { Blue }
        '9' { Abord }
        default {
            Error
        }
    }

}

# ===============
# Paramétrages
# ===============

function Mantra {
    $Benediction = "Mantra"

    Write-Host @"
    Choisissez un Mantra :
    1. Kinder Surprise
    2. Girls Chase, how to get pussy
    3. Chérie FM
    4. Nuclear Kitchen
    5. Cailloux
    6. Anti-rides
    (ou)
    Entrez la commande a executer (cmd) [ex: start www.orinox.com/fr] :
"@

    $Mantra = Read-Host "Entrez la commande a executer (cmd) [ex: start www.orinox.com/fr] :"
    if ([string]::IsNullOrWhiteSpace($Mantra)) {
        $Mantra = 1..6 | Get-Random
    }
    elseif ($Mantra -eq "1") {
        $Action = "start www.kinder.com/fr/fr/kinder-surprise"
    }
    elseif ($Mantra -eq "2") {
        $Action = "start www.girlschase.com"
    }
    elseif ($Mantra -eq "3") {
        $Action = "start www.cheriefm.fr"
    }
    elseif ($Mantra -eq "4") {
        $Action = "start www.bearingpoint.com/fr-fr/publications-evenements/blogs/energie/cuisine-nucleaire/"
    }
    elseif ($Mantra -eq "5") {
        $Action = "start www.formationlithotherapie.fr/"
    }
    elseif ($Mantra -eq "6") {
        $Action = "start www.amazon.fr/creme-anti-ride/s?k=creme+anti+ride"
    }
    else {
        $Action = $Mantra
    }

    $Execute = "cmd.exe"
    $Arg = "/c `"$Action`""
    Send
}

function Blue {
    $Benediction = "Ecran de la mort"

    Write-Host @"
    Choisissez une mort :
    1. Bleu fatal !
    2. Rouge mortel
"@
    $Col = Read-Host "Mort"; if ([string]::IsNullOrWhiteSpace($Col)) { $Col = 1..2 | Get-Random }
    if ($Col -eq "1") {
        $Script = "Blue.ps1"
    }
    elseif ($Col -eq "2") {
        $Script= "Red.ps1"
    }
    else {
        Error
    }
    
    $Action = "$PSScriptRoot\Run\$Script"
    $Execute = "powershell.exe"
    $Arg = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$Action`""
    Send
}

function Requiem {
    $Benediction = "Requiem"

    Write-Host @"
    Choisissez une bande originale :
    1. uwu <3
    2. Oooh Yeaah !
    3. Prrrout
    4. The Demon's Share
    5. Pika chuuu !
    6. I Like Move it
"@
    $Choix = Read-Host; if ([string]::IsNullOrWhiteSpace($Choix)) { $Choix = 1..6 | Get-Random }
    if ($Choix -eq "1") {
        $Script = "uwu.mp3"
    }
    elseif ($Choix -eq "2") {
        $Script= "OhYeahLong.mp3"
    }
    elseif ($Choix -eq "3") {
        $Script= "Prout.mp3"
    }
    elseif ($Choix -eq "4") {
        $Script= "Demon.mp3"
    }
    elseif ($Choix -eq "5") {
        $Script= "Pikachu.mp3"
    }
    elseif ($Choix -eq "6") {
        $Script= "LikeToMoveIt.mp3"
    }
    else {
        Error
    }
    $Action = "$PSScriptRoot\Run\InvisiblePlayer.ps1"
    $Execute = "powershell.exe"
    $Arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -NoExit -File `"$Action`" -Audio `"$Script`""
    Send
}

function Idiot {
    $Benediction = "You are an idiot!"
    $Script = "Idiot.ps1"

    $Action = "$PSScriptRoot\Run\$Script"
    $Execute = "powershell.exe"
    $Arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Action`""
    send
}

function Quizz {
    $Benediction = "Quizz"
    $Script = "Quizz.ps1"

    $Action = "$PSScriptRoot\Run\$Script"
    $Execute = "powershell.exe"
    $Arg = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$Action`""
    error
    # send
}

# ===============
# Contacter DIEU
# ===============

function Send {   
    Write-Host "Spécifier une date de démarrage ?"

    $now = Get-Date
    $fr  = [cultureinfo]'fr-FR'
    $p   = [datetime]::MinValue
    $inD = Read-Host "À quelle date ? [ex: 24/12/2077] ou [N]"
    $inH = Read-Host "À quelle heure ? [ex: 09:00] ou [N]"

    $day  = if ([datetime]::TryParseExact($inD, 'dd/MM/yyyy', $fr, 'None', [ref]$p) -and $p -ge $now.Date) { $p.Date } else { $now.Date }
    $time = if ([datetime]::TryParseExact($inH, 'HH:mm',      $fr, 'None', [ref]$p)) { $p.TimeOfDay } else { $now.TimeOfDay }
    $when = $day + $time
    # La date et heure ne peut être que minimum dans 2 minutes dans le futur
    if ($when -le $now.AddMinutes(1)) { $when = $now.AddMinutes(2) }

    $Interval = Read-Host "Entrez une répétition en minutes (/mo) [ex: 15] ou [N]: "
    if ($Interval -match '^\s*\d+\s*$' -and [int]$Interval.Trim() -gt 0) {
        $Interval = [int]$Interval.Trim()
    } else {
        $Interval = "Non"
    }

    Write-Host @"

    _____________________________________
    |   Bénédiction :       $Benediction
    |
    |   Action      :       $Action
    |   Répétition  :       $Interval
    |   Quand       :       $When
    ____________________________________

"@
    $Confirm = Read-Host "Souhaitez-vous envoyer cette bénédiction ? (O/N)"
    if ($Confirm -ine 'O' -and -not [string]::IsNullOrWhiteSpace($Confirm)) {
        Abord
    } else {
        # Creation de la Scheduled Task
        $command = New-ScheduledTaskAction `
            -Execute          $Execute `
            -Argument         $Arg `
            -WorkingDirectory $PSScriptRoot
        # $command    = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$Action`""
        if ($Interval -eq 'Non') {
            $trigger   = New-ScheduledTaskTrigger -Once -At $When
        } else {
            $trigger   = New-ScheduledTaskTrigger -Once -At $When `
                            -RepetitionInterval (New-TimeSpan -Minutes $Interval) `
                            -RepetitionDuration (New-TimeSpan -Days 666)
        }
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
        $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName "${NAME}_$BUILD" `
            -Action $command -Trigger $trigger -Principal $principal -Settings $settings -Description "It is expected" -Force

        # Verification avant echo
        Check
    }
}

function Check {
    $task = Get-ScheduledTask -TaskName "${NAME}_$BUILD" -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "OOPS !! ... Something went wrong !"
        Error
    }
    else {
        Jubilee
    }
}

function Delivrance {
    $task = Get-ScheduledTask -TaskName "${NAME}_$BUILD" -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "AUCUNE Sainte '$NAME' n'a été trouvée !"
        Error
    }
    else {
        Unregister-ScheduledTask -TaskName "${NAME}_$BUILD" -Confirm:$false -ErrorAction Stop

        $task = Get-ScheduledTask -TaskName "${NAME}_$BUILD" -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-Host "OK la Sainte '$NAME' ainsi fut exhorcisée."
        }
        else {
            Error
        }
    }

    $SONG = "$PSScriptRoot\Content\Hallelujah.mp3"; $global:player.Open($SONG); $global:player.Play()
    Start-Sleep -Seconds 10
    Close
}

# ===============
# Fermetures
# ===============

function Jubilee {
# $n = 1..9 | Get-Random 
$SONG = "$PSScriptRoot\Content\OhYeah.mp3"; $global:player.Open($SONG); $global:player.Play()
Write-Host @"
    


    Grâce vous soit rendue car ainsi '$NAME' fut engeandrée.
	       ___
	  (`\,;^+^+^+;,/`)
	 (- (((o.o))) -)
	(-   ))\-/((   -)
	(-   (() ())   -)
	 \   `/`@`\`   /
	  \  /     \  /
	   \/       \/
	   /         \
	  /_/_/_^|_\_\_\

"@
Start-Sleep -Seconds 6
Close
}

function Abord {
$SONG = "$PSScriptRoot\Content\Monkey.mp3"; $global:player.Open($SONG); $global:player.Play()
Write-Host @"



 Priere annulee sale mecreant.
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
Start-Sleep -Seconds 3
Start-Process "https://fr.wikihow.com/devenir-plus-intelligent"
Start-Sleep -Seconds 3
Close
}

function Error {
$SONG = "$PSScriptRoot\Content\Demon.mp3"; $global:player.Open($SONG); $global:player.Play()
Write-Host @"



 NOK Erreur lors de la priere soyez maudit.
	      (                      )
      ^|\    _,--------._    / ^|
      ^| `.,'            `. /  ^|
      `  '              ,-'   '
       \/_         _   (     /
      (,-.`.    ,',-.`. `__,'
       ^|/#\ ),-','#\`= ,'.` ^|
       `._/)  -'.\_,'   ) ))^|
       /  (_.)\     .   -'//
      (  /\____/\    ) )`'\
       \ ^|V----V^|^|  ' ,    \
        ^|`- -- -'   ,'   \  \      _____
 ___    ^|         .'    \ \  `._,-'     `-
    `.__,`---^---'       \ ` -'
       -.______  \ . /  ______,-
               `.     ,'          

"@
Start-Sleep -Seconds 6
Close
}

function Close {
if ($global:player) { $global:player.Stop(); $global:player.Close() }   # Stopper la lecture
Stop-Process -Id $PID -Force
}

# ===============
# Lancement final du script
# ===============

# Demarrage du menu (après définition du script)
MenuDuJour