<#
.SYNOPSIS
    BeneHero - Proof of concept d'un jeu de rythme (type Guitar Hero) en PowerShell + WinForms.

.DESCRIPTION
    Principes clés illustrés ici :
      - Le TEMPS est la source de vérité (Stopwatch) : la position des notes est recalculée
        à chaque frame (y = ligneFrappe - (tempsNote - tempsActuel) * vitesse), aucune dérive.
      - Rendu GDI+ dans un Panel double-buffered (petite classe C# via Add-Type).
      - Entrées clavier horodatées sur le même Stopwatch, gestion de l'auto-repeat.
      - Fenêtres de jugement (Parfait / Bien / Raté), score, combo, multiplicateur.
      - Partition générée par code (démo) ou chargée depuis un CSV "temps_ms;colonne".

    Touches : D F J K (colonnes 0 à 3) | Espace = démarrer / reprendre | Échap = pause.

.PARAMETER ChartPath
    Fichier CSV optionnel, une note par ligne : temps_en_ms;colonne (colonne de 0 à 3).
    Exemple :  2500;0  puis  3000;2  puis  3500;3
#>
param(
    [string]$ChartPath
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Panel double-buffered (DoubleBuffered est protégé : on passe par une sous-classe)
if (-not ('BeneHeroPanel' -as [type])) {
    Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System.Windows.Forms;
public class BeneHeroPanel : Panel {
    public BeneHeroPanel() {
        this.DoubleBuffered = true;
        this.ResizeRedraw = true;
    }
}
"@
}

#region Configuration -------------------------------------------------------
$Cfg = @{
    Width      = 480
    Height     = 720
    LaneCount  = 4
    LaneWidth  = 90
    HitY       = 620          # position verticale de la ligne de frappe
    NoteRadius = 28
    SpeedPxMs  = 0.45         # vitesse de défilement (pixels par milliseconde)
    PerfectMs  = 50           # fenêtre "Parfait"
    GoodMs     = 110          # fenêtre "Bien" (au-delà : raté)
    OffsetMs   = 0            # calibration audio/vidéo (plus tard : latence audio)
    LeadInMs   = 2500         # délai avant la première note de la partition de démo
}
$Cfg.LaneLeft = [int](($Cfg.Width - $Cfg.LaneCount * $Cfg.LaneWidth) / 2)

$LaneKeys   = @('D', 'F', 'J', 'K')
$LaneColors = @(
    [System.Drawing.Color]::FromArgb(255, 235, 64, 52),    # rouge
    [System.Drawing.Color]::FromArgb(255, 245, 190, 30),   # jaune
    [System.Drawing.Color]::FromArgb(255, 50, 190, 90),    # vert
    [System.Drawing.Color]::FromArgb(255, 60, 140, 245)    # bleu
)
# Mapping touche -> colonne (clé = code entier de la touche)
$KeyMap = @{}
for ($i = 0; $i -lt $LaneKeys.Count; $i++) {
    $k = [System.Windows.Forms.Keys]::$($LaneKeys[$i])
    $KeyMap[[int]$k] = $i
}
#endregion

#region Partition ------------------------------------------------------------
function New-Note([double]$time, [int]$lane) {
    [pscustomobject]@{ Time = $time; Lane = $lane; State = 0 }   # State : 0 en attente, 1 touchée, 2 ratée
}

function New-DemoChart {
    # 120 BPM, croches (250 ms) : notes quasi à chaque temps, plus rares sur les contretemps
    $notes = New-Object System.Collections.Generic.List[object]
    $rnd   = New-Object System.Random 42
    $step  = 250
    for ($i = 0; $i -lt 128; $i++) {
        $onBeat = (($i % 2) -eq 0)
        $p = if ($onBeat) { 0.85 } else { 0.30 }
        if ($rnd.NextDouble() -lt $p) {
            $notes.Add((New-Note ($Cfg.LeadInMs + $i * $step) $rnd.Next(0, $Cfg.LaneCount)))
        }
    }
    return $notes
}

function Import-Chart([string]$path) {
    $notes = New-Object System.Collections.Generic.List[object]
    foreach ($row in (Import-Csv -Path $path -Delimiter ';' -Header 'Time', 'Lane')) {
        $notes.Add((New-Note ([double]$row.Time) ([int]$row.Lane)))
    }
    # Le tri est indispensable : la logique suppose des notes ordonnées dans le temps
    $sorted = New-Object System.Collections.Generic.List[object]
    foreach ($n in ($notes | Sort-Object Time)) { $sorted.Add($n) }
    return $sorted
}
#endregion

#region État du jeu ----------------------------------------------------------
$G = @{
    State     = 'Menu'      # Menu | Playing | Paused | Finished
    Sw        = New-Object System.Diagnostics.Stopwatch
    Notes     = $null
    First     = 0           # index de la première note encore non résolue
    Down      = New-Object 'bool[]' 4
    Flash     = New-Object 'double[]' 4     # dernier appui par colonne (ms)
    Score     = 0
    Combo     = 0
    MaxCombo  = 0
    Perfects  = 0
    Goods     = 0
    Misses    = 0
    JText     = ''
    JColor    = [System.Drawing.Color]::White
    JTime     = -9999.0
    LastTime  = 0.0
}

if ($ChartPath -and (Test-Path $ChartPath)) { $G.Notes = Import-Chart $ChartPath }
else { $G.Notes = New-DemoChart }
$G.LastTime = $G.Notes[$G.Notes.Count - 1].Time

function Get-Now { return $G.Sw.Elapsed.TotalMilliseconds + $Cfg.OffsetMs }

function Set-Judgement([string]$text, [System.Drawing.Color]$color) {
    $G.JText  = $text
    $G.JColor = $color
    $G.JTime  = Get-Now
}

function Start-Game {
    foreach ($n in $G.Notes) { $n.State = 0 }
    $G.First = 0; $G.Score = 0; $G.Combo = 0; $G.MaxCombo = 0
    $G.Perfects = 0; $G.Goods = 0; $G.Misses = 0
    $G.JText = ''
    for ($i = 0; $i -lt 4; $i++) { $G.Down[$i] = $false; $G.Flash[$i] = -9999.0 }
    $G.Sw.Reset(); $G.Sw.Start()
    $G.State = 'Playing'
}

function Register-Press([int]$lane) {
    $now = Get-Now
    $G.Flash[$lane] = $now
    $notes = $G.Notes
    for ($i = $G.First; $i -lt $notes.Count; $i++) {
        $n = $notes[$i]
        if (($n.Time - $now) -gt $Cfg.GoodMs) { break }          # trop loin dans le futur
        if ($n.State -ne 0 -or $n.Lane -ne $lane) { continue }
        $delta = [math]::Abs($now - $n.Time)
        if ($delta -le $Cfg.GoodMs) {
            $n.State = 1
            $G.Combo++
            if ($G.Combo -gt $G.MaxCombo) { $G.MaxCombo = $G.Combo }
            $mult = [math]::Min(1 + [math]::Floor($G.Combo / 10), 4)
            if ($delta -le $Cfg.PerfectMs) {
                $G.Perfects++; $G.Score += 300 * $mult
                Set-Judgement 'PARFAIT' ([System.Drawing.Color]::Gold)
            } else {
                $G.Goods++; $G.Score += 100 * $mult
                Set-Judgement 'BIEN' ([System.Drawing.Color]::LightGreen)
            }
            return
        }
    }
    # Appui sans note dans la fenêtre : ignoré (on pourrait pénaliser ici)
}

function Update-Game {
    $now   = Get-Now
    $notes = $G.Notes
    # Notes dépassées sans appui -> ratées
    for ($i = $G.First; $i -lt $notes.Count; $i++) {
        $n = $notes[$i]
        if ($n.Time -gt ($now - $Cfg.GoodMs)) { break }
        if ($n.State -eq 0) {
            $n.State = 2
            $G.Misses++; $G.Combo = 0
            Set-Judgement 'RATE' ([System.Drawing.Color]::IndianRed)
        }
    }
    while ($G.First -lt $notes.Count -and $notes[$G.First].State -ne 0) { $G.First++ }

    if ($now -gt ($G.LastTime + 1500)) {
        $G.Sw.Stop()
        $G.State = 'Finished'
    }
}

function Set-Pause {
    if ($G.State -eq 'Playing') { $G.Sw.Stop(); $G.State = 'Paused' }
}
function Resume-Game {
    if ($G.State -eq 'Paused') { $G.Sw.Start(); $G.State = 'Playing' }
}
#endregion

#region Rendu ----------------------------------------------------------------
$fontBig   = New-Object System.Drawing.Font('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
$fontMid   = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$fontSmall = New-Object System.Drawing.Font('Segoe UI', 11)
$sfCenter  = New-Object System.Drawing.StringFormat
$sfCenter.Alignment     = [System.Drawing.StringAlignment]::Center
$sfCenter.LineAlignment = [System.Drawing.StringAlignment]::Center

$brushBg      = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 18, 18, 28))
$brushLane    = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 28, 28, 42))
$brushWhite   = [System.Drawing.Brushes]::White
$brushGray    = [System.Drawing.Brushes]::LightGray
$brushShade   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(170, 0, 0, 0))
$penLaneSep   = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 60, 60, 80)), 1
$penHitLine   = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 230, 230, 240)), 2
$laneBrushes  = foreach ($c in $LaneColors) { New-Object System.Drawing.SolidBrush $c }
$lanePens     = foreach ($c in $LaneColors) { New-Object System.Drawing.Pen $c, 3 }
$laneBrushes  = @($laneBrushes); $lanePens = @($lanePens)

# Une forme différente par colonne (utile aussi pour les daltoniens)
function Draw-Shape($g, [int]$lane, [single]$cx, [single]$cy, [single]$r, $brush) {
    switch ($lane) {
        0 { $g.FillEllipse($brush, $cx - $r, $cy - $r, 2 * $r, 2 * $r) }
        1 { $g.FillRectangle($brush, $cx - $r, $cy - $r, 2 * $r, 2 * $r) }
        2 {
            $pts = [System.Drawing.PointF[]]@(
                (New-Object System.Drawing.PointF($cx, ($cy - $r - 4))),
                (New-Object System.Drawing.PointF(($cx + $r + 4), $cy)),
                (New-Object System.Drawing.PointF($cx, ($cy + $r + 4))),
                (New-Object System.Drawing.PointF(($cx - $r - 4), $cy)))
            $g.FillPolygon($brush, $pts)
        }
        3 {
            $pts = [System.Drawing.PointF[]]@(
                (New-Object System.Drawing.PointF($cx, ($cy - $r - 2))),
                (New-Object System.Drawing.PointF(($cx + $r + 2), ($cy + $r))),
                (New-Object System.Drawing.PointF(($cx - $r - 2), ($cy + $r))))
            $g.FillPolygon($brush, $pts)
        }
    }
}

function Draw-Overlay($g, [string]$title, [string]$line1, [string]$line2) {
    $g.FillRectangle($brushShade, 0, 0, $Cfg.Width, $Cfg.Height)
    $g.DrawString($title, $fontBig, $brushWhite, (New-Object System.Drawing.RectangleF(0, 200, $Cfg.Width, 70)), $sfCenter)
    $g.DrawString($line1, $fontMid, $brushWhite, (New-Object System.Drawing.RectangleF(0, 290, $Cfg.Width, 80)), $sfCenter)
    $g.DrawString($line2, $fontSmall, $brushGray, (New-Object System.Drawing.RectangleF(0, 380, $Cfg.Width, 80)), $sfCenter)
}

function Render([System.Drawing.Graphics]$g) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.FillRectangle($brushBg, 0, 0, $Cfg.Width, $Cfg.Height)

    $now   = Get-Now
    $left  = $Cfg.LaneLeft
    $lw    = $Cfg.LaneWidth
    $hitY  = $Cfg.HitY
    $r     = $Cfg.NoteRadius

    # Colonnes + séparateurs
    $g.FillRectangle($brushLane, $left, 0, $lw * $Cfg.LaneCount, $Cfg.Height)
    for ($i = 0; $i -le $Cfg.LaneCount; $i++) {
        $x = $left + $i * $lw
        $g.DrawLine($penLaneSep, $x, 0, $x, $Cfg.Height)
    }

    # Flash de colonne (appui récent) + cibles sur la ligne de frappe
    for ($i = 0; $i -lt $Cfg.LaneCount; $i++) {
        $cx  = $left + $i * $lw + $lw / 2
        $age = $now - $G.Flash[$i]
        if ($age -ge 0 -and $age -lt 150) {
            $alpha = [int](120 * (1 - $age / 150))
            $b = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $LaneColors[$i]))
            $g.FillRectangle($b, $left + $i * $lw, 0, $lw, $hitY + $r)
            $b.Dispose()
        }
        if ($G.Down[$i]) { Draw-Shape $g $i $cx $hitY ($r + 2) $brushWhite }
        # contour de la cible
        switch ($i) {
            0 { $g.DrawEllipse($lanePens[$i], $cx - $r, $hitY - $r, 2 * $r, 2 * $r) }
            1 { $g.DrawRectangle($lanePens[$i], $cx - $r, $hitY - $r, 2 * $r, 2 * $r) }
            default { }
        }
        if ($i -ge 2) {
            # contour approximé pour losange / triangle : on redessine la forme en fin de ligne
            $g.DrawLine($lanePens[$i], $cx - $r, $hitY + $r + 6, $cx + $r, $hitY + $r + 6)
        }
        $g.DrawString($LaneKeys[$i], $fontMid, $laneBrushes[$i], (New-Object System.Drawing.RectangleF(($left + $i * $lw), ($hitY + $r + 8), $lw, 30)), $sfCenter)
    }
    $g.DrawLine($penHitLine, $left, $hitY, $left + $lw * $Cfg.LaneCount, $hitY)

    # Notes : y = ligneFrappe - (tempsNote - tempsActuel) * vitesse
    if ($G.State -ne 'Menu') {
        $notes = $G.Notes
        for ($i = $G.First; $i -lt $notes.Count; $i++) {
            $n = $notes[$i]
            $y = $hitY - ($n.Time - $now) * $Cfg.SpeedPxMs
            if ($y -lt -$r) { break }                 # au-dessus de l'écran : les suivantes aussi
            if ($n.State -ne 0 -or $y -gt ($Cfg.Height + $r)) { continue }
            $cx = $left + $n.Lane * $lw + $lw / 2
            Draw-Shape $g $n.Lane $cx $y $r $laneBrushes[$n.Lane]
        }
    }

    # HUD
    $g.DrawString("Score : $($G.Score)", $fontMid, $brushWhite, 10, 8)
    if ($G.Combo -ge 2) {
        $mult = [math]::Min(1 + [math]::Floor($G.Combo / 10), 4)
        $g.DrawString("Combo $($G.Combo)  x$mult", $fontSmall, [System.Drawing.Brushes]::Gold, 10, 40)
    }
    $jAge = $now - $G.JTime
    if ($G.JText -ne '' -and $jAge -ge 0 -and $jAge -lt 600) {
        $b = New-Object System.Drawing.SolidBrush $G.JColor
        $g.DrawString($G.JText, $fontMid, $b, (New-Object System.Drawing.RectangleF(0, 520, $Cfg.Width, 40)), $sfCenter)
        $b.Dispose()
    }

    # Écrans
    switch ($G.State) {
        'Menu'     { Draw-Overlay $g 'BENEHERO' 'Appuie sur ESPACE pour jouer' "Touches : $($LaneKeys -join '  ')   |   Échap : pause" }
        'Paused'   { Draw-Overlay $g 'PAUSE' 'ESPACE pour reprendre' '' }
        'Finished' {
            $total = [math]::Max($G.Notes.Count, 1)
            $acc = [math]::Round(100 * ($G.Perfects + $G.Goods) / $total, 1)
            Draw-Overlay $g 'TERMINE' "Score : $($G.Score)   |   Précision : $acc %" `
                "Parfaits $($G.Perfects)  |  Bien $($G.Goods)  |  Ratés $($G.Misses)  |  Combo max $($G.MaxCombo)`n`nESPACE pour rejouer"
        }
    }
}
#endregion

#region Fenêtre -------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text            = 'BeneHero'
$form.ClientSize      = New-Object System.Drawing.Size($Cfg.Width, $Cfg.Height)
$form.StartPosition   = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox     = $false
$form.KeyPreview      = $true
$form.BackColor       = [System.Drawing.Color]::Black

$panel = New-Object BeneHeroPanel
$panel.Dock = 'Fill'
$form.Controls.Add($panel)

$panel.Add_Paint({ param($s, $e) Render $e.Graphics })

$form.Add_KeyDown({
    param($s, $e)
    $code = [int]$e.KeyCode
    if ($KeyMap.ContainsKey($code)) {
        $lane = $KeyMap[$code]
        if ($G.State -eq 'Playing' -and -not $G.Down[$lane]) {    # ignore l'auto-repeat Windows
            $G.Down[$lane] = $true
            Register-Press $lane
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true
        return
    }
    switch ($e.KeyCode) {
        'Space' {
            switch ($G.State) {
                'Menu'     { Start-Game }
                'Finished' { Start-Game }
                'Paused'   { Resume-Game }
            }
            $e.Handled = $true; $e.SuppressKeyPress = $true
        }
        'Escape' {
            if ($G.State -eq 'Playing') { Set-Pause }
            $e.Handled = $true; $e.SuppressKeyPress = $true
        }
    }
})

$form.Add_KeyUp({
    param($s, $e)
    $code = [int]$e.KeyCode
    if ($KeyMap.ContainsKey($code)) { $G.Down[$KeyMap[$code]] = $false }
})

# Pause automatique si la fenêtre perd le focus (sinon la partie continue sans le joueur)
$form.Add_Deactivate({ Set-Pause })

# Boucle de jeu : le Timer ne fait que rafraîchir ; la logique repose sur le Stopwatch
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 15
$timer.Add_Tick({
    if ($G.State -eq 'Playing') { Update-Game }
    $panel.Invalidate()
})
$timer.Start()

$form.Add_FormClosed({
    $timer.Stop(); $timer.Dispose()
    foreach ($o in @($fontBig, $fontMid, $fontSmall, $sfCenter, $brushBg, $brushLane, $brushShade, $penLaneSep, $penHitLine)) { $o.Dispose() }
    foreach ($o in $laneBrushes) { $o.Dispose() }
    foreach ($o in $lanePens) { $o.Dispose() }
})

[void]$form.ShowDialog()
#endregion
