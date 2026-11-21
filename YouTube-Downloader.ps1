Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$yt = Get-Command yt-dlp.exe -ErrorAction SilentlyContinue
if (-not $yt) { $yt = Get-Command yt-dlp -ErrorAction SilentlyContinue }
if (-not $yt) {
    [Windows.Forms.MessageBox]::Show("No encuentro yt-dlp. Instalalo primero con:`r`n`r`nwinget install yt-dlp.yt-dlp","YouTube Downloader")
    exit
}
$ytPath = $yt.Source

# Last used folder is remembered between runs
$settingsDir  = Join-Path $env:APPDATA "YouTube-Downloader"
$settingsFile = Join-Path $settingsDir "ultima-carpeta.txt"

function Get-LastFolder {
    if (Test-Path $settingsFile) {
        $saved = (Get-Content $settingsFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ($saved) { $saved = $saved.Trim() }
        if ($saved -and (Test-Path $saved)) { return $saved }
    }
    return [Environment]::GetFolderPath("MyVideos")
}
function Save-LastFolder($path) {
    try {
        New-Item -ItemType Directory -Force $settingsDir | Out-Null
        Set-Content -Path $settingsFile -Value $path -Encoding UTF8
    } catch { }  # not critical: next run just falls back to Videos
}

# ---------- Colors and fonts ----------
$cBg      = [Drawing.Color]::FromArgb(243,245,249)
$cCard    = [Drawing.Color]::White
$cHeader  = [Drawing.Color]::FromArgb(24,26,32)
$cAccent  = [Drawing.Color]::FromArgb(230,33,23)
$cAccentH = [Drawing.Color]::FromArgb(200,25,18)
$cText    = [Drawing.Color]::FromArgb(30,32,38)
$cMuted   = [Drawing.Color]::FromArgb(110,115,125)
$cBorder  = [Drawing.Color]::FromArgb(222,226,232)

$fBase  = New-Object Drawing.Font("Segoe UI",10)
$fLabel = New-Object Drawing.Font("Segoe UI Semibold",9)
$fTitle = New-Object Drawing.Font("Segoe UI Semibold",17)
$fSub   = New-Object Drawing.Font("Segoe UI",9.5)
$fBtn   = New-Object Drawing.Font("Segoe UI Semibold",10.5)

# ---------- Window ----------
$form = New-Object Windows.Forms.Form
$form.Text = "YouTube Downloader"
$form.ClientSize = New-Object Drawing.Size(560,600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $cBg
$form.Font = $fBase
$form.ForeColor = $cText

# Header
$header = New-Object Windows.Forms.Panel
$header.Dock = "Top"
$header.Height = 78
$header.BackColor = $cHeader
$form.Controls.Add($header)

$logo = New-Object Windows.Forms.Label
$logo.Text = [char]0x25B6
$logo.Font = New-Object Drawing.Font("Segoe UI Symbol",16)
$logo.ForeColor = [Drawing.Color]::White
$logo.BackColor = $cAccent
$logo.TextAlign = "MiddleCenter"
$logo.Location = New-Object Drawing.Point(24,18)
$logo.Size = New-Object Drawing.Size(52,42)
$header.Controls.Add($logo)

$title = New-Object Windows.Forms.Label
$title.Text = "YouTube Downloader"
$title.Font = $fTitle
$title.ForeColor = [Drawing.Color]::White
$title.Location = New-Object Drawing.Point(88,12)
$title.AutoSize = $true
$header.Controls.Add($title)

$subtitle = New-Object Windows.Forms.Label
$subtitle.Text = "Bajá videos en MP4 o audio en MP3"
$subtitle.Font = $fSub
$subtitle.ForeColor = [Drawing.Color]::FromArgb(170,175,185)
$subtitle.Location = New-Object Drawing.Point(90,46)
$subtitle.AutoSize = $true
$header.Controls.Add($subtitle)

# White card that holds the inputs
$card = New-Object Windows.Forms.Panel
$card.Location = New-Object Drawing.Point(20,96)
$card.Size = New-Object Drawing.Size(520,330)
$card.BackColor = $cCard
$card.Add_Paint({
    $pen = New-Object Drawing.Pen($cBorder)
    $_.Graphics.DrawRectangle($pen,0,0,$card.Width-1,$card.Height-1)
    $pen.Dispose()
})
$form.Controls.Add($card)

function Add-Label($text,$x,$y,$w=470) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text
    $l.Font = $fLabel
    $l.ForeColor = $cMuted
    $l.Location = New-Object Drawing.Point($x,$y)
    $l.Size = New-Object Drawing.Size($w,20)
    $card.Controls.Add($l)
}
function Add-Combo($items,$x,$y,$w) {
    $c = New-Object Windows.Forms.ComboBox
    $c.Location = New-Object Drawing.Point($x,$y)
    $c.Size = New-Object Drawing.Size($w,28)
    $c.DropDownStyle = "DropDownList"
    $c.FlatStyle = "Flat"
    [void]$c.Items.AddRange([string[]]$items)
    $c.SelectedIndex = 0
    $card.Controls.Add($c)
    return $c
}
function New-FlatButton($text,$x,$y,$w,$h,$parent,$primary=$false) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object Drawing.Point($x,$y)
    $b.Size = New-Object Drawing.Size($w,$h)
    $b.FlatStyle = "Flat"
    $b.Cursor = [Windows.Forms.Cursors]::Hand
    if ($primary) {
        $b.Font = $fBtn
        $b.BackColor = $cAccent
        $b.ForeColor = [Drawing.Color]::White
        $b.FlatAppearance.BorderSize = 0
        $b.FlatAppearance.MouseOverBackColor = $cAccentH
    } else {
        $b.BackColor = $cCard
        $b.ForeColor = $cText
        $b.FlatAppearance.BorderColor = $cBorder
        $b.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(236,239,244)
    }
    $parent.Controls.Add($b)
    return $b
}

# URL
Add-Label "ENLACE DE YOUTUBE" 20 18
$url = New-Object Windows.Forms.TextBox
$url.Location = New-Object Drawing.Point(20,42)
$url.Size = New-Object Drawing.Size(380,28)
$url.BorderStyle = "FixedSingle"
$card.Controls.Add($url)
$paste = New-FlatButton "Pegar" 410 41 90 28 $card
$paste.Add_Click({
    if ([Windows.Forms.Clipboard]::ContainsText()) { $url.Text = [Windows.Forms.Clipboard]::GetText().Trim() }
})

# Format + qualities
Add-Label "FORMATO" 20 88
$format = Add-Combo @("MP4 - Video con audio","MP3 - Solo audio") 20 112 480

Add-Label "CALIDAD DE VIDEO" 20 158 230
$quality = Add-Combo @("1080p","720p","480p","360p","1440p","4K - 2160p","Mejor disponible") 20 182 230

Add-Label "CALIDAD DE AUDIO (MP3)" 270 158 230
$audio = Add-Combo @("320 kbps","256 kbps","192 kbps","128 kbps") 270 182 230

# Only the quality that applies to the chosen format is editable
$format.Add_SelectedIndexChanged({
    $isMp3 = ($format.SelectedIndex -eq 1)
    $quality.Enabled = -not $isMp3
    $audio.Enabled = $isMp3
})
$audio.Enabled = $false

# Folder
Add-Label "CARPETA DE DESTINO" 20 228
$folder = New-Object Windows.Forms.TextBox
$folder.Location = New-Object Drawing.Point(20,252)
$folder.Size = New-Object Drawing.Size(380,28)
$folder.BorderStyle = "FixedSingle"
$folder.Text = Get-LastFolder
$card.Controls.Add($folder)

$browse = New-FlatButton "Examinar..." 410 251 90 28 $card
$browse.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $folder.Text
    if ($dialog.ShowDialog() -eq "OK") {
        $folder.Text = $dialog.SelectedPath
        Save-LastFolder $folder.Text
    }
})

$hint = New-Object Windows.Forms.Label
$hint.Text = "Se recuerda la última carpeta que usaste."
$hint.Font = $fSub
$hint.ForeColor = $cMuted
$hint.Location = New-Object Drawing.Point(20,288)
$hint.Size = New-Object Drawing.Size(480,20)
$card.Controls.Add($hint)

# Progress area
$progress = New-Object Windows.Forms.ProgressBar
$progress.Location = New-Object Drawing.Point(20,442)
$progress.Size = New-Object Drawing.Size(520,14)
$progress.Style = "Continuous"
$form.Controls.Add($progress)

$status = New-Object Windows.Forms.Label
$status.Text = "Listo para descargar"
$status.ForeColor = $cMuted
$status.Location = New-Object Drawing.Point(20,462)
$status.Size = New-Object Drawing.Size(520,40)
$form.Controls.Add($status)

$download   = New-FlatButton "DESCARGAR" 20 510 330 44 $form $true
$openFolder = New-FlatButton "Abrir carpeta" 360 510 180 44 $form
$form.AcceptButton = $download

$footer = New-Object Windows.Forms.Label
$footer.Text = "Hecho con IA  ·  Usa yt-dlp y FFmpeg"
$footer.Font = New-Object Drawing.Font("Segoe UI",8.5)
$footer.ForeColor = $cMuted
$footer.TextAlign = "MiddleCenter"
$footer.Location = New-Object Drawing.Point(20,568)
$footer.Size = New-Object Drawing.Size(520,20)
$form.Controls.Add($footer)

$openFolder.Add_Click({
    if (Test-Path $folder.Text) { Start-Process explorer.exe $folder.Text }
})

# ---------- Download logic ----------
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 500
$script:proc = $null
$script:outFile = $null
$script:errFile = $null
$script:cancelled = $false

function Set-Idle {
    $download.Text = "DESCARGAR"
    $download.BackColor = $cAccent
    $download.FlatAppearance.MouseOverBackColor = $cAccentH
    foreach ($c in @($url,$paste,$format,$folder,$browse)) { $c.Enabled = $true }
    $quality.Enabled = ($format.SelectedIndex -eq 0)
    $audio.Enabled = ($format.SelectedIndex -eq 1)
}
function Set-Busy {
    $download.Text = "CANCELAR"
    $download.BackColor = [Drawing.Color]::FromArgb(90,95,105)
    $download.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(70,75,85)
    foreach ($c in @($url,$paste,$format,$quality,$audio,$folder,$browse)) { $c.Enabled = $false }
}

$timer.Add_Tick({
    if (-not $script:proc) { return }

    $content = Get-Content $script:outFile -Raw -ErrorAction SilentlyContinue
    if ($content) {
        $found = [regex]::Matches($content,'\[download\]\s+(\d{1,3}(?:\.\d+)?)%[^\r\n]*')
        if ($found.Count -gt 0) {
            $last = $found[$found.Count-1]
            $pct = [math]::Min(100,[math]::Max(0,[int][double]$last.Groups[1].Value))
            $progress.Value = $pct
            $status.Text = "Descargando... " + ($last.Value -replace '^\[download\]\s+','')
        }
        if ($content -match '\[(Merger|ExtractAudio)\]') { $status.Text = "Procesando con FFmpeg..." }
    }

    if ($script:proc.HasExited) {
        $timer.Stop()
        Set-Idle
        if ($script:cancelled) {
            $progress.Value = 0
            $status.Text = "Descarga cancelada"
        } elseif ($script:proc.ExitCode -eq 0) {
            $progress.Value = 100
            $status.Text = "¡Descarga terminada!"
            [Windows.Forms.MessageBox]::Show("La descarga terminó correctamente.","YouTube Downloader")
        } else {
            $status.Text = "Ocurrió un error"
            $err = Get-Content $script:errFile -Raw -ErrorAction SilentlyContinue
            if (-not $err) { $err = $content }
            [Windows.Forms.MessageBox]::Show("No se pudo completar la descarga:`r`n`r`n$err","YouTube Downloader")
        }
        $script:proc = $null
    }
})

$download.Add_Click({
    # While downloading, the same button cancels
    if ($script:proc -and -not $script:proc.HasExited) {
        $script:cancelled = $true
        $script:proc.Kill()
        $status.Text = "Cancelando..."
        return
    }

    $link = $url.Text.Trim()
    if ($link -notmatch '^https?://') {
        [Windows.Forms.MessageBox]::Show("Pegá un enlace válido de YouTube.","YouTube Downloader")
        return
    }
    if (-not (Test-Path $folder.Text)) {
        [Windows.Forms.MessageBox]::Show("La carpeta de destino no existe.","YouTube Downloader")
        return
    }
    if (-not (Get-Command ffmpeg.exe -ErrorAction SilentlyContinue)) {
        [Windows.Forms.MessageBox]::Show("No encuentro FFmpeg. Instalalo con:`r`n`r`nwinget install Gyan.FFmpeg","YouTube Downloader")
        return
    }

    Save-LastFolder $folder.Text

    $argsList = @("--no-playlist","--newline","-P",$folder.Text)

    if ($format.SelectedIndex -eq 1) {
        $bitrate = $audio.SelectedItem -replace ' kbps',''
        $argsList += @("-x","--audio-format","mp3","--audio-quality","${bitrate}K")
    } else {
        $height = switch ($quality.SelectedIndex) {
            0 { "1080" }
            1 { "720" }
            2 { "480" }
            3 { "360" }
            4 { "1440" }
            5 { "2160" }
            default { "99999" }
        }
        # Prefer H.264 + AAC so the MP4 plays with sound in Windows' default player
        $argsList += @("-f","bv*+ba/b","-S","res:${height},vcodec:h264,acodec:m4a","--merge-output-format","mp4")
    }

    $argsList += $link

    $quoted = ($argsList | ForEach-Object {
        # double trailing backslashes so a path like C:\ doesn't escape the closing quote
        '"' + (($_ -replace '"','\"') -replace '(\\+)$','$1$1') + '"'
    }) -join ' '

    $temp = [IO.Path]::GetTempPath()
    $script:outFile = Join-Path $temp "yt-downloader-out.txt"
    $script:errFile = Join-Path $temp "yt-downloader-err.txt"
    Remove-Item $script:outFile,$script:errFile -Force -ErrorAction SilentlyContinue

    $script:cancelled = $false
    $progress.Value = 0
    $status.Text = "Iniciando descarga..."
    Set-Busy

    try {
        $script:proc = Start-Process -FilePath $ytPath -ArgumentList $quoted `
            -NoNewWindow -PassThru `
            -RedirectStandardOutput $script:outFile `
            -RedirectStandardError $script:errFile
        # Touching .Handle is required or ExitCode stays empty and every download looks failed
        $null = $script:proc.Handle
        $timer.Start()
    } catch {
        Set-Idle
        $status.Text = "No se pudo iniciar"
        [Windows.Forms.MessageBox]::Show($_.Exception.Message,"YouTube Downloader")
    }
})

$form.Add_FormClosing({
    if ($script:proc -and -not $script:proc.HasExited) { $script:proc.Kill() }
})

[void]$form.ShowDialog()
