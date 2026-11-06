# Chargement de Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
 
# Creation du formulaire
$form = New-Object System.Windows.Forms.Form
$form.Text = "Benedictus.exe"
$form.Size = New-Object System.Drawing.Size(320, 150)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
 
# Label avec le texte
$label = New-Object System.Windows.Forms.Label
$label.Text = "You are an idiot !"
$label.TextAlign = "MiddleCenter"
$label.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$label.Size = New-Object System.Drawing.Size(280, 40)
$label.Location = New-Object System.Drawing.Point(10, 15)
$form.Controls.Add($label)
 
# Bouton OK centre
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "Yes"
$okButton.Size = New-Object System.Drawing.Size(80, 30)
$okButton.Location = New-Object System.Drawing.Point((($form.ClientSize.Width - 80) / 2), 65)
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($okButton)
 
$form.AcceptButton = $okButton
 
# Affichage
[void]$form.ShowDialog()

# Rappel Audio que c'est un idiot
$SONG = "$PSScriptRoot\..\Content\Idiot.mp3"
# $SONG = (Resolve-Path (Join-Path $PSScriptRoot "..\Content\Idiot.mp3")).Path
if (-not $global:player) { 
    Add-Type -AssemblyName PresentationCore 
    $global:player = New-Object System.Windows.Media.MediaPlayer 
} 
$global:player.Open($SONG) 
$global:player.Play()
Start-Sleep -Seconds 9