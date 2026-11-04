{% macro round_money(column_name, precision=2) %}
    round(({{ column_name }})::numeric, {{ precision }})
{% endmacro %}
