{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    unique_key='event_id',
    event_time='created_at',
    begin='2019-01-01',
    batch_size='month',
    lookback=1
) }}

select
    event_id,
    user_id,
    session_id,
    event_type,
    traffic_source,
    created_at
from {{ ref('stg_events') }}
