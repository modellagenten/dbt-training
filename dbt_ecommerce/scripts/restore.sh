#!/bin/bash
# Holt einen freigegebenen Lösungsstand (Git-Tag loesung-NN) aus dem Schulungs-Repository.
#
# Aufruf im Projektordner:   bash scripts/restore.sh 03
#
# Ersetzt models/, seeds/, macros/, tests/, snapshots/, analyses/, functions/ sowie
# selectors.yml, vars.yml, packages.yml, dbt_project.yml, profiles.yml und .gitignore
# durch den Stand der Musterlösung. Dateien in diesen Ordnern, die es in der Lösung nicht
# gibt, werden entfernt. Eigene Änderungen vorher committen! Danach "dbt deps" ausführen.
#
# Die Tags loesung-01, loesung-02, ... werden im Laufe der Schulung freigegeben.
set -euo pipefail

NR="${1:-}"
REMOTE="${SOLUTION_REMOTE:-https://github.com/modellagenten/dbt-training.git}"
PATHS=(models seeds macros tests snapshots analyses functions
       selectors.yml vars.yml packages.yml dbt_project.yml profiles.yml .gitignore)

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

if ! git fetch -q --no-tags "$REMOTE" "+refs/tags/$TAG:refs/tags/$TAG" 2>/dev/null; then
    echo "Stand $TAG ist (noch) nicht freigegeben oder das Repository ist nicht erreichbar."
    exit 1
fi

# nur Pfade übernehmen, die es im Lösungsstand gibt
EXIST=()
for p in "${PATHS[@]}"; do
    if git cat-file -e "$TAG:./$p" 2>/dev/null; then EXIST+=("$p"); fi
done
if [ ${#EXIST[@]} -eq 0 ]; then
    echo "Im Tag $TAG wurde kein dbt-Projekt in diesem Ordner gefunden."
    exit 1
fi

# git restore übernimmt den Stand des Tags; Dateien, die dort fehlen, werden entfernt
git restore --source="$TAG" --worktree -- "${EXIST[@]}"
# package-lock.yml wird nicht übernommen - "dbt deps" erzeugt sie neu.

echo "Stand $TAG wiederhergestellt. Prüfen mit: git status   und danach   dbt deps && dbt build"
