with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

final as (

    select
        order_item_id,
        order_id,
        user_id,
        product_id,
        ordered_at,
        item_status,
        sale_price,
        item_margin
    from order_items

)

select * from final
