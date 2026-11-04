{% macro grant_select_on_schema(schema_name, role) %}
    {% set sql %}
        grant usage on schema {{ schema_name }} to {{ role }};
        grant select on all tables in schema {{ schema_name }} to {{ role }};
    {% endset %}
    {% do run_query(sql) %}
    {% do log('Rechte vergeben für ' ~ schema_name, info=True) %}
{% endmacro %}
