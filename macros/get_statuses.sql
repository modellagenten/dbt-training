{% macro get_statuses() %}
    {% if execute %}
        {% set result = run_query('select distinct status from ' ~ ref('stg_orders') ~ ' order by 1') %}
        {{ return(result.columns[0].values()) }}
    {% else %}
        {{ return([]) }}
    {% endif %}
{% endmacro %}
