<# ======================================================================
Titel:        NIC_Realtime_Monitor_GUI.ps1
Zweck:        Echtzeit-Überwachung aller aktiven NICs (PS 5.1, WinForms)
              - Summen oben (RX/TX Ø + Drops/Errors)
              - Pro NIC: Header "Name - IPv4" + letzte N Messpunkte
              - Alphabetische Sortierung, stabile Anzeige ohne Groups
Version:      1.2
Änderungen:   - Vollständiger Dark-Mode (OBS-ähnlich)
              - Konsistente Farbgebung ohne Zurückfallen auf Systemfarben
              - Stabile Spaltenüberschriften/erste Gruppe
              - Durchschnittsbildung über die letzten N Messpunkte je NIC
Hinweise:     Datei als UTF-8 mit BOM speichern. Start mit -STA.
              z.B.: powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\NIC_Realtime_Monitor_GUI.ps1
====================================================================== #>

#region Config

# Messfenster (Anzahl History-Einträge pro NIC, auch Grundlage für den Ø)
$HISTORY_WINDOW = 5     # auf 5 setzen, wenn über 5 s gemittelt werden soll

# Globale Zustände (bewusst im Skript-Scope)
$script:state   = @{}   # Name -> @{ Stats=<obj>; Time=<DateTime>; IPv4=<string> }
$script:history = @{}   # Name -> [System.Collections.ArrayList] mit Einträgen @{Ts; Rx; Tx; Rd; Re; Td; Alert}

# Imports & Styles
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void][System.Windows.Forms.Application]::EnableVisualStyles()

# OBS-ähnliche Dark-Mode-Farben
$C_FormBg  = [System.Drawing.ColorTranslator]::FromHtml("#1e1e1e")   # Haupt-Hintergrund
$C_PanelBg = [System.Drawing.ColorTranslator]::FromHtml("#2d2d2d")   # Header/Panel
$C_HeaderBg= [System.Drawing.ColorTranslator]::FromHtml("#3a3a3a")   # Spaltenkopf
$C_Text    = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")   # Primärtext
$C_Muted   = [System.Drawing.ColorTranslator]::FromHtml("#cfcfcf")   # Sekundärtext
$C_Accent  = [System.Drawing.ColorTranslator]::FromHtml("#00ff99")   # Grün (OK)
$C_Border  = [System.Drawing.ColorTranslator]::FromHtml("#444444")   # Linien
$C_Alert   = [System.Drawing.ColorTranslator]::FromHtml("#ff6666")   # Rot (Alarm)

# Durchschnittszeichen „Ø“ (als Unicode, robust gegen Encoding)
$SYMB_AVG = [char]0x00D8

#endregion


#region Helpers

function Get-ActiveNics {
    # Aktive, physische Adapter in stabiler Reihenfolge
    Get-NetAdapter |
        Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface } |
        Sort-Object ifIndex
}

function Get-IPv4ForNic($nic) {
    $ip = Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } |
          Select-Object -ExpandProperty IPAddress -First 1
    if ([string]::IsNullOrWhiteSpace($ip)) {
        $tmp = Get-NetIPAddress -InterfaceIndex $nic.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Select-Object -ExpandProperty IPAddress -First 1
        if ($tmp) { $ip = $tmp } else { $ip = "-" }
    }
    return $ip
}

function Ensure-NicState {
    param([Parameter(Mandatory)][string]$NicName)
    if (-not $script:state.ContainsKey($NicName)) {
        $stats = Get-NetAdapterStatistics -Name $NicName -ErrorAction SilentlyContinue
        if (-not $stats) { return } # Falls Adapter in der Zwischenzeit verschwand
        $script:state[$NicName] = @{
            Stats = $stats
            Time  = Get-Date
            IPv4  = "-"
        }
    }
    if (-not $script:history.ContainsKey($NicName)) {
        $script:history[$NicName] = New-Object System.Collections.ArrayList
    }
}

function Add-ToHistory {
    param(
        [Parameter(Mandatory)][string]$NicName,
        [Parameter(Mandatory)][hashtable]$Entry
    )
    Ensure-NicState -NicName $NicName
    $list = $script:history[$NicName]
    [void]$list.Add($Entry)
    while ($list.Count -gt $HISTORY_WINDOW) { $list.RemoveAt(0) }
}

function Get-NicAverages {
    <#
      Gibt je NIC den Ø (Rx/Tx) der letzten N Einträge und die Summen der Drops/Errors
      sowie ein Flag AnyAlert zurück.
      Rückgabewert: PSCustomObject @{ AvgRx; AvgTx; SumRd; SumRe; SumTd; AnyAlert }
    #>
    param([Parameter(Mandatory)][string]$NicName)

    if (-not $script:history.ContainsKey($NicName)) {
        return [pscustomobject]@{ AvgRx=0.0; AvgTx=0.0; SumRd=0; SumRe=0; SumTd=0; AnyAlert=$false }
    }

    $list = $script:history[$NicName]
    if ($list.Count -eq 0) {
        return [pscustomobject]@{ AvgRx=0.0; AvgTx=0.0; SumRd=0; SumRe=0; SumTd=0; AnyAlert=$false }
    }

    $recentCount = [math]::Min($HISTORY_WINDOW, $list.Count)
    $recent      = $list | Select-Object -Last $recentCount

    $rxVals = foreach($r in $recent){ [double]$r['Rx'] }
    $txVals = foreach($r in $recent){ [double]$r['Tx'] }
    $rdVals = foreach($r in $recent){ [int]   $r['Rd'] }
    $reVals = foreach($r in $recent){ [int]   $r['Re'] }
    $tdVals = foreach($r in $recent){ [int]   $r['Td'] }

    $avgRx = ($rxVals | Measure-Object -Average).Average
    $avgTx = ($txVals | Measure-Object -Average).Average
    if (-not $avgRx) { $avgRx = 0 }
    if (-not $avgTx) { $avgTx = 0 }

    $sumRd = [int](($rdVals | Measure-Object -Sum).Sum)
    $sumRe = [int](($reVals | Measure-Object -Sum).Sum)
    $sumTd = [int](($tdVals | Measure-Object -Sum).Sum)

    $anyAlert = $false
    if ($recent | Where-Object { $_['Alert'] }) { $anyAlert = $true }

    return [pscustomobject]@{
        AvgRx = [double]$avgRx
        AvgTx = [double]$avgTx
        SumRd = $sumRd
        SumRe = $sumRe
        SumTd = $sumTd
        AnyAlert = [bool]$anyAlert
    }
}

function Sync-Nics {
    $nics = Get-ActiveNics

    foreach ($nic in $nics) {
        Ensure-NicState -NicName $nic.Name
        $script:state[$nic.Name].IPv4 = Get-IPv4ForNic $nic
    }

    # Entfernte NICs bereinigen
    foreach ($name in @($script:state.Keys)) {
        if (-not ($nics | Where-Object { $_.Name -eq $name })) {
            [void]$script:state.Remove($name)
            [void]$script:history.Remove($name)
        }
    }
}

function Update-StatusText {
    $n = Get-ActiveNics
    $arr = @()
    foreach ($nic in $n) { $arr += ("{0} ({1})" -f $nic.Name, (Get-IPv4ForNic $nic)) }
    $lblStatus.Text = "Aktive NICs: " + ($arr -join "  |  ")
}

function Update-Summary {
    param(
        [double]$sumRx, [double]$sumTx,
        [int]$sumRxDrops, [int]$sumRxErr, [int]$sumTxDrops,
        [bool]$anyAlert
    )
    $lblSumRX.Text    = "RX ${SYMB_AVG}: {0:N2} Mbit/s" -f $sumRx
    $lblSumTX.Text    = "TX ${SYMB_AVG}: {0:N2} Mbit/s" -f $sumTx
    $lblSumDrops.Text = "Drops/Errors: {0} / {1} / {2}" -f $sumRxDrops, $sumRxErr, $sumTxDrops
    # Bei Alarm nur die Drops in Rot hervorheben – Panel-Farbe bleibt konstant dunkel
    if ($anyAlert) { $lblSumDrops.ForeColor = $C_Alert } else { $lblSumDrops.ForeColor = $C_Text }
}

#endregion


#region GUI

# Hauptfenster
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "NIC Live Monitor - Summen + {0}er-History je NIC" -f $HISTORY_WINDOW
$form.StartPosition = "CenterScreen"
$form.TopMost       = $true
$form.Size          = New-Object System.Drawing.Size(880, 520)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox   = $false
$form.BackColor     = $C_FormBg

# Statusband unten
$status    = New-Object System.Windows.Forms.StatusStrip
$lblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
[void]$status.Items.Add($lblStatus)
$status.SizingGrip = $false
$status.Dock = [System.Windows.Forms.DockStyle]::Bottom
$status.BackColor = $C_FormBg
$lblStatus.ForeColor = $C_Muted
$status.Renderer  = New-Object System.Windows.Forms.ToolStripProfessionalRenderer
$status.RenderMode= [System.Windows.Forms.ToolStripRenderMode]::System
$form.Controls.Add($status)

# Layout: 1 Spalte, 2 Zeilen
$layout = New-Object System.Windows.Forms.TableLayoutPanel
$layout.Dock        = [System.Windows.Forms.DockStyle]::Fill
$layout.ColumnCount = 1
$layout.RowCount    = 2
$layout.RowStyles.Add( (New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 72)) )
$layout.RowStyles.Add( (New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)) )
$form.Controls.Add($layout)

# Header-Panel (Summen + Button)
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock      = [System.Windows.Forms.DockStyle]::Fill
$headerPanel.BackColor = $C_PanelBg

$fontHeader = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$lblSumTitle = New-Object System.Windows.Forms.Label
$lblSumTitle.Text = "GESAMT (alle aktiven NICs):"
$lblSumTitle.Location = New-Object System.Drawing.Point(12, 10)
$lblSumTitle.AutoSize = $true
$lblSumTitle.Font = $fontHeader
$lblSumTitle.ForeColor = $C_Text

$lblSumRX = New-Object System.Windows.Forms.Label
$lblSumRX.Text = "RX: 0.00 Mbit/s"
$lblSumRX.Location = New-Object System.Drawing.Point(12, 36)
$lblSumRX.AutoSize = $true
$lblSumRX.ForeColor = $C_Text

$lblSumTX = New-Object System.Windows.Forms.Label
$lblSumTX.Text = "TX: 0.00 Mbit/s"
$lblSumTX.Location = New-Object System.Drawing.Point(160, 36)
$lblSumTX.AutoSize = $true
$lblSumTX.ForeColor = $C_Text

$lblSumDrops = New-Object System.Windows.Forms.Label
$lblSumDrops.Text = "Drops/Errors: 0 / 0 / 0"
$lblSumDrops.Location = New-Object System.Drawing.Point(300, 36)
$lblSumDrops.AutoSize = $true
$lblSumDrops.ForeColor = $C_Text

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text  = "Beenden"
$btnClose.Size  = New-Object System.Drawing.Size(90, 36)
$btnClose.Dock  = [System.Windows.Forms.DockStyle]::Right
$btnClose.Margin= New-Object System.Windows.Forms.Padding(0, 12, 12, 12)
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderColor        = $C_Border
$btnClose.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(80,80,80)
$btnClose.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$btnClose.BackColor = $C_PanelBg
$btnClose.ForeColor = $C_Text
$btnClose.Font      = New-Object System.Drawing.Font("Segoe UI", 9)
$btnClose.Add_Click({ $form.Close() })

$headerPanel.Controls.Add($btnClose)
$headerPanel.Controls.AddRange(@($lblSumTitle, $lblSumRX, $lblSumTX, $lblSumDrops))

# ListView
$lv = New-Object System.Windows.Forms.ListView
$lv.View        = [System.Windows.Forms.View]::Details
$lv.FullRowSelect = $true
$lv.GridLines   = $true
$lv.Font        = New-Object System.Drawing.Font("Consolas", 10)
$lv.ShowGroups  = $false
$lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$lv.UseCompatibleStateImageBehavior = $false
$lv.Dock        = [System.Windows.Forms.DockStyle]::Fill
$lv.BackColor   = $C_FormBg
$lv.ForeColor   = $C_Text

# Double-Buffering (nicht öffentliche Eigenschaft)
$doubleBufferProp = $lv.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'NonPublic,Instance')
$doubleBufferProp.SetValue($lv, $true, $null)

# Spalten
$lv.Columns.Clear()
$cols = @(
    @{Text = "NIC";        Width = 280 },
    @{Text = "Zeit";       Width =  90 },
    @{Text = "RX [Mbit/s]";Width = 110 },
    @{Text = "TX [Mbit/s]";Width = 110 },
    @{Text = "RX_Drops";   Width =  90 },
    @{Text = "RX_Errors";  Width =  90 },
    @{Text = "TX_Drops";   Width =  90 }
)
foreach ($c in $cols) { [void]$lv.Columns.Add($c.Text, $c.Width) }

# OwnerDraw: dunkler Spaltenkopf
$lv.OwnerDraw = $true
$lv.add_DrawColumnHeader({
    param($sender, $e)
    $g = $e.Graphics
    $g.FillRectangle((New-Object System.Drawing.SolidBrush $C_HeaderBg), $e.Bounds)

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Near'
    $sf.LineAlignment = 'Center'
    $g.DrawString($e.Header.Text, $sender.Font,
        (New-Object System.Drawing.SolidBrush $C_Text),
        $e.Bounds, $sf)

    $g.DrawLine((New-Object System.Drawing.Pen $C_Border),
        $e.Bounds.Left, $e.Bounds.Bottom - 1, $e.Bounds.Right, $e.Bounds.Bottom - 1)
})

$lv.add_DrawItem({ $_.DrawDefault = $true })
$lv.add_DrawSubItem({ $_.DrawDefault = $true })

# Restbreite auf die letzte Spalte legen
function Fit-LastColumn {
    if ($lv.Columns.Count -lt 1) { return }
    $sum = 0
    for ($i = 0; $i -lt $lv.Columns.Count - 1; $i++) { $sum += $lv.Columns[$i].Width }
    $rest = $lv.ClientSize.Width - $sum - 2
    if ($rest -gt 60) { $lv.Columns[$lv.Columns.Count - 1].Width = $rest }
}
Fit-LastColumn
$lv.Add_SizeChanged({ Fit-LastColumn })
$form.Add_Shown({ Fit-LastColumn })

# Headerzeilen (künstlich) nicht selektierbar
$lv.add_ItemSelectionChanged({
    param($sender,$e)
    if ($e.Item.Tag -eq 'hdr') { $e.Item.Selected = $false }
})

# Controls ins Layout
$layout.Controls.Add($headerPanel, 0, 0)
$layout.Controls.Add($lv,          0, 1)

#endregion


#region View / Build

function Rebuild-View {
    $lv.BeginUpdate()
    try {
        $lv.Visible = $false
        $lv.Items.Clear()

        $nicNames = (Get-ActiveNics | Select-Object -ExpandProperty Name) | Sort-Object

        if (-not $nicNames -or $nicNames.Count -eq 0) {
            $dummy = New-Object System.Windows.Forms.ListViewItem("")
            for ($i = 1; $i -lt $lv.Columns.Count; $i++) { [void]$dummy.SubItems.Add("") }
            [void]$lv.Items.Add($dummy)
        }

        # Gesamtsummen (über Ø der NICs) für den Kopf
        $sumRxM = 0.0; $sumTxM = 0.0
        $sumRxD = 0;   $sumRxE = 0;   $sumTxD = 0
        $anyAlert = $false

        foreach ($n in $nicNames) {

            # Header pro NIC
            $ip = if ($script:state.ContainsKey($n) -and $script:state[$n].IPv4) { $script:state[$n].IPv4 } else { "-" }
            $hdr = New-Object System.Windows.Forms.ListViewItem(("{0} - {1}" -f $n,$ip))
            for ($i = 1; $i -lt $lv.Columns.Count; $i++) { [void]$hdr.SubItems.Add("") }
            $hdr.Tag = 'hdr'
            $hdr.ForeColor = $C_Accent
            $hdr.Font = New-Object System.Drawing.Font($lv.Font, [System.Drawing.FontStyle]::Bold)
            [void]$lv.Items.Add($hdr)

            # History anzeigen (älteste -> jüngste)
            if (-not $script:history.ContainsKey($n)) { $script:history[$n] = New-Object System.Collections.ArrayList }
            foreach ($h in $script:history[$n]) {
                $it = New-Object System.Windows.Forms.ListViewItem("")       # NIC-Spalte leer
                [void]$it.SubItems.Add($h.Ts)                                # Zeit
                [void]$it.SubItems.Add(("{0:N2}" -f $h.Rx))                  # RX
                [void]$it.SubItems.Add(("{0:N2}" -f $h.Tx))                  # TX
                [void]$it.SubItems.Add($h.Rd.ToString())                     # RX_Drops
                [void]$it.SubItems.Add($h.Re.ToString())                     # RX_Errors
                [void]$it.SubItems.Add($h.Td.ToString())                     # TX_Drops
                $it.ForeColor = $(if ($h.Alert) { $C_Alert } else { $C_Accent })
                [void]$lv.Items.Add($it)
            }

            # Ø/Summen der letzten N Einträge für diese NIC
            $agg = Get-NicAverages -NicName $n
            $sumRxM += $agg.AvgRx
            $sumTxM += $agg.AvgTx
            $sumRxD += $agg.SumRd
            $sumRxE += $agg.SumRe
            $sumTxD += $agg.SumTd
            if ($agg.AnyAlert) { $anyAlert = $true }
        }

        if ($lv.Items.Count -gt 0) { $lv.EnsureVisible($lv.Items.Count - 1) }

        # Spaltenkopf/erste Zeile sauber zeichnen
        $lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Clickable
        $lv.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
        $lv.Visible = $true
        $lv.Refresh()

        # Summen/Ø aktualisieren
        Update-Summary $sumRxM $sumTxM $sumRxD $sumRxE $sumTxD $anyAlert
    }
    finally {
        $lv.EndUpdate()
    }
}

#endregion


#region Timer (1 s)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    if ($form.IsDisposed -or -not $form.Created) { return }
    try {
        Sync-Nics
        Update-StatusText

        $now  = Get-Date
        $nics = Get-ActiveNics

        foreach ($nic in $nics) {
            Ensure-NicState -NicName $nic.Name

            $curr = Get-NetAdapterStatistics -Name $nic.Name
            $prev = $script:state[$nic.Name]
            if (-not $prev) { continue }

            $dt = [math]::Max(0.0001, ($now - $prev.Time).TotalSeconds)

            # Bytes-Delta -> Mbit/s
            $rxBytes = $curr.ReceivedBytes - $prev.Stats.ReceivedBytes
            $txBytes = $curr.SentBytes     - $prev.Stats.SentBytes
            $rxMbit  = [math]::Round(($rxBytes * 8 / 1MB) / $dt, 2)
            $txMbit  = [math]::Round(($txBytes * 8 / 1MB) / $dt, 2)

            # Drops/Errors (Deltas)
            $rxDrops  = $curr.ReceivedDiscardedPackets - $prev.Stats.ReceivedDiscardedPackets
            $rxErrors = $curr.ReceivedPacketErrors     - $prev.Stats.ReceivedPacketErrors
            $txDrops  = $curr.OutboundDiscardedPackets - $prev.Stats.OutboundDiscardedPackets

            $alert = ($rxDrops -gt 0 -or $rxErrors -gt 0 -or $txDrops -gt 0)

            # History-Eintrag
            Add-ToHistory -NicName $nic.Name -Entry @{
                Ts    = $now.ToString("HH:mm:ss")
                Rx    = $rxMbit
                Tx    = $txMbit
                Rd    = [int]$rxDrops
                Re    = [int]$rxErrors
                Td    = [int]$txDrops
                Alert = [bool]$alert
            }

            # Merker aktualisieren
            $script:state[$nic.Name].Stats = $curr
            $script:state[$nic.Name].Time  = $now
        }

        Rebuild-View
    }
    catch { }
})

#endregion


#region Events & Start

$form.Add_Load({
    $form.BackColor        = $C_FormBg
    $headerPanel.BackColor = $C_PanelBg
    $lv.BackColor          = $C_FormBg
    $lv.ForeColor          = $C_Text
    $status.BackColor      = $C_FormBg
})

$form.Add_FormClosing({
    try { $timer.Stop(); $timer.Dispose() } catch { }
})
$form.Add_FormClosed({
    try { [System.Windows.Forms.Application]::Exit() } catch { }
})

Sync-Nics
Update-StatusText
$timer.Start()
[void]$form.ShowDialog()

#endregion
