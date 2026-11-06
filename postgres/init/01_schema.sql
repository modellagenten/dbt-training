-- Rohdaten-Schema für die Schulung (thelook_ecommerce, Kaggle-Export)
-- Läuft einmalig beim ersten Start des Postgres-Containers.

create schema if not exists raw;

-- Rolle für Block 07 (grants / post-hook): darf später Marts lesen
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'reporting') then
        create role reporting nologin;
    end if;
end
$$;

create table raw.distribution_centers (
    id          integer primary key,
    name        text,
    latitude    double precision,
    longitude   double precision
);

create table raw.users (
    id              integer primary key,
    first_name      text,
    last_name       text,
    email           text,
    age             integer,
    gender          text,
    state           text,
    street_address  text,
    postal_code     text,
    city            text,
    country         text,
    latitude        double precision,
    longitude       double precision,
    traffic_source  text,
    created_at      timestamptz
);

create table raw.products (
    id                      integer primary key,
    cost                    double precision,
    category                text,
    name                    text,
    brand                   text,
    retail_price            double precision,
    department              text,
    sku                     text,
    distribution_center_id  integer
);

create table raw.orders (
    order_id      integer primary key,
    user_id       integer,
    status        text,
    gender        text,
    created_at    timestamptz,
    returned_at   timestamptz,
    shipped_at    timestamptz,
    delivered_at  timestamptz,
    num_of_item   integer
);

create table raw.order_items (
    id                 integer primary key,
    order_id           integer,
    user_id            integer,
    product_id         integer,
    inventory_item_id  integer,
    status             text,
    created_at         timestamptz,
    shipped_at         timestamptz,
    delivered_at       timestamptz,
    returned_at        timestamptz,
    sale_price         double precision
);

create table raw.inventory_items (
    id                              integer primary key,
    product_id                      integer,
    created_at                      timestamptz,
    sold_at                         timestamptz,
    cost                            double precision,
    product_category                text,
    product_name                    text,
    product_brand                   text,
    product_retail_price            double precision,
    product_department              text,
    product_sku                     text,
    product_distribution_center_id  integer
);

create table raw.events (
    id               integer primary key,
    user_id          integer,
    sequence_number  integer,
    session_id       text,
    created_at       timestamptz,
    ip_address       text,
    city             text,
    state            text,
    postal_code      text,
    browser          text,
    traffic_source   text,
    uri              text,
    event_type       text
);

-- Metadaten zum Laden (wird von 02_load.sh befüllt)
create table raw._load_info (
    loaded_at       timestamptz,
    time_shift      interval,
    note            text
);
