{% macro margin_pct(revenue, cost, precision=1) %}
    round(
        (({{ revenue }} - {{ cost }}) / nullif({{ revenue }}, 0) * 100)::numeric,
        {{ precision }}
    )
{% endmacro %}
