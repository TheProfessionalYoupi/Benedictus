$Text = @'
检测到问题，Windows 已被锁定以防止对计算机造成损害。

CRITICAL_不锈钢_FAILED

如果这是您第一次看到此停止错误屏幕，请不要重新启动计算机。如果此屏幕出现，请考虑执行以下步骤：

请检查这是否来自一位 不锈钢 同事的玩笑（已正确安装）。
如果这是新安装，请向他们寻求解决方案，或询问您可能需要的任何 Windows 密钥。

如果问题仍然存在，请禁用或移除任何新安装的硬件或软件。禁用 BIOS 内存选项（例如缓存或影子存储）。

技术信息：

*** STOP: 0x0000DEAD (0x00000000, 0x00000000, 0x00000000, 0x00000000)

按下 键以重新启动系统，或等待管理员恢复正常操作。
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
    $Form.BackColor = "#8B0000"
    $Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor

    # ➜ Placer le Form sur l'écran correspondant
    $Form.StartPosition = 'Manual'
    $Form.Bounds = $Screen.Bounds

    $Form.Show()
}

# ➜ Nécessaire pour que les fenêtres restent ouvertes
[System.Windows.Forms.Application]::Run()