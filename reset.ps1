# Setzt die Schulungsumgebung auf den Ausgangszustand zurück (Windows PowerShell).
# Die Datenbank wird gelöscht und aus den CSV-Dateien neu aufgebaut (ca. 30 Sekunden).
# Das Projekt dbt_ecommerce/ bleibt unverändert.
#
# Aufruf im Ordner dbt-training:   .\reset.ps1
# Falls Skripte gesperrt sind:        powershell -ExecutionPolicy Bypass -File .\reset.ps1
Set-Location -Path $PSScriptRoot
docker compose down -v
docker compose up -d
Write-Host "Warte auf die Datenbank ..."
do {
    Start-Sleep -Seconds 3
    $ready = docker compose exec -T postgres psql -U dbt_user -d ecommerce -tAc "select 1 from raw._load_info" 2>$null
} until ($ready -match "1")
Write-Host "Fertig. Rohdaten sind neu geladen."
