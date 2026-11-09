#!/bin/bash
# Holt einen freigegebenen Lösungsstand (Git-Tag loesung-NN) aus dem Schulungs-Repository.
#
# Aufruf im Projektordner:   bash scripts/restore.sh 03
#
# Ersetzt models/, seeds/, macros/, tests/, snapshots/, analyses/, functions/ sowie
# selectors.yml, vars.yml, packages.yml, dbt_project.yml und profiles.yml durch den Stand
# der Musterlösung. Dateien in diesen Ordnern, die es in der Lösung nicht gibt, werden
# entfernt. Eigene Änderungen vorher committen! Danach "dbt deps" ausführen.
#
# Die Tags loesung-01, loesung-02, ... werden im Laufe der Schulung freigegeben.
set -euo pipefail

NR="${1:-}"
REMOTE="${SOLUTION_REMOTE:-https://github.com/modellagenten/dbt-training.git}"
DIRS=(models seeds macros tests snapshots analyses functions)
FILES=(selectors.yml vars.yml packages.yml dbt_project.yml profiles.yml)

if [ ! -f dbt_project.yml ]; then
    echo "Bitte im Projektordner aufrufen (dort, wo dbt_project.yml liegt)."
    exit 1
fi

if [ -z "$NR" ]; then
    echo "Aufruf: bash scripts/restore.sh <Nummer>   z. B. 03"
    echo "Bisher freigegebene Stände:"
    git ls-remote --tags --refs "$REMOTE" 'loesung-*' | sed 's#.*refs/tags/#  #' | sort
    exit 1
fi
TAG="loesung-$NR"

if [ -n "$(git status --porcelain -- .)" ]; then
    echo "Achtung: Es gibt uncommittete Änderungen. Bitte erst committen (git add -A && git commit -m ...)."
    exit 1
fi

# Tag in ein temporäres Repository holen - euer eigenes Repository bleibt unverändert
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git init -q --bare "$TMP/repo"
if ! git -C "$TMP/repo" fetch -q --depth 1 --no-tags "$REMOTE" "+refs/tags/$TAG:refs/tags/$TAG" 2>/dev/null; then
    echo "Stand $TAG ist (noch) nicht freigegeben oder das Repository ist nicht erreichbar."
    exit 1
fi
mkdir "$TMP/files"
git -C "$TMP/repo" archive "$TAG" | tar -x -C "$TMP/files"

# Das dbt-Projekt liegt im Tag entweder im Wurzelordner oder im Ordner dbt_ecommerce/
if [ -f "$TMP/files/dbt_project.yml" ]; then
    SRC="$TMP/files"
elif [ -f "$TMP/files/dbt_ecommerce/dbt_project.yml" ]; then
    SRC="$TMP/files/dbt_ecommerce"
else
    echo "Im Tag $TAG wurde kein dbt-Projekt gefunden."
    exit 1
fi

for d in "${DIRS[@]}"; do
    if [ -d "$SRC/$d" ]; then rm -rf "./$d"; cp -R "$SRC/$d" "./$d"; fi
done
for f in "${FILES[@]}"; do
    if [ -f "$SRC/$f" ]; then cp "$SRC/$f" "./$f"; fi
done
# package-lock.yml wird nicht übernommen - "dbt deps" erzeugt sie neu.

echo "Stand $TAG wiederhergestellt. Prüfen mit: git status   und danach   dbt deps && dbt build"
