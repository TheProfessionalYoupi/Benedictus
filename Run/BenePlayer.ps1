param(
    [string]$Audio
)

$SONG = "$PSScriptRoot\..\Content\$Audio"

if (-not $global:player) { 
    Add-Type -AssemblyName PresentationCore 
    $global:player = New-Object System.Windows.Media.MediaPlayer 
} 

$global:player.Open($SONG) 
$global:player.Play()

# Laisse le temps au lecteur audio de traiter le fichier
Start-Sleep -Seconds 9