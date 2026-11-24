<#
___________________________________________
__ Nom : 	 	BeneQuizz.
__ Autheur :	MMI
__ Version :	6.6.6.6 (v1.0)
__ Date :		09/11/2026
__ Update :		.
___________________________________________
#>

using namespace System.Windows.Forms
using namespace System.Drawing
using namespace System.Drawing.Imaging

param(
    [string]$Mode
)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing, PresentationCore
[Application]::EnableVisualStyles()

# =============================================================================
# 1. PARAMETRES
# =============================================================================

$NAME   = 'BeneQuizz'
$BUILD  = 'v1.0'
# $MODE   = "Fun"
# $MODE   = "Casual"
# $MODE   = "Deathmatch"

$SONG  = "$PSScriptRoot\..\Content\QuizzSoundscape.mp3"
$QFILE = "$PSScriptRoot\..\Content\Ressources\Quizz.json"

# Winnner sounds
$Winners = @(
    "$PSScriptRoot\..\Content\OhYeah.mp3",
    "$PSScriptRoot\..\Content\Ouiii.mp3",
    "$PSScriptRoot\..\Content\Pokeball.mp3",
    "$PSScriptRoot\..\Content\Genial.mp3",
    "$PSScriptRoot\..\Content\BravoMaCherie.mp3",
    "$PSScriptRoot\..\Content\GoodBoy.mp3",
    "$PSScriptRoot\..\Content\Meow.mp3",
    "$PSScriptRoot\..\Content\Woah.mp3",
    "$PSScriptRoot\..\Content\Tuturu.mp3"
)
# Looser sounds
$Loosers = @(
    "$PSScriptRoot\..\Content\OhMiiince.mp3",
    "$PSScriptRoot\..\Content\Oops.mp3",
    "$PSScriptRoot\..\Content\OopsOopsOops.mp3",
    "$PSScriptRoot\..\Content\OopsieWoopsie.mp3",
    "$PSScriptRoot\..\Content\Goat.mp3",
    "$PSScriptRoot\..\Content\LooserGirl.mp3",
    "$PSScriptRoot\..\Content\PetitCon.mp3",
    "$PSScriptRoot\..\Content\OhNo.mp3"
)
# Time Up sounds
$TimeUppers = @(
    "$PSScriptRoot\..\Content\FartReverb.mp3",
    "$PSScriptRoot\..\Content\BurpReverb.mp3"
)
# Game Won sounds
$VICT  = "$PSScriptRoot\..\Content\HappySong.mp3"
# Game over sounds
$GAMO  = "$PSScriptRoot\..\Content\Demon.mp3"

$RSRC       = "$PSScriptRoot\..\Content\Ressources\"
$LifeIcon   = (Join-Path $RSRC 'NyanCatHead-32.png') ; $IconSize = 32    # fichiers 128x128 ; $IconSize = taille affichée à S = 1
$DeadIcon   = (Join-Path $RSRC 'NyanCatDeadHead-32.png')

$AnswerCount      = 3       # nombre de boutons de réponse

# Affichage : l'interface est dessinée pour une référence (S = 1), puis mise à l'échelle au lancement
$RefW         = 1280        # largeur de la zone de jeu à S = 1 (pixels)
$RefH         = 800         # hauteur de la zone de jeu à S = 1 (pixels)
$RefScreenH   = 1440        # hauteur d'écran pour laquelle S = 1
$ScaleMin     = 0.9         # plancher de S (petits écrans)
$ScaleMax     = 3.0         # plafond de S (8K)
$ScaleStep    = 0.05        # pas d'arrondi de S
$ForceScreenH = $null       # test : simule une hauteur d'écran (ex. 1080, 2160, 4320) ; $null = automatique

# Réglages du jeu
if ($MODE -eq "Fun") { $CountdownSeconds = 12 } elseif ($MODE -eq "Casual") { $CountdownSeconds = 15 } elseif ($MODE -eq "Deathmatch") { $CountdownSeconds = 12 }   # durée du décompte par question
if ($MODE -eq "Fun") { $LoosingCountDown = 8 } elseif ($MODE -eq "Casual") { $LoosingCountDown = 12 } elseif ($MODE -eq "Deathmatch") { $LoosingCountDown = 8 }     # durée du décompte lorsque l'on perd

if ($MODE -eq "Fun") { $PauseSeconds = 5 } elseif ($MODE -eq "Casual") { $PauseSeconds = 6 } elseif ($MODE -eq "Deathmatch") { $PauseSeconds = 4 }                  # durée de pause entre les questions

if ($MODE -eq "Fun") { $Lives = 5 } elseif ($MODE -eq "Casual") { $Lives = 7 } elseif ($MODE -eq "Deathmatch") { $Lives = 3 }           # nombre de vies au départ
if ($MODE -eq "Fun") { $WinGoal = 7 } elseif ($MODE -eq "Casual") { $WinGoal = 10 } elseif ($MODE -eq "Deathmatch") { $WinGoal = 5 }    # bonnes réponses nécessaires pour gagner

if ($MODE -eq "Deathmatch") { $DEADLY = $true } else { $DEADLY = $false }   # Deadly mode (shutdown du PC si abandon ou défaite)

# Couleurs (boutons de réponse)
$Colors = @{
    # Standard
    BtnBack   = [Color]::FromArgb(253, 253, 253)
    BtnHover  = [Color]::FromArgb(224, 238, 249)
    BtnDown   = [Color]::FromArgb(204, 228, 247)
    BtnBorder = [Color]::FromArgb(173, 173, 173)
    # Answered
    Locked    = [Color]::FromArgb(130, 130, 130)
    LockBack  = [Color]::FromArgb(190, 190, 190)
    GoodFore  = [Color]::FromArgb(0, 128, 0)
    GoodBack  = [Color]::FromArgb(198, 239, 206)
    BadFore   = [Color]::FromArgb(192, 0, 0)
    BadBack   = [Color]::FromArgb(255, 199, 206)
    RevlBack  = [Color]::FromArgb(235, 249, 238)
}

# =============================================================================
# 2. DONNEES : questions
#    Lines     : lignes de texte en haut à gauche
#    Prompt    : ligne centrée au-dessus des boutons
#    Answers   : $AnswerCount réponses @{ Text ; Correct }
#    Image     : chemin d'image ou $null
#    NoShuffle : (optionnel) $true = garde l'ordre des réponses tel qu'écrit
# =============================================================================

# $Questions = @(
#     @{ Prompt  = 'Quelle est la bonne réponse ?'
#        Answers = @(
#            @{ Text = 'Oui'       ; Correct = $true  }
#            @{ Text = 'Non'       ; Correct = $false }
#            @{ Text = 'Peut-être' ; Correct = $false }
#        )
#        Image   = (Join-Path $RSRC 'Greek.jpg') }
#     @{ Prompt  = 'Quelle est la couleur ?'
#        Answers = @(
#            @{ Text = 'Rouge' ; Correct = $false }
#            @{ Text = 'Vert'  ; Correct = $false }
#            @{ Text = 'Bleu'  ; Correct = $true  }
#        )
#        Image   = (Join-Path $RSRC 'ColorsRender1.jpg') }
#     @{ Prompt  = 'Quelle est la forme ?'
#        Answers = @(
#            @{ Text = 'Triangle' ; Correct = $false }
#            @{ Text = 'Rond'     ; Correct = $true  }
#            @{ Text = 'Carré'    ; Correct = $false }
#        )
#        Image   = (Join-Path $RSRC 'Geom.jpg')
#        NoShuffle = $false }
# )

# foreach ($q in $Questions) {
#     if (@($q.Answers).Count -ne $AnswerCount) {
#         throw "Question '$($q.Prompt)' : $AnswerCount réponses attendues."
#     }
# }

# =============================================================================
# 3. ETAT DU JEU
# =============================================================================

$script:questions = @()      # toutes les questions chargées
$script:order     = @()      # ordre de passage (index mélangés)
$script:cursor    = 0        # position dans $script:order

$script:shown     = @()      # réponses de la question en cours, dans l'ordre affiché
$script:locked    = $false   # $true = boutons gelés (clics ignorés)

$script:elapsed   = 0        # temps écoulé (jamais réinitialisé)
$script:remaining = 0        # décompte en cours
$script:counting  = $false   # $true = le décompte avance à chaque tick
$script:paused    = $false   # $true = décompte gelé, clics ignorés

$script:current   = $null    # question en cours

$script:wins      = 0        # nombre de bonnes réponses
$script:played    = 0        # nombre de parties jouées
$script:lives     = $Lives   # nombre de vies au départ

# =============================================================================
# 3b. ECHELLE ET MISE EN PAGE
#     $Scale est calculé une fois, d'après la hauteur de l'écran principal.
#     Toutes les dimensions (pixels) et toutes les polices (pixels) passent ensuite par lui :
#     la fenêtre occupe toujours la même proportion de l'écran, quel que soit le DPI Windows.
# =============================================================================

$bounds  = [Screen]::PrimaryScreen.Bounds
$screenH = if ($ForceScreenH) { $ForceScreenH } else { $bounds.Height }
$screenW = $bounds.Width * $screenH / $bounds.Height                     # largeur proportionnelle (cas simulé)

$Scale = [Math]::Round($screenH / $RefScreenH / $ScaleStep) * $ScaleStep
$Scale = [Math]::Max($ScaleMin, [Math]::Min($ScaleMax, $Scale))
$Scale = [Math]::Min($Scale, 0.9 * $screenW / $RefW)                     # sécurité : jamais plus de 90 % de la largeur

# Valeur de référence (S = 1) -> pixels réels
function px {
    param([double]$Value)
    [int][Math]::Round($Value * $Scale)
}

# Police Segoe UI définie en pixels (insensible au DPI de Windows), taille de référence à S = 1
function New-UiFont {
    param([double]$Size, [FontStyle]$Style = [FontStyle]::Regular)
    [Font]::new('Segoe UI', [float](px $Size), $Style, [GraphicsUnit]::Pixel)
}

# Charge une image (sans verrouiller le fichier) et la redimensionne UNE fois, en haute qualité,
# pour tenir dans Width x Height (proportions conservées). Opacity < 1 : version atténuée.
function Get-ScaledImage {
    param([string]$Path, [int]$Width, [int]$Height, [double]$Opacity = 1)

    $ms  = [IO.MemoryStream]::new([IO.File]::ReadAllBytes($Path))
    $src = [Image]::FromStream($ms)
    $k   = [Math]::Min($Width / $src.Width, $Height / $src.Height)
    $w   = [Math]::Max(1, [int][Math]::Round($src.Width  * $k))
    $h   = [Math]::Max(1, [int][Math]::Round($src.Height * $k))

    $ia = [ImageAttributes]::new()
    $ia.SetWrapMode('TileFlipXY')                        # évite le halo sur les bords
    if ($Opacity -lt 1) {
        $cm = [ColorMatrix]::new() ; $cm.Matrix33 = [float]$Opacity
        $ia.SetColorMatrix($cm)
    }

    $bmp = [Bitmap]::new($w, $h)
    $g   = [Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode   = 'HighQuality'
    $g.DrawImage($src, [Rectangle]::new(0, 0, $w, $h), 0, 0, $src.Width, $src.Height, 'Pixel', $ia)

    $g.Dispose() ; $ia.Dispose() ; $src.Dispose() ; $ms.Dispose()
    $bmp
}

# Toutes les valeurs de mise en page (valeurs de référence à S = 1, déjà converties en pixels réels)
$UI = @{
    # Fenêtre
    FormW      = px $RefW
    FormH      = px $RefH
    Pad        = px 24
    # Hauteurs des rangées de la racine
    RowHeader  = px 145                                  # texte + décompte + score
    RowImage   = px 340                                  # image (320 + 10 de marge de chaque côté)
    RowPrompt  = px 70                                   # question (2 lignes)
    RowButtons = px 76                                   # boutons de réponse
    RowFooter  = px 50                                   # Pause / Abandonner
    # Header
    CountColW  = px 240                                  # colonne centrale (décompte)
    Gap        = px 3                                    # petite marge autour des textes
    TextMargin = [Padding]::new((px 3))
    # Image centrale
    PicW       = px 640
    PicH       = px 320
    # Boutons
    BtnW       = px 200
    BtnH       = px 50
    BtnGap     = px 15
    FootBtnW   = px 120
    FootBtnH   = px 36
    # Icônes de vie
    Icon       = px $IconSize
    # Polices (pixels ; équivalent du rendu 125 % validé : 12 pt = 20 px, 14 pt = 23 px, 48 pt = 80 px)
    FontBtn    = New-UiFont 15
    FontText   = New-UiFont 23
    FontBold   = New-UiFont 23 Bold
    FontBig    = New-UiFont 80 Bold
    FontBtnBold  = New-UiFont 17 Bold
    FontFeedback = New-UiFont 20 Italic
}

# =============================================================================
# 4. INTERFACE
# =============================================================================

$form = [Form]@{
    Text            = "$NAME.exe"
    AutoScaleMode   = 'None'                             # aucune mise à l'échelle automatique : tout passe par $Scale
    Font            = $UI.FontBtn                        # police héritée par les boutons
    ClientSize      = [Size]::new($UI.FormW, $UI.FormH)
    StartPosition   = 'CenterScreen' ; FormBorderStyle = 'FixedDialog'
    MaximizeBox     = $false ; MinimizeBox = $false
}

# --- Racine : 1 colonne, 6 lignes ---
$root = [TableLayoutPanel]@{
    Dock = 'Fill' ; ColumnCount = 1 ; RowCount = 6
    Padding = [Padding]::new($UI.Pad)
}
$null = $root.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
$null = $root.RowStyles.Add([RowStyle]::new('Absolute', $UI.RowHeader))    # 0 texte + timers
$null = $root.RowStyles.Add([RowStyle]::new('Absolute', $UI.RowImage))     # 1 image
$null = $root.RowStyles.Add([RowStyle]::new('Absolute', $UI.RowPrompt))    # 2 ligne de texte centrée
$null = $root.RowStyles.Add([RowStyle]::new('Absolute', $UI.RowButtons))   # 3 boutons
$null = $root.RowStyles.Add([RowStyle]::new('Percent', 100))               # 4 espace libre
$null = $root.RowStyles.Add([RowStyle]::new('Absolute', $UI.RowFooter))    # 5 quitter

# --- Ligne 0 : texte (gauche) + décompte (centre) + score/temps écoulé (droite) ---
$header = [TableLayoutPanel]@{ Dock = 'Fill' ; ColumnCount = 3 ; RowCount = 1 ; Margin = [Padding]::new(0) }
$null = $header.ColumnStyles.Add([ColumnStyle]::new('Percent', 50))
$null = $header.ColumnStyles.Add([ColumnStyle]::new('Absolute', $UI.CountColW))
$null = $header.ColumnStyles.Add([ColumnStyle]::new('Percent', 50))
$null = $header.RowStyles.Add([RowStyle]::new('Percent', 100))

# Panneau de gauche : 2 lignes libres + temps écoulé (chrono)
$lblLine1   = [Label]@{ Text = "$NAME !" ; AutoSize = $true ; Font = $UI.FontText ; Margin = $UI.TextMargin }
$lblLine2   = [Label]@{ Text = "Mode de jeu : $MODE" ; AutoSize = $true ; Font = $UI.FontText ; Margin = $UI.TextMargin }
$lblElapsed = [Label]@{ Text = 'Temps écoulé : 00:00' ; AutoSize = $true ; Font = $UI.FontText ; Margin = $UI.TextMargin }
$leftPanel  = [FlowLayoutPanel]@{ Dock = 'Fill' ; FlowDirection = 'TopDown' ; WrapContents = $false }
$leftPanel.Controls.AddRange(@($lblLine1, $lblLine2, $lblElapsed))

# Icônes de vie : chat éveillé / chat qui dort (semi-transparent) pour une vie perdue
# (fichiers en haute définition, réduits une seule fois à la taille affichée)
$iconOn  = Get-ScaledImage $LifeIcon $UI.Icon $UI.Icon
$iconOff = Get-ScaledImage $DeadIcon $UI.Icon $UI.Icon 0.5          # opacité d'une vie perdue

# Panneau de droite : score, vies, temps écoulé (les lignes s'empilent toutes seules)
$rightPanel = [TableLayoutPanel]@{ AutoSize = $true ; ColumnCount = 1 ; Anchor = 'Top, Right' }
$lblScore   = [Label]@{ Text = "Score : 0 / $WinGoal" ; AutoSize = $true ; Anchor = 'Right' ; Font = $UI.FontText ; Margin = $UI.TextMargin }
$lblLives   = [Label]@{ Text = 'Vies restantes :' ; AutoSize = $true ; Anchor = 'Right' ; Font = $UI.FontText ; Margin = $UI.TextMargin }
$lifeIcons  = @(1..$Lives | ForEach-Object {
    [PictureBox]@{ Size = [Size]::new($UI.Icon, $UI.Icon) ; SizeMode = 'Zoom' ; Image = $iconOn ; Margin = $UI.TextMargin }
})
$livesFlow  = [FlowLayoutPanel]@{ AutoSize = $true ; WrapContents = $false ; Anchor = 'Right' }
$livesFlow.Controls.AddRange($lifeIcons)
$rightPanel.Controls.AddRange(@($lblScore, $lblLives, $livesFlow))

# Décompte : titre + chiffres. Les chiffres (AutoSize) sont remontés dans un Panel qui rogne le vide
# au-dessus de la police ; les valeurs se déduisent de la hauteur de ligne réelle de la police.
$lblCountdownTitle = [Label]@{
    Text = 'Temps restant' ; AutoSize = $true ; Anchor = 'None'
    Font = $UI.FontText
    Margin = [Padding]::new(0, $UI.Gap, 0, 0)
}
$lblCountdown = [Label]@{
    Text = '00:00' ; AutoSize = $true ; Anchor = 'Top'
    Font = $UI.FontBig
    Margin = [Padding]::new(0)
}

$fh  = $lblCountdown.Font.Height                         # hauteur de ligne réelle (en pixels)
$cut = [int]($fh * 0.2)                                  # vide rogné au-dessus des chiffres

$digits = [TableLayoutPanel]@{ Size = [Size]::new($UI.CountColW, $fh) ; Location = [Point]::new(0, -$cut) ; ColumnCount = 1 }
$null = $digits.ColumnStyles.Add([ColumnStyle]::new('Percent', 100))
$digits.Controls.Add($lblCountdown, 0, 0)

$clip = [Panel]@{ Size = [Size]::new($UI.CountColW, $fh - $cut - [int]($fh * 0.1)) ; Anchor = 'None' ; Margin = [Padding]::new(0) }
$clip.Controls.Add($digits)

$countdownPanel = [TableLayoutPanel]@{ AutoSize = $true ; ColumnCount = 1 ; RowCount = 2 ; Anchor = 'Top' }
$null = $countdownPanel.RowStyles.Add([RowStyle]::new('AutoSize'))
$null = $countdownPanel.RowStyles.Add([RowStyle]::new('AutoSize'))
$countdownPanel.Controls.Add($lblCountdownTitle, 0, 0)
$countdownPanel.Controls.Add($clip, 0, 1)

$header.Controls.Add($leftPanel, 0, 0)
$header.Controls.Add($countdownPanel, 1, 0)
$header.Controls.Add($rightPanel, 2, 0)

# --- Ligne 1 : image à taille fixe, centrée (l'image est déjà à la bonne taille : CenterImage) ---
$pic = [PictureBox]@{
    Size = [Size]::new($UI.PicW, $UI.PicH) ; Anchor = 'None'
    SizeMode = 'CenterImage' ; BorderStyle = 'FixedSingle'
}

# --- Ligne 2 : ligne de texte centrée (au-dessus des boutons) ---
$lblPrompt = [Label]@{
    Dock = 'Fill' ; TextAlign = 'MiddleCenter'
    Font = $UI.FontBold
}

# --- Ligne 3 : boutons de réponse, centrés et espacés ---
# FlatStyle Flat : permet de contrôler les couleurs de survol/clic (cf. Set-ButtonState)
$flow = [FlowLayoutPanel]@{ AutoSize = $true ; WrapContents = $false ; Anchor = 'None' }
$answerButtons = @(foreach ($i in 0..($AnswerCount - 1)) {
    $btn = [Button]@{
        Text = "Reponse $('ABC'[$i])" ; Size = [Size]::new($UI.BtnW, $UI.BtnH)
        Margin = [Padding]::new($UI.BtnGap, 0, $UI.BtnGap, 0)
        FlatStyle = 'Flat' ; TabStop = $false ; Font = $UI.FontBtnBold
        Tag = $i                                         # index mémorisé dans le bouton
    }
    $btn.FlatAppearance.BorderSize  = 1
    $btn.FlatAppearance.BorderColor = $Colors.BtnBorder
    $btn.Add_Click({ Invoke-Answer -Index $this.Tag })    # $this = bouton cliqué
    $flow.Controls.Add($btn)
    $btn
})

# --- Ligne 4 : texte propre à la question, affiché pendant la pause (sous les boutons) ---
$lblFeedback = [Label]@{
    Dock = 'Fill' ; TextAlign = 'MiddleCenter'
    Font = $UI.FontFeedback
}

# --- Ligne 5 : Pause en bas à gauche (mode Casual seulement), Quitter en bas à droite ---
$btnPause = [Button]@{
    Text = 'Pause' ; Size = [Size]::new($UI.FootBtnW, $UI.FootBtnH) ; Anchor = 'Bottom, Left'
    Enabled = ($MODE -eq 'Casual')
}
$btnPause.Add_Click({
    $script:paused = -not $script:paused
    $this.Text = if ($script:paused) { 'Reprendre' } else { 'Pause' }
})
$btnQuit = [Button]@{
    Text = 'Abandonner' ; Size = [Size]::new($UI.FootBtnW, $UI.FootBtnH) ; Anchor = 'Bottom, Right'
}
$btnQuit.Add_Click({ $form.Close() })

$footer = [TableLayoutPanel]@{ Dock = 'Fill' ; ColumnCount = 2 ; RowCount = 1 }
$null = $footer.ColumnStyles.Add([ColumnStyle]::new('Percent', 50))
$null = $footer.ColumnStyles.Add([ColumnStyle]::new('Percent', 50))
$null = $footer.RowStyles.Add([RowStyle]::new('Percent', 100))
$footer.Controls.Add($btnPause, 0, 0)
$footer.Controls.Add($btnQuit, 1, 0)

# --- Assemblage ---
$root.Controls.Add($header,      0, 0)
$root.Controls.Add($pic,         0, 1)
$root.Controls.Add($lblPrompt,   0, 2)
$root.Controls.Add($flow,        0, 3)
$root.Controls.Add($lblFeedback, 0, 4)
$root.Controls.Add($footer,      0, 5)
$form.Controls.Add($root)

# =============================================================================
# 5. FONCTIONS : outils
# =============================================================================

function Format-Time {
    param([int]$Seconds)
    [TimeSpan]::FromSeconds($Seconds).ToString('mm\:ss')
}

function Start-Music {
    if (-not (Test-Path $SONG)) { return }               # pas de plantage si le fichier manque
    if (-not $global:player) { $global:player = [System.Windows.Media.MediaPlayer]::new() }
    $global:player.Open([Uri][IO.Path]::GetFullPath($SONG))
    # S'abonner à l'événement de fin de lecture pour boucler
    Register-ObjectEvent -InputObject $global:player -EventName MediaEnded -Action {
        $global:player.Position = [TimeSpan]::Zero
        $global:player.Play()
    } | Out-Null
    $global:player.Play()
}

function Update-Score {
    param([bool]$Won)
    if (-not $Won) { return }
    $script:wins++
    $lblScore.Text = "Score : $($script:wins) / $WinGoal"
    if ($script:wins -eq $WinGoal) { Invoke-Victory }
}

# Lit et parse le fichier de questions (la source pourra changer plus tard : déchiffrement...)
function Import-Questions {
    param([string]$Path = $QFILE)
    $json = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    $data = ConvertFrom-Json $json
    @($data)                                             # garantit un tableau, même avec une seule question
}

# Mélange les index une seule fois ; évite d'enchaîner la même question entre deux cycles
function Reset-Pool {
    $n    = $script:questions.Count
    $last = if ($script:order.Count) { $script:order[-1] } else { -1 }
    $script:order = @(Get-Random -InputObject (0..($n - 1)) -Count $n)
    if ($n -gt 1 -and $script:order[0] -eq $last) {
        $script:order[0], $script:order[-1] = $script:order[-1], $script:order[0]
    }
    $script:cursor = 0
}

# Tirage sans remise : question suivante de la liste mélangée, remélange en fin de cycle
function Get-NextQuestion {
    if ($script:cursor -ge $script:order.Count) { Reset-Pool }
    $script:questions[$script:order[$script:cursor++]]
}

# =============================================================================
# 6. FONCTIONS : décompte (le temps écoulé, lui, ne s'arrête jamais)
# =============================================================================

function Reset-Countdown {
    param([int]$Seconds = $CountdownSeconds)

    $script:remaining       = $Seconds
    $script:counting        = $true
    $lblCountdown.Text      = Format-Time $Seconds
    $lblCountdown.ForeColor = [SystemColors]::ControlText
}

function Stop-Countdown {
    $script:counting = $false                            # l'affichage reste figé
}

# =============================================================================
# 7. FONCTIONS : état visuel des boutons
#    Normal : aspect de base      Locked : gelé, police grisée
#    Good   : clic juste (vert)   Bad    : clic faux (rouge)
#    Reveal : bonne réponse non cliquée (police verte, fond inchangé)
# =============================================================================

function Set-ButtonState {
    param(
        [Button]$Button,
        [ValidateSet('Normal', 'Locked', 'Good', 'Bad', 'Reveal')][string]$State
    )
    switch ($State) {
        'Normal' {
            $Button.ForeColor = [SystemColors]::ControlText
            $Button.BackColor = $Colors.BtnBack
            $Button.FlatAppearance.MouseOverBackColor = $Colors.BtnHover
            $Button.FlatAppearance.MouseDownBackColor = $Colors.BtnDown
            return
        }
        'Locked' { $Button.ForeColor = $Colors.Locked   ; $Button.BackColor = $Colors.LockBack }
        'Good'   { $Button.ForeColor = $Colors.GoodFore ; $Button.BackColor = $Colors.GoodBack }
        'Bad'    { $Button.ForeColor = $Colors.BadFore  ; $Button.BackColor = $Colors.BadBack }
        'Reveal' { $Button.ForeColor = $Colors.GoodFore ; $Button.BackColor = $Colors.RevlBack }
    }
    # États gelés : survol et clic = couleur de fond actuelle (aucun effet visible)
    $Button.FlatAppearance.MouseOverBackColor = $Button.BackColor
    $Button.FlatAppearance.MouseDownBackColor = $Button.BackColor
}

function Set-AllButtons {
    param([string]$State)
    foreach ($b in $answerButtons) { Set-ButtonState $b $State }
}

function Show-CorrectAnswers {
    for ($i = 0; $i -lt $script:shown.Count; $i++) {
        if ($script:shown[$i].Correct) { Set-ButtonState $answerButtons[$i] 'Reveal' }
    }
}

# =============================================================================
# 8. FONCTIONS : contenu de la question (lignes, prompt, boutons, image)
# =============================================================================

# L'image est redimensionnée une fois à la taille de la zone d'affichage (cf. Get-ScaledImage)
function Set-QuizImage {
    param([string]$Path)

    if ($pic.Image) { $pic.Image.Dispose() ; $pic.Image = $null }
    if ($Path -and (Test-Path $Path)) {
        $pic.Image = Get-ScaledImage $Path $pic.ClientSize.Width $pic.ClientSize.Height
    }
}

function Set-Question {
    param([Parameter(Mandatory)]$Q)

    $script:current   = $Q
    $lblFeedback.Text = ''
    $lblPrompt.Text = $Q.prompt
    Set-QuizImage $(if ($Q.image) { Join-Path $RSRC $Q.image })   # $null = pas d'image

    $answers = @($Q.answers)
    if (-not $Q.noShuffle) { $answers = @($answers | Get-Random -Count $answers.Count) }

    $script:shown = $answers                             # ordre réellement affiché
    for ($i = 0; $i -lt $answerButtons.Count; $i++) {
        $answerButtons[$i].Text = $answers[$i].text
    }
}

function Show-NextQuestion {
    $pauseTimer.Stop()
    if ($script:lives -le 0 -or $script:wins -ge $WinGoal) { return }   # partie finie : pas de question suivante
    Set-AllButtons 'Normal'
    $script:locked = $false
    Set-Question (Get-NextQuestion)
    Reset-Countdown
}

# =============================================================================
# 9. FONCTIONS : réponse / fin du temps
# =============================================================================

# Fige la manche : clics ignorés, décompte figé, boutons grisés
function Lock-Round {
    $script:locked = $true
    Stop-Countdown
    Set-AllButtons 'Locked'
    $lblFeedback.Text = $script:current.feedback
}

# Retire une vie ; à 0, déclenche la défaite
function Remove-Life {
    if ($script:lives -le 0) { return }
    $lifeIcons[--$script:lives].Image = $iconOff         # grise la dernière icône pleine
    if ($script:lives -eq 1) { $lblLives.ForeColor = [Color]::Red }
    if ($script:lives -eq 0) { Invoke-GameOver }
}

function Invoke-Answer {
    param([int]$Index)

    if ($script:locked -or $script:paused) { return }
    Lock-Round
    Update-Score -Won ([bool]$script:shown[$Index].Correct)

    if ($script:shown[$Index].Correct) {
        Set-ButtonState $answerButtons[$Index] 'Good'
        if ($script:wins -ge $WinGoal) { return }
        if (-not $global:pA) { $global:pA = [System.Windows.Media.MediaPlayer]::new() } else { $global:pA.Stop() }
        $global:pA.Open([Uri][IO.Path]::GetFullPath(($Winners | Get-Random))); $global:pA.Position = [TimeSpan]::Zero; $global:pA.Play()
    }
    else {
        Set-ButtonState $answerButtons[$Index] 'Bad'
        Show-CorrectAnswers
        Remove-Life
        if ($script:lives -le 0) { return }
        if (-not $global:pB) { $global:pB = [System.Windows.Media.MediaPlayer]::new() } else { $global:pB.Stop() }
        $global:pB.Open([Uri][IO.Path]::GetFullPath(($Loosers | Get-Random))); $global:pB.Position = [TimeSpan]::Zero; $global:pB.Play()
        
    }
    $pauseTimer.Start()                                  # puis Show-NextQuestion
}

function Invoke-TimeUp {
    Lock-Round
    Update-Score -Won $false
    Show-CorrectAnswers
    Remove-Life
    if ($script:lives -le 0) { return }
    if (-not $global:pC) { $global:pC = [System.Windows.Media.MediaPlayer]::new() } else { $global:pC.Stop() }
    $global:pC.Open([Uri][IO.Path]::GetFullPath(($TimeUppers | Get-Random))); $global:pC.Position = [TimeSpan]::Zero; $global:pC.Play()
    $pauseTimer.Start()                                  # puis Show-NextQuestion
}

# =============================================================================
# 10. GAME OVER / Victory
# =============================================================================

# Appelé quand il ne reste plus aucune vie
function Invoke-GameOver {
    if ($global:player) { $global:player.Stop() }
    $form.BackColor = [System.Drawing.Color]::FromArgb(234, 111, 83)
    if (-not $global:pL) { $global:pL = New-Object System.Windows.Media.MediaPlayer; $global:pL.Open($GAMO) }; $global:pL.Position = [TimeSpan]::Zero; $global:pL.Play()
    
    # TODO : écran de défaite...

    if ($DEADLY) { shutdown -s -t 10 }

    $script:endTimer = [Timer]@{ Interval = 9 * 1000 }
    $script:endTimer.Add_Tick({ $this.Stop() ; $form.Close() })
    $script:endTimer.Start()
}

function Invoke-Victory {
    if ($global:player) { $global:player.Stop() }
    $form.BackColor = [System.Drawing.Color]::FromArgb(134, 195, 141)
    if (-not $global:pW) { $global:pW = New-Object System.Windows.Media.MediaPlayer; $global:pW.Open($VICT) }; $global:pW.Position = [TimeSpan]::Zero; $global:pW.Play()

    # TODO : écran de réussite + vous avez gagné le droit de rejouer...

    $DEADLY = $false

    $script:endTimer = [Timer]@{ Interval = 15 * 1000}
    $script:endTimer.Add_Tick({ $this.Stop() ; $form.Close() })
    $script:endTimer.Start()

}

# =============================================================================
# 11. LE SEIGNEUR DU TEMPS
# =============================================================================

# Timer principal : tourne en continu, ne s'arrête jamais
$timer = [Timer]@{ Interval = 1000 }
$timer.Add_Tick({
    $script:elapsed++
    $lblElapsed.Text = 'Temps écoulé : ' + (Format-Time $script:elapsed)

    if (-not $script:counting -or $script:paused) { return }

    $script:remaining--
    $lblCountdown.Text = Format-Time $script:remaining
    if ($script:remaining -le 3 -and $script:remaining -ge 1) {
            $lblCountdown.ForeColor = [Color]::Orange
        }
    if ($script:remaining -le 0) {
        $lblCountdown.ForeColor = [Color]::Red
        Invoke-TimeUp
    }
})

# Timer de pause : affichage du résultat, puis question suivante
$pauseTimer = [Timer]@{ Interval = $PauseSeconds * 1000 }
$pauseTimer.Add_Tick({ Show-NextQuestion })              # Show-NextQuestion l'arrête

# =============================================================================
# 12. QUITCALL
# =============================================================================

$form.Add_FormClosing({
    # ajouter une confirmation, si oui alors appel au loose

    $global:player.Open($GAMO); $global:player.Play()
    Start-Sleep -Seconds 1

    $timer.Stop() ; $pauseTimer.Stop()
    if ($global:player) { $global:player.Stop() ; $global:player.Close() }
    if ($pic.Image) { $pic.Image.Dispose() }
    $timer.Dispose() ; $pauseTimer.Dispose()
})

# =============================================================================
# 13. DEMARRAGE
# =============================================================================

$script:questions = @(Import-Questions)
Reset-Pool

Start-Music
Show-NextQuestion
$timer.Start()

[Application]::Run($form)