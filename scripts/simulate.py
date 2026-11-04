#!/usr/bin/env python3
"""Simuliert Änderungen in den Rohdaten (raw.*) für die Übungen.

Aufruf (im dbt-Container, im Projektordner):

    python scripts/simulate.py --step new-orders
    python scripts/simulate.py --step late-events
    python scripts/simulate.py --step status-change
    python scripts/simulate.py --step delete-orders
    python scripts/simulate.py --step stale --days 5
    python scripts/simulate.py --step status

Schritte:
  new-orders      neue Bestellungen + Positionen + Events (Zeitstempel: letzte Stunden)
  late-events     Events mit ALTEM Zeitstempel, die erst jetzt "ankommen" (Late Arriving Data)
  status-change   Statuswechsel: Processing -> Shipped -> Complete -> Returned
  delete-orders   löscht Bestellungen samt Positionen (Hard Deletes)
  stale           verschiebt ALLE Zeitstempel um --days Tage in die Vergangenheit (Freshness-Warnung)
  status          zeigt Zeilenzahlen, Status-Verteilung und jüngste Zeitstempel
"""
import argparse
import os
import sys

import psycopg2


def connect():
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "postgres"),
        port=int(os.environ.get("DB_PORT", 5432)),  # im Container immer 5432
        dbname=os.environ.get("POSTGRES_DB", "ecommerce"),
        user=os.environ.get("POSTGRES_USER", "dbt_user"),
        password=os.environ.get("POSTGRES_PASSWORD", "dbt_password"),
    )


def new_orders(cur, count):
    cur.execute("select coalesce(max(order_id), 0), (select coalesce(max(id), 0) from raw.order_items) from raw.orders")
    max_order, max_item = cur.fetchone()
    cur.execute(
        """
        with picked as (
            select row_number() over () as n, u.id as user_id, u.gender
            from (select id, gender from raw.users order by random() limit %(count)s) u
        )
        insert into raw.orders (order_id, user_id, status, gender, created_at, num_of_item)
        select %(max_order)s + n, user_id, 'Processing', gender,
               now() - random() * interval '12 hours',
               1 + floor(random() * 4)::int
        from picked
        """,
        {"count": count, "max_order": max_order},
    )
    n_orders = cur.rowcount
    cur.execute(
        """
        with new_orders as (
            select o.order_id, o.user_id, o.created_at, generate_series(1, o.num_of_item) as pos
            from raw.orders o
            where o.order_id > %(max_order)s
        ),
        numbered as (
            select row_number() over () as n, * from new_orders
        ),
        with_product as (
            select n.*, p.id as product_id, p.retail_price,
                   (select i.id from raw.inventory_items i where i.product_id = p.id limit 1) as inventory_item_id
            from numbered n
            cross join lateral (select id, retail_price from raw.products order by random() + n.n * 0 limit 1) p
        )
        insert into raw.order_items (id, order_id, user_id, product_id, inventory_item_id, status, created_at, sale_price)
        select %(max_item)s + n, order_id, user_id, product_id, inventory_item_id, 'Processing', created_at, retail_price
        from with_product
        """,
        {"max_order": max_order, "max_item": max_item},
    )
    n_items = cur.rowcount
    cur.execute("update raw.orders o set num_of_item = c.cnt from (select order_id, count(*) cnt from raw.order_items where order_id > %s group by order_id) c where o.order_id = c.order_id", (max_order,))
    n_events = copy_events(cur, 300, "now() - random() * interval '12 hours'")
    print(f"new-orders: {n_orders} Bestellungen, {n_items} Positionen, {n_events} Events eingefügt")


def copy_events(cur, count, ts_expr):
    cur.execute(
        f"""
        insert into raw.events (id, user_id, sequence_number, session_id, created_at, ip_address,
                                city, state, postal_code, browser, traffic_source, uri, event_type)
        select (select max(id) from raw.events) + row_number() over (),
               user_id, sequence_number, gen_random_uuid()::text, {ts_expr},
               ip_address, city, state, postal_code, browser, traffic_source, uri, event_type
        from (select * from raw.events order by random() limit %s) s
        """,
        (count,),
    )
    return cur.rowcount


def late_events(cur, count):
    n = copy_events(cur, count, "now() - interval '2 days' - random() * interval '3 days'")
    print(f"late-events: {n} Events mit Zeitstempel von vor 2-5 Tagen eingefügt")


def status_change(cur, count):
    per = max(count // 3, 1)
    steps = [
        ("Processing", "Shipped", "shipped_at"),
        ("Shipped", "Complete", "delivered_at"),
        ("Complete", "Returned", "returned_at"),
    ]
    for old, new, col in steps:
        cur.execute(
            f"""
            with picked as (
                select order_id from raw.orders where status = %s order by random() limit %s
            ),
            upd_items as (
                update raw.order_items i set status = %s, {col} = now()
                where i.order_id in (select order_id from picked)
            )
            update raw.orders o set status = %s, {col} = now()
            where o.order_id in (select order_id from picked)
            """,
            (old, per, new, new),
        )
        print(f"status-change: {cur.rowcount} Bestellungen {old} -> {new}")


def delete_orders(cur, count):
    cur.execute(
        """
        with picked as (select order_id from raw.orders order by random() limit %s),
        del_items as (delete from raw.order_items where order_id in (select order_id from picked))
        delete from raw.orders where order_id in (select order_id from picked)
        returning order_id
        """,
        (count,),
    )
    ids = sorted(r[0] for r in cur.fetchall())
    print(f"delete-orders: {len(ids)} Bestellungen gelöscht, z. B. {ids[:5]}")


def stale(cur, days):
    iv = f"{int(days)} days"
    cur.execute("update raw.users set created_at = created_at - %s::interval", (iv,))
    cur.execute(
        """update raw.orders set created_at = created_at - %(i)s::interval, returned_at = returned_at - %(i)s::interval,
           shipped_at = shipped_at - %(i)s::interval, delivered_at = delivered_at - %(i)s::interval""",
        {"i": iv},
    )
    cur.execute(
        """update raw.order_items set created_at = created_at - %(i)s::interval, shipped_at = shipped_at - %(i)s::interval,
           delivered_at = delivered_at - %(i)s::interval, returned_at = returned_at - %(i)s::interval""",
        {"i": iv},
    )
    cur.execute("update raw.inventory_items set created_at = created_at - %(i)s::interval, sold_at = sold_at - %(i)s::interval", {"i": iv})
    cur.execute("update raw.events set created_at = created_at - %s::interval", (iv,))
    print(f"stale: alle Zeitstempel um {days} Tage in die Vergangenheit verschoben")


def status(cur):
    for t in ["users", "products", "orders", "order_items", "inventory_items", "events", "distribution_centers"]:
        cur.execute(f"select count(*) from raw.{t}")
        print(f"raw.{t:<22} {cur.fetchone()[0]:>8} Zeilen")
    cur.execute("select status, count(*) from raw.orders group by 1 order by 2 desc")
    print("orders nach Status:", ", ".join(f"{s}={c}" for s, c in cur.fetchall()))
    cur.execute("select max(created_at) from raw.orders")
    print("jüngste Bestellung:", cur.fetchone()[0])
    cur.execute("select max(created_at) from raw.events")
    print("jüngstes Event:    ", cur.fetchone()[0])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--step", required=True, choices=["new-orders", "late-events", "status-change", "delete-orders", "stale", "status"])
    p.add_argument("--count", type=int, default=None, help="Anzahl (Standard je nach Schritt)")
    p.add_argument("--days", type=int, default=5, help="Tage für --step stale")
    args = p.parse_args()

    conn = connect()
    try:
        with conn, conn.cursor() as cur:
            if args.step == "new-orders":
                new_orders(cur, args.count or 200)
            elif args.step == "late-events":
                late_events(cur, args.count or 200)
            elif args.step == "status-change":
                status_change(cur, args.count or 90)
            elif args.step == "delete-orders":
                delete_orders(cur, args.count or 20)
            elif args.step == "stale":
                stale(cur, args.days)
            else:
                status(cur)
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
