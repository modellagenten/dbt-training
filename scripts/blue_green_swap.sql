-- Blue/Green-Deployment für PostgreSQL (Übung 8, Zusatz)
-- 1. dbt build --target prod_blue          -> baut analytics_blue, analytics_blue_staging, ...
-- 2. Tests laufen lassen (im Build enthalten)
-- 3. Dieses Skript ausführen: Der Tausch ist atomar (Postgres kennt transaktionales DDL)
--    psql -h postgres -U $POSTGRES_USER -d ecommerce -f scripts/blue_green_swap.sql
-- Rollback: Die Schemas *_old wieder zurückbenennen (analog, umgekehrte Richtung).
-- Aufräumen nach erfolgreicher Prüfung: drop schema analytics_old, analytics_old_staging,
--                                       analytics_old_marts, analytics_old_snapshots cascade;
begin;
alter schema analytics rename to analytics_old;
alter schema analytics_staging rename to analytics_old_staging;
alter schema analytics_marts rename to analytics_old_marts;
alter schema analytics_snapshots rename to analytics_old_snapshots;

alter schema analytics_blue rename to analytics;
alter schema analytics_blue_staging rename to analytics_staging;
alter schema analytics_blue_marts rename to analytics_marts;
alter schema analytics_blue_snapshots rename to analytics_snapshots;
commit;
