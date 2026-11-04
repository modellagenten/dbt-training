with order_items as (

    select * from {{ ref('int_order_items_enriched') }}

),

final as (

    select
        order_item_id,
        order_id,
        user_id,
        product_id,
        {{ dbt_utils.generate_surrogate_key(['order_id', 'product_id']) }} as order_product_key,
        ordered_at,
        item_status,
        sale_price,
        item_margin,
        item_margin_pct
    from order_items

)

select * from final
