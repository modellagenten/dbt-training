-- Lädt die CSV-Dateien aus /data nach raw.* und verschiebt optional alle Zeitstempel,
-- sodass die jüngste Bestellung "jetzt" ist (Umgebungsvariable TIME_SHIFT=true, Standard).
-- Bewusst als SQL-Datei (nicht als Shell-Skript): unabhängig von Ausführungsrechten und Zeilenenden,
-- damit die Umgebung unter Windows, macOS und Linux gleich startet.

\echo >> lade Rohdaten
\copy raw.distribution_centers from program 'gunzip -c /data/distribution_centers.csv.gz' with (format csv, header true)
\copy raw.users from program 'gunzip -c /data/users.csv.gz' with (format csv, header true)
\copy raw.products from program 'gunzip -c /data/products.csv.gz' with (format csv, header true)
\copy raw.orders from program 'gunzip -c /data/orders.csv.gz' with (format csv, header true)
\copy raw.order_items from program 'gunzip -c /data/order_items.csv.gz' with (format csv, header true)
\copy raw.inventory_items from program 'gunzip -c /data/inventory_items.csv.gz' with (format csv, header true)
\copy raw.events from program 'gunzip -c /data/events.csv.gz' with (format csv, header true)

\getenv env_time_shift TIME_SHIFT
\if :{?env_time_shift}
    \set time_shift :env_time_shift
\else
    \set time_shift true
\endif
select (:'time_shift' = 'true') as do_shift \gset

\if :do_shift
\echo >> verschiebe Zeitstempel relativ zu heute

create temp table _shift as
select now() - (select max(created_at) from raw.orders) as s;

update raw.users           set created_at = created_at + (select s from _shift);
update raw.orders          set created_at = created_at + (select s from _shift),
                               returned_at = returned_at + (select s from _shift),
                               shipped_at = shipped_at + (select s from _shift),
                               delivered_at = delivered_at + (select s from _shift);
update raw.order_items     set created_at = created_at + (select s from _shift),
                               shipped_at = shipped_at + (select s from _shift),
                               delivered_at = delivered_at + (select s from _shift),
                               returned_at = returned_at + (select s from _shift);
update raw.inventory_items set created_at = created_at + (select s from _shift),
                               sold_at = sold_at + (select s from _shift);
update raw.events          set created_at = created_at + (select s from _shift);

-- Folgezeitstempel (Versand, Lieferung, Retoure) liegen im Original bis zu ~10 Tage nach
-- der letzten Bestellung. Nach der Verschiebung dürfen sie nicht in der Zukunft liegen.
update raw.orders set shipped_at = least(shipped_at, now()), delivered_at = least(delivered_at, now()),
                      returned_at = least(returned_at, now())
where greatest(shipped_at, delivered_at, returned_at) > now();
update raw.order_items set shipped_at = least(shipped_at, now()), delivered_at = least(delivered_at, now()),
                           returned_at = least(returned_at, now())
where greatest(shipped_at, delivered_at, returned_at) > now();
update raw.inventory_items set sold_at = least(sold_at, now()) where sold_at > now();
update raw.inventory_items set created_at = now() where created_at > now();
update raw.order_items set created_at = now() where created_at > now();
update raw.events set created_at = now() where created_at > now();
update raw.users set created_at = now() where created_at > now();

insert into raw._load_info select now(), s, 'Zeitstempel relativ zu heute verschoben' from _shift;

\else
insert into raw._load_info values (now(), interval '0', 'Originalzeitstempel (Export 01/2024)');
\endif

analyze;
grant usage on schema raw to reporting;
\echo >> fertig
