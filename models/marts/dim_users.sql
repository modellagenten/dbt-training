with users as (

    select * from {{ ref('stg_users') }}

),

order_status as (

    select * from {{ ref('int_user_order_status') }}

),

final as (

    select
        users.user_id,
        users.first_name,
        users.last_name,
        users.email,
        users.country,
        users.created_at,
        coalesce(order_status.orders_complete, 0)   as orders_complete,
        coalesce(order_status.orders_shipped, 0)    as orders_shipped,
        coalesce(order_status.orders_processing, 0) as orders_processing,
        coalesce(order_status.orders_cancelled, 0)  as orders_cancelled,
        coalesce(order_status.orders_returned, 0)   as orders_returned
    from users
    left join order_status on users.user_id = order_status.user_id

)

select * from final
