-- Übung 9: Execution Plan für den Zugriff auf eine Bestellung.
-- Kompilieren mit `dbt compile --select explain_order_lookup`, das SQL aus
-- target/compiled/... in DBeaver (oder psql) ausführen und den Plan lesen.
explain (analyze, buffers)
select *
from {{ ref('fct_order_items') }}
where order_id = 104663
