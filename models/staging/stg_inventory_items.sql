with source as (

    select * from {{ source('thelook', 'inventory_items') }}

),

renamed as (

    select
        id as inventory_item_id,
        product_id,
        product_distribution_center_id as distribution_center_id,
        created_at,
        sold_at,
        cost as item_cost
    from source

)

select * from renamed
