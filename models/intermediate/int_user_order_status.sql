{% set statuses = dbt_utils.get_column_values(ref('stg_orders'), 'status') %}

select
    user_id,
    {{ dbt_utils.pivot('status', statuses, prefix='orders_', quote_identifiers=false) }}
from {{ ref('stg_orders') }}
group by user_id
