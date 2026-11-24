<#
    La Beneroulette de l'Infortune - Proof of concept
    Roue de la fortune WinForms / GDI+ en PowerShell.

    Principe :
      1. Le résultat est tiré AVANT l'animation (tirage pondéré).
      2. On calcule l'angle final pour que le pointeur (en haut) tombe sur ce secteur.
      3. Un Timer interpole l'angle avec un easing "ease-out cubique".
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Panel avec double buffering (évite le flicker) -------------------------
if (-not ('DBPanel' -as [type])) {
    Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System.Windows.Forms;
public class DBPanel : Panel {
    public DBPanel() {
        this.SetStyle(ControlStyles.AllPaintingInWmPaint |
                      ControlStyles.UserPaint |
                      ControlStyles.OptimizedDoubleBuffer, true);
        this.UpdateStyles();
    }
}
"@
}

# --- Données : les secteurs de la roue ---------------------------------------
# Weight = poids de probabilité (indépendant de la taille visuelle du secteur)
$Segments = @(
    [pscustomobject]@{ Label = 'Un café offert';      Weight = 15; Color = '#E4572E' }
    [pscustomobject]@{ Label = 'Rien du tout';        Weight = 25; Color = '#6C757D' }
    [pscustomobject]@{ Label = 'Corvée de backup';    Weight = 15; Color = '#17BEBB' }
    [pscustomobject]@{ Label = 'Blague du jour';      Weight = 15; Color = '#FFC914' }
    [pscustomobject]@{ Label = 'JACKPOT !';           Weight = 2;  Color = '#76B041' }
    [pscustomobject]@{ Label = 'Reboot forcé';        Weight = 10; Color = '#9B5DE5' }
    [pscustomobject]@{ Label = 'Un compliment';       Weight = 13; Color = '#F15BB5' }
    [pscustomobject]@{ Label = 'Écran bleu (virtuel)'; Weight = 5; Color = '#2E86DE' }
)

$SegCount = $Segments.Count
$Step     = 360.0 / $SegCount          # taille visuelle identique pour chaque secteur
$Rand     = [System.Random]::new()

# --- État partagé entre les handlers -----------------------------------------
$script:State = @{
    Angle    = 0.0
    Start    = 0.0
    Target   = 0.0
    Duration = 4500        # ms
    Spinning = $false
    Index    = -1
    Sw       = [System.Diagnostics.Stopwatch]::new()
}

# --- Ressources GDI créées une seule fois ------------------------------------
$Brushes = foreach ($s in $Segments) {
    [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($s.Color))
}
$FontLabel = [System.Drawing.Font]::new('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$PenEdge   = [System.Drawing.Pen]::new([System.Drawing.Color]::White, 3)
$BrushText = [System.Drawing.Brushes]::White
$BrushHub  = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(40, 40, 48))
$BrushPtr  = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220, 30, 30))
$SfLabel   = [System.Drawing.StringFormat]::new()
$SfLabel.Alignment     = [System.Drawing.StringAlignment]::Far
$SfLabel.LineAlignment = [System.Drawing.StringAlignment]::Center

# --- Fonctions ---------------------------------------------------------------
function Get-WeightedIndex {
    $total = ($Segments | Measure-Object -Property Weight -Sum).Sum
    $roll  = $Rand.NextDouble() * $total
    $cum   = 0.0
    for ($i = 0; $i -lt $SegCount; $i++) {
        $cum += $Segments[$i].Weight
        if ($roll -lt $cum) { return $i }
    }
    return $SegCount - 1
}

function Get-TargetAngle([int]$Index, [double]$Current) {
    # Convention GDI+ : angle 0 = 3h, sens horaire. Le pointeur est en haut = 270°.
    # Le centre du secteur i est à R + (i + 0.5) * Step. On veut qu'il soit à 270°.
    $jitter = ($Rand.NextDouble() - 0.5) * $Step * 0.8       # reste dans le secteur
    $final  = 270.0 - (($Index + 0.5) * $Step) - $jitter
    $delta  = (($final - $Current) % 360.0 + 360.0) % 360.0  # rotation positive minimale
    $turns  = $Rand.Next(4, 7)                               # 4 à 6 tours complets
    return $Current + $turns * 360.0 + $delta
}

# --- Interface ---------------------------------------------------------------
$form = [System.Windows.Forms.Form]::new()
$form.Text          = 'La Beneroulette de l''Infortune'
$form.ClientSize    = [System.Drawing.Size]::new(820, 560)
$form.MinimumSize   = [System.Drawing.Size]::new(700, 500)
$form.StartPosition = 'CenterScreen'
$form.BackColor     = [System.Drawing.Color]::FromArgb(30, 30, 36)

$layout = [System.Windows.Forms.TableLayoutPanel]::new()
$layout.Dock        = 'Fill'
$layout.ColumnCount = 2
$layout.RowCount    = 1
[void]$layout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new('Percent', 100))
[void]$layout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new('Absolute', 250))
[void]$layout.RowStyles.Add([System.Windows.Forms.RowStyle]::new('Percent', 100))
$form.Controls.Add($layout)

$wheelPanel = [DBPanel]::new()
$wheelPanel.Dock = 'Fill'
$layout.Controls.Add($wheelPanel, 0, 0)

# Panneau de droite : bouton (haut), résultat, historique (reste)
$side = [System.Windows.Forms.Panel]::new()
$side.Dock    = 'Fill'
$side.Padding = [System.Windows.Forms.Padding]::new(10)
$layout.Controls.Add($side, 1, 0)

$lstHistory = [System.Windows.Forms.ListBox]::new()
$lstHistory.Dock        = 'Fill'
$lstHistory.BackColor   = [System.Drawing.Color]::FromArgb(45, 45, 54)
$lstHistory.ForeColor   = [System.Drawing.Color]::White
$lstHistory.BorderStyle = 'None'
$lstHistory.Font        = [System.Drawing.Font]::new('Segoe UI', 10)
$side.Controls.Add($lstHistory)

$lblHistory = [System.Windows.Forms.Label]::new()
$lblHistory.Text      = 'Historique'
$lblHistory.Dock      = 'Top'
$lblHistory.Height    = 28
$lblHistory.ForeColor = [System.Drawing.Color]::Silver
$lblHistory.Font      = [System.Drawing.Font]::new('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$side.Controls.Add($lblHistory)

$lblResult = [System.Windows.Forms.Label]::new()
$lblResult.Text      = 'Tentez votre malchance...'
$lblResult.Dock      = 'Top'
$lblResult.Height    = 110
$lblResult.TextAlign = 'MiddleCenter'
$lblResult.ForeColor = [System.Drawing.Color]::White
$lblResult.Font      = [System.Drawing.Font]::new('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$side.Controls.Add($lblResult)

$btnSpin = [System.Windows.Forms.Button]::new()
$btnSpin.Text      = 'LANCER LA ROUE'
$btnSpin.Dock      = 'Top'
$btnSpin.Height    = 55
$btnSpin.FlatStyle = 'Flat'
$btnSpin.BackColor = [System.Drawing.Color]::FromArgb(220, 30, 30)
$btnSpin.ForeColor = [System.Drawing.Color]::White
$btnSpin.Font      = [System.Drawing.Font]::new('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$btnSpin.FlatAppearance.BorderSize = 0
$side.Controls.Add($btnSpin)

# --- Dessin de la roue -------------------------------------------------------
$wheelPanel.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $w  = $sender.ClientSize.Width
    $h  = $sender.ClientSize.Height
    $r  = [Math]::Min($w, $h) / 2.0 - 30
    $cx = $w / 2.0
    $cy = $h / 2.0 + 12
    if ($r -lt 20) { return }

    # Roue : on translate au centre puis on tourne
    $g.TranslateTransform($cx, $cy)
    $g.RotateTransform([float]$script:State.Angle)

    $rect = [System.Drawing.RectangleF]::new(-$r, -$r, 2 * $r, 2 * $r)
    for ($i = 0; $i -lt $SegCount; $i++) {
        $g.FillPie($Brushes[$i], $rect.X, $rect.Y, $rect.Width, $rect.Height,
                   [float]($i * $Step), [float]$Step)
        $g.DrawPie($PenEdge, $rect.X, $rect.Y, $rect.Width, $rect.Height,
                   [float]($i * $Step), [float]$Step)
    }

    # Libellés : rotation vers le milieu du secteur, texte aligné vers l'extérieur
    for ($i = 0; $i -lt $SegCount; $i++) {
        $state = $g.Save()
        $g.RotateTransform([float](($i + 0.5) * $Step))
        $labelRect = [System.Drawing.RectangleF]::new($r * 0.28, -14, $r * 0.66, 28)
        $g.DrawString($Segments[$i].Label, $FontLabel, $BrushText, $labelRect, $SfLabel)
        $g.Restore($state)
    }

    # Moyeu central
    $g.FillEllipse($BrushHub, -22, -22, 44, 44)
    $g.ResetTransform()

    # Pointeur fixe en haut (triangle pointant vers le bas)
    $top = $cy - $r
    $pts = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new([float]($cx - 16), [float]($top - 20)),
        [System.Drawing.PointF]::new([float]($cx + 16), [float]($top - 20)),
        [System.Drawing.PointF]::new([float]$cx,        [float]($top + 16))
    )
    $g.FillPolygon($BrushPtr, $pts)
    $g.DrawPolygon([System.Drawing.Pens]::White, $pts)
})
$wheelPanel.Add_Resize({ $wheelPanel.Invalidate() })

# --- Animation ---------------------------------------------------------------
$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = 16

$timer.Add_Tick({
    $st = $script:State
    $t  = [Math]::Min(1.0, $st.Sw.ElapsedMilliseconds / [double]$st.Duration)
    $eased = 1.0 - [Math]::Pow(1.0 - $t, 3)          # ease-out cubique
    $st.Angle = $st.Start + ($st.Target - $st.Start) * $eased
    $wheelPanel.Invalidate()

    if ($t -ge 1.0) {
        $timer.Stop()
        $st.Sw.Stop()
        $st.Spinning = $false
        $st.Angle    = $st.Target % 360.0            # normalisation pour la prochaine rotation

        $win = $Segments[$st.Index]
        $lblResult.Text      = $win.Label
        $lblResult.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($win.Color)
        [void]$lstHistory.Items.Insert(0, ('{0:HH:mm:ss}  {1}' -f (Get-Date), $win.Label))
        [System.Media.SystemSounds]::Exclamation.Play()
        $btnSpin.Enabled = $true
        $wheelPanel.Invalidate()
    }
})

$btnSpin.Add_Click({
    $st = $script:State
    if ($st.Spinning) { return }
    $st.Spinning = $true
    $btnSpin.Enabled     = $false
    $lblResult.Text      = '...'
    $lblResult.ForeColor = [System.Drawing.Color]::White

    $st.Index  = Get-WeightedIndex                  # 1) on tire le lot
    $st.Start  = $st.Angle
    $st.Target = Get-TargetAngle $st.Index $st.Angle # 2) on calcule l'angle final
    $st.Sw.Restart()
    $timer.Start()                                    # 3) on anime
})

# --- Nettoyage ---------------------------------------------------------------
$form.Add_FormClosing({
    $timer.Stop()
    $timer.Dispose()
    foreach ($b in $Brushes) { $b.Dispose() }
    $FontLabel.Dispose(); $PenEdge.Dispose(); $BrushHub.Dispose(); $BrushPtr.Dispose(); $SfLabel.Dispose()
})

[void]$form.ShowDialog()
$form.Dispose()
