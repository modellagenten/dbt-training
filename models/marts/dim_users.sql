with users as (

    select * from {{ ref('stg_users') }}

),

final as (

    select
        user_id,
        first_name,
        last_name,
        email,
        country,
        created_at
    from users

)

select * from final
