with source as (

    select * from {{ source('thelook', 'events') }}

),

renamed as (

    select
        id as event_id,
        user_id,
        session_id,
        sequence_number,
        created_at,
        event_type,
        uri,
        browser,
        traffic_source,
        city,
        state,
        postal_code
    from source

)

select * from renamed
