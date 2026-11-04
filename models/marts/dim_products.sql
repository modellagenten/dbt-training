with products as (

    select * from {{ ref('stg_products') }}

),

category_groups as (

    select * from {{ ref('category_groups') }}

),

final as (

    select
        products.product_id,
        products.product_name,
        products.brand,
        products.department,
        products.category,
        coalesce(category_groups.category_group, 'Sonstiges') as category_group,
        products.retail_price,
        products.product_cost,
        products.retail_price - products.product_cost as unit_margin
    from products
    left join category_groups
        on products.category = category_groups.category

)

select * from final
