{{ config(materialized='ephemeral') }}

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select order_id, status as order_status, created_at as ordered_at
    from {{ ref('stg_orders') }}
),

products as (
    select product_id, product_name, brand, category, product_cost
    from {{ ref('stg_products') }}
),

enriched as (
    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.user_id,
        order_items.product_id,
        order_items.status as item_status,
        orders.order_status,
        orders.ordered_at,
        products.product_name,
        products.brand,
        products.category,
        {{ round_money('order_items.sale_price') }} as sale_price,
        {{ round_money('products.product_cost') }} as product_cost,
        {{ round_money('order_items.sale_price - products.product_cost') }} as item_margin,
        {{ margin_pct('order_items.sale_price', 'products.product_cost') }} as item_margin_pct
    from order_items
    inner join orders on order_items.order_id = orders.order_id
    left join products on order_items.product_id = products.product_id
)

select * from enriched
