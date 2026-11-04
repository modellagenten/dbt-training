with source as (

    select * from {{ source('thelook', 'users') }}

),

renamed as (

    select
        id as user_id,
        first_name,
        last_name,
        email,
        country,
        created_at
    from source

)

select * from renamed
