# dbt-training

Schulungsumgebung für die Schulung **dbt Core Grundlagen**. Sie startet mit einem Befehl und enthält:

- **PostgreSQL 17** mit den E-Commerce-Rohdaten "thelook" im Schema `raw`
- einen **dbt-Container** mit dbt Core 1.12, dem Postgres-Adapter, Git und MetricFlow
- das **Projekt `dbt_ecommerce`** als Startpunkt für alle Übungen

Alles läuft lokal auf eurem Rechner. Ihr braucht keinen Cloud-Account und keine Python-Installation. Die Umgebung funktioniert unter **Windows, macOS und Linux**.

## Voraussetzungen

| Programm | Hinweis |
|----------|---------|
| Docker Desktop (oder Docker Engine + Compose v2) | mindestens 8 GB RAM empfohlen; unter Windows mit WSL 2 |
| Git | zum Klonen dieses Repositories |
| Visual Studio Code | mit der Erweiterung **Dev Containers** (`ms-vscode-remote.remote-containers`) |
| DBeaver | zum Ansehen der Tabellen |

## Schnellstart

```text
git clone https://github.com/modellagenten/dbt-training.git
cd dbt-training
```

| Schritt | Linux / macOS | Windows (PowerShell) |
|---------|---------------|----------------------|
| `.env` anlegen (einmalig: Zugangsdaten und Port) | `cp .env.example .env` | `Copy-Item .env.example .env` |

```text
docker compose up -d --build   # erster Start dauert einige Minuten (Image bauen, Daten laden)
docker compose ps              # beide Services müssen "running" bzw. "healthy" sein
```

Danach in VS Code den Ordner `dbt-training` öffnen und **"Reopen in Container"** wählen.
Im Terminal von VS Code läuft ihr jetzt im dbt-Container im Projektordner `dbt_ecommerce`:

```bash
dbt deps        # Packages installieren
dbt debug       # prüft Konfiguration und Datenbankverbindung
```

Ohne Dev Container funktioniert es genauso über ein Terminal:

```text
docker compose exec dbt bash
```

## Verbindung mit DBeaver

| Feld | Wert |
|------|------|
| Host | `localhost` |
| Port | `5432` (oder der Wert von `POSTGRES_PORT` in `.env`) |
| Datenbank | `ecommerce` |
| Benutzer / Passwort | `dbt_user` / `dbt_password` (aus `.env`) |

Die Rohdaten liegen im Schema `raw`. Alles, was dbt baut, erscheint in Schemas wie `dbt_dev_staging` und `dbt_dev_marts` (Target `dev`) bzw. `analytics_staging` und `analytics_marts` (Target `prod`).

## Hinweise für Windows

- Docker Desktop mit **WSL 2** verwenden (Einstellung *Use the WSL 2 based engine*).
- Den Ordner `dbt-training` nicht in OneDrive oder einem anderen synchronisierten Ordner ablegen; das stört die Container-Mounts.
- Alle dbt-, Git- und Python-Befehle der Übungen gebt ihr im Terminal des Dev Containers (Linux, bash) ein, dort ist alles identisch zu macOS und Linux. Auf dem Host nutzt ihr nur `docker compose`.
- Die Dateien sind für einheitliche Zeilenenden (LF) vorbereitet (`.gitattributes`). Wenn ihr Dateien mit einem Editor bearbeitet, speichert sie mit LF-Zeilenenden (VS Code zeigt das rechts unten an).

## Rohdaten

| Tabelle | Zeilen (ca.) |
|---------|--------------|
| `raw.users` | 100.000 |
| `raw.products` | 29.000 |
| `raw.orders` | 125.000 |
| `raw.order_items` | 182.000 |
| `raw.inventory_items` | 491.000 |
| `raw.distribution_centers` | 10 |
| `raw.events` | 10.000 (Stichprobe) |

Quelle: [Looker Ecommerce BigQuery Dataset (Kaggle)](https://www.kaggle.com/datasets/mustafakeser4/looker-ecommerce-bigquery-dataset), ein Export des Google-Datensatzes `thelook_ecommerce`.
Beim ersten Start werden **alle Zeitstempel so verschoben, dass die jüngste Bestellung "jetzt" ist** (siehe `postgres/init/02_load.sql`, abschaltbar mit `TIME_SHIFT=false` in `.env`). Dadurch funktionieren Source Freshness und zeitbasierte Filter wie gewünscht.

## Daten verändern (für die Übungen)

Das Skript `dbt_ecommerce/scripts/simulate.py` simuliert Änderungen in den Rohdaten. Aufruf im Container im Projektordner:

```bash
python scripts/simulate.py --step new-orders      # neue Bestellungen und Events
python scripts/simulate.py --step late-events     # Events mit altem Zeitstempel (Late Arriving Data)
python scripts/simulate.py --step status-change   # Statuswechsel von Bestellungen
python scripts/simulate.py --step delete-orders   # Bestellungen löschen (Hard Deletes)
python scripts/simulate.py --step stale --days 5  # alle Zeitstempel in die Vergangenheit schieben
python scripts/simulate.py --step status          # Überblick über den aktuellen Stand
```

## Lösungsstand übernehmen (wenn ihr bei einer Übung nicht weiterkommt)

Nach jeder Übung wird die Musterlösung als Git-Tag (`loesung-01`, `loesung-02`, ...) freigegeben. Mit dem Skript `dbt_ecommerce/scripts/restore.sh` holt ihr einen solchen Stand in euer Projekt. Aufruf im Container im Projektordner:

```bash
git add -A && git commit -m "mein Stand"   # eigene Arbeit vorher sichern
bash scripts/restore.sh                     # zeigt die bisher freigegebenen Stände
bash scripts/restore.sh 03                  # übernimmt den Stand loesung-03
dbt deps && dbt build
```

Das Skript ersetzt `models/`, `seeds/`, `macros/`, `tests/`, `snapshots/`, `analyses/`, `functions/` und die Projektdateien (`dbt_project.yml`, `packages.yml`, ...) durch den Lösungsstand. Dateien in diesen Ordnern, die es in der Lösung nicht gibt, werden entfernt. Mit `git status` und `git diff` seht ihr den Unterschied zu eurem Stand; mit `git restore . && git clean -fd .` macht ihr die Übernahme wieder rückgängig (zurück zu eurem letzten Commit).

## Hilfe, wenn etwas hängt

| Situation | Lösung |
|-----------|--------|
| Port 5432 ist belegt (lokale Postgres-Installation) | in `.env` `POSTGRES_PORT=5433` setzen, dann `docker compose up -d` |
| Daten sind kaputt oder verändert | auf dem Host `docker compose down -v`, danach `docker compose up -d` (baut die Datenbank neu auf; das Projekt bleibt unverändert). Alternativ `./reset.sh` (Linux/macOS) bzw. `.\reset.ps1` (Windows) |
| Container läuft nicht | `docker compose logs postgres` bzw. `docker compose logs dbt` |
| `dbt docs serve` nicht erreichbar | `dbt docs serve --host 0.0.0.0 --port 8080`, dann <http://localhost:8080> |
| Port 8080 ist belegt | in `docker-compose.yml` beim Service `dbt` die Portzuordnung ändern, z. B. `"8081:8080"` |
| Alles zurück auf Anfang | `docker compose down -v` (löscht auch die Datenbank) |

## Aufbau des Repositories

| Pfad | Inhalt |
|------|--------|
| `docker-compose.yml`, `.env.example` | Services und Zugangsdaten |
| `dbt/` | Dockerfile und Python-Pakete des dbt-Containers |
| `postgres/init/` | Schema (`01_schema.sql`) und Ladeskript (`02_load.sql`), laufen beim ersten Start |
| `data/` | Rohdaten als `.csv.gz` |
| `dbt_ecommerce/` | **euer Projekt** (Startpunkt der Übungen) |
| `.devcontainer/` | Konfiguration für VS Code Dev Containers |
| `reset.sh`, `reset.ps1` | Datenbank zurücksetzen (Linux/macOS bzw. Windows) |
