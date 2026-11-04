with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('int_order_items_enriched') }}
),

order_totals as (
    select
        order_id,
        count(*) as line_count,
        sum(sale_price) as revenue,
        sum(item_margin) as margin
    from order_items
    group by 1
),

final as (
    select
        orders.order_id,
        orders.user_id,
        orders.status,
        orders.created_at as ordered_at,
        coalesce(order_totals.line_count, 0) as line_count,
        coalesce(order_totals.revenue, 0) as revenue,
        coalesce(order_totals.margin, 0) as margin
    from orders
    left join order_totals on orders.order_id = order_totals.order_id
)

select * from final
