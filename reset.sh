#!/bin/bash
# Setzt die Schulungsumgebung auf den Ausgangszustand zurück:
# Datenbank wird gelöscht und aus den CSV-Dateien neu aufgebaut (dauert ca. 30 Sekunden).
# Das Projekt dbt_ecommerce/ bleibt unverändert.
set -euo pipefail
cd "$(dirname "$0")"
docker compose down -v
docker compose up -d
echo "Warte auf die Datenbank ..."
until docker compose exec -T postgres psql -U "${POSTGRES_USER:-dbt_user}" -d "${POSTGRES_DB:-ecommerce}" -tAc "select 1 from raw._load_info" 2>/dev/null | grep -q 1; do
    sleep 3
done
echo "Fertig. Rohdaten sind neu geladen."
