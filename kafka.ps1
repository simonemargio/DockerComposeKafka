<#
    ***************************************************************
    Author: Simone Margio

    All rights reserved. This code is released under the MIT License.

    Last release date: 09/02/2025
    ***************************************************************

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    provided to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
#>

# Funzione Execute-Command: esegue un comando e gestisce il controllo degli errori
function Execute-Command {
    param (
        # Comando da eseguire
        [string]$command,
        # Messaggio di errore da visualizzare in caso di fallimento
        [string]$errorMessage,
        # Se true, ignora il codice di uscita del comando
        [bool]$ignoreExitCode = $false
    )

    # Mostra il comando che verrà eseguito
    # Avvia il processo
    # Attende che il processo termini
    Write-Host "Esecuzione di: $command" -ForegroundColor Green
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -NoNewWindow -PassThru
    $process.WaitForExit()

    # Se non ignoriamo il codice di uscita e il comando ha fallito (ExitCode non è 0), visualizza un errore e termina lo script
    if (-not $ignoreExitCode -and $process.ExitCode -ne 0) {
        Write-Host "$errorMessage" -ForegroundColor Red
        exit 1
    }

    # Se ignoriamo il codice di uscita e il comando ha fallito, avvisa senza errore grave
    if ($ignoreExitCode -and $process.ExitCode -ne 0) {
        Write-Host "Il comando e' stato eseguito, ma non sono stati rilevati aggiornamenti." -ForegroundColor Yellow
    }
}

# Verifica se lo script è eseguito con privilegi di amministratore
if (-not [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Questo script deve essere eseguito come amministratore!" -ForegroundColor Red
    exit 1
}

# Verifica se WSL (Windows Subsystem for Linux) è già abilitato
$wslFeature = dism.exe /online /get-featureinfo /featurename:Microsoft-Windows-Subsystem-Linux | Select-String "State : Enabled"
if (-not $wslFeature) {
    Write-Host "Abilitazione di Windows Subsystem for Linux (WSL)" -ForegroundColor Green
    Execute-Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" "Errore nell'abilitazione di WSL!"
} else {
    Write-Host "WSL gia' abilitata." -ForegroundColor Yellow
}

# Verifica e aggiorna WSL, ignorando il codice di uscita
Write-Host "Verifica aggiornamenti per WSL" -ForegroundColor Green
Execute-Command "wsl --update" "Errore nell'aggiornamento di WSL!" $true

Write-Host "Installazione Ubuntu" -ForegroundColor Green
wsl --install -d Ubuntu-22.04

# Ottiene il percorso della directory corrente
# Definisce il percorso della cartella "kafka" come sottocartella della directory corrente
# Crea la cartella "kafka" se non esiste già
# Entra nella cartella "kafka"
$CurrentDir = Get-Location
$KafkaDir = Join-Path -Path $CurrentDir -ChildPath "kafkaDocker"
if (-not (Test-Path $KafkaDir)) {
    New-Item -ItemType Directory -Path $KafkaDir | Out-Null
}
Set-Location -Path $KafkaDir

# Scarica il file "docker-compose.yml" dal link specificato usando WSL
Write-Host "Scaricamento del file docker-compose.yml" -ForegroundColor Green
wsl bash -c 'wget -O docker-compose.yml https://github.com/simonemargio/DockerComposeKafka/raw/main/docker-compose.yml'

# Aggiornamento pacchetti di Ubuntu
Write-Host "Aggiornamento del sistema" -ForegroundColor Green
wsl bash -c 'sudo apt-get update && sudo apt-get -y upgrade'

# Verifica e installa Docker Compose se non è già installato
$dockerComposeInstalled = wsl bash -c "docker-compose --version 2>/dev/null"
if (-not $dockerComposeInstalled) {
    Write-Host "Installazione di Docker Compose" -ForegroundColor Green
    Execute-Command "wsl bash -c 'sudo apt -y install docker-compose'" "Errore nell'installazione di Docker Compose!"
} else {
    Write-Host "Docker Compose e' gia' installato." -ForegroundColor Yellow
}

# Scarica il file di script "kafka.sh" per gestire il container
Write-Host "Scaricamento del file di script" -ForegroundColor Green
wsl bash -c 'wget -O kafka.sh https://github.com/simonemargio/DockerComposeKafka/raw/main/kafka.sh'