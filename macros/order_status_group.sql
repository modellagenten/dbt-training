{% macro order_status_group(column_name) %}
    case
        when {{ column_name }} = 'Complete' then 'abgeschlossen'
        when {{ column_name }} in ('Shipped', 'Processing') then 'in Bearbeitung'
        when {{ column_name }} in ('Cancelled', 'Returned') then 'storniert'
        else 'unbekannt'
    end
{% endmacro %}
