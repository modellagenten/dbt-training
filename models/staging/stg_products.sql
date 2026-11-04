with source as (

    select * from {{ source('thelook', 'products') }}

),

renamed as (

    select
        id as product_id,
        name as product_name,
        brand,
        category,
        department,
        retail_price,
        cost as product_cost
    from source

)

select * from renamed
