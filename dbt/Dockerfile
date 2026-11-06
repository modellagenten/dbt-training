FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends git jq postgresql-client curl less nano ca-certificates \
 && apt-get clean

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# Nicht-root-Benutzer (UID 1000 passt zu den meisten Linux-Hosts)
RUN useradd -m -u 1000 -s /bin/bash dbt \
 && mkdir -p /workspace && chown dbt:dbt /workspace
USER dbt
RUN git config --global --add safe.directory '*' \
 && git config --global init.defaultBranch main \
 && git config --global user.name "Teilnehmer:in" \
 && git config --global user.email "teilnehmer@schulung.local"

WORKDIR /workspace/dbt_ecommerce
CMD ["sleep", "infinity"]
