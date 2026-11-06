$Text = @'
A problem has been detected and Windows has been locked to prevent damage 
to your computer.

CRITICAL_ORINOX_FAILED

If this is the first time you've seen this Stop error screen, 
do not restart your computer. If this screen appeared, perhaps follow
these steps:

Check to make sure this wasn't a joke from an Orinox colleague properly installed.
If this is a new installation, ask your them for a solution
for any Windows magical key you might need.

If problems continue, disable or remove any newly installed hardware 
or software. Disable BIOS memory options such as caching or shadowing.
If you need to use Safe Mode to remove or disable components, restart
your computer, press F66 to select Advanced Startup Options, and then
select Safe Mode.

Technical Information:

*** LOCK: 0x0000005A (0x00000001, 0x00000001, 0x00000000, 0x00000000)

Collecting data for crash dump ...
Initializing disk for crash dump ...
Beginning dump for physical memory.
Dumping physical memory to disk: 100
Physical memory dump complete.
Contact your system admin or technical support group for further assistance.
'@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ➜ Liste globale pour stocker tous les formulaires
$Global:Forms = @()
# ➜ Récupérer tous les écrans
$Screens = [System.Windows.Forms.Screen]::AllScreens

# ➜ Créer et afficher une form par écran
foreach ($Screen in $Screens) {

    $Label = New-Object System.Windows.Forms.Label
    $Label.TabIndex = 1
    $Label.Text = $Text
    $Label.ForeColor = 'White'
    $Label.AutoSize = $True
    $Label.Font = "Lucida Console, 16pt, style=Regular"
    $Label.Location = '0, 30'

    $Form = New-Object system.Windows.Forms.Form

    $Form.Controls.Add($Label)
    $Form.FormBorderStyle = 'None'
    $Form.BackColor = "#000080"
    $Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor

    # ➜ Placer le Form sur l'écran correspondant
    $Form.StartPosition = 'Manual'
    $Form.Bounds = $Screen.Bounds

    $Form.Show()
}

# ➜ Nécessaire pour que les fenêtres restent ouvertes
[System.Windows.Forms.Application]::Run()