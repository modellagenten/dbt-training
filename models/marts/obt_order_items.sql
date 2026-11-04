with items as (
    select * from {{ ref('fct_order_items') }}
),

users as (
    select * from {{ ref('dim_users') }}
),

products as (
    select * from {{ ref('dim_products') }}
),

final as (
    select
        items.order_item_id,
        items.order_id,
        items.ordered_at,
        items.item_status,
        items.sale_price,
        items.item_margin,
        users.user_id,
        users.country,
        products.product_name,
        products.brand,
        products.category_group
    from items
    left join users on items.user_id = users.user_id
    left join products on items.product_id = products.product_id
)

select * from final
