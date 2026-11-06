#!/bin/bash
# Holt den Stand einer Übungslösung aus der Musterlösung (Ordner /solution).
#
# Aufruf im Projektordner:   bash scripts/restore.sh 03
#
# Kopiert models/, seeds/, macros/, tests/, snapshots/, analyses/, functions/, selectors.yml,
# vars.yml, packages.yml, dbt_project.yml, profiles.yml und .gitignore aus dem Git-Tag loesung-03
# in euer Projekt. Danach "dbt deps" ausführen.
# Eure eigenen Dateien in diesen Ordnern werden dabei ÜBERSCHRIEBEN - committet vorher!
#
# Voraussetzung: Die Musterlösung (ein Git-Repository mit den Tags loesung-01 bis loesung-10)
# liegt im Ordner .solution des Repositories.
set -euo pipefail

NR="${1:-}"
SOLUTION="${SOLUTION_DIR:-/solution}"

if ! git -C "$SOLUTION" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Keine Musterlösung gefunden (erwartet im Ordner .solution des Repositories)."
    exit 1
fi
if [ -z "$NR" ]; then
    echo "Aufruf: bash scripts/restore.sh <Nummer>   z. B. 03"
    echo "Verfügbare Stände:"; git -C "$SOLUTION" tag --list 'loesung-*' | sed 's/^/  /'
    exit 1
fi
TAG="loesung-$NR"
git -C "$SOLUTION" rev-parse -q --verify "refs/tags/$TAG" >/dev/null || { echo "Tag $TAG nicht gefunden."; exit 1; }

if [ -n "$(git status --porcelain -- . 2>/dev/null)" ]; then
    echo "Achtung: Es gibt uncommittete Änderungen. Bitte erst committen (git add -A && git commit -m ...)."
    exit 1
fi

TMP="$(mktemp -d)"
git -C "$SOLUTION" archive "$TAG" | tar -x -C "$TMP"
for d in models seeds macros tests snapshots analyses functions; do
    if [ -d "$TMP/$d" ]; then rm -r "./$d" 2>/dev/null || true; cp -R "$TMP/$d" "./$d"; fi
done
for f in selectors.yml vars.yml packages.yml dbt_project.yml profiles.yml .gitignore; do
    [ -f "$TMP/$f" ] && cp "$TMP/$f" "./$f"
done
# Hinweis: package-lock.yml wird nicht kopiert - "dbt deps" erzeugt sie neu.
rm -r "$TMP"
echo "Stand $TAG wiederhergestellt. Prüfen mit: git status   und   dbt build"
