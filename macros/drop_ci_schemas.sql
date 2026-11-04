{% macro drop_ci_schemas(prefix='dbt_ci') %}
    {#- Löscht alle CI-Schemas, deren Name mit dem Präfix beginnt (z. B. dbt_ci, dbt_ci_pr_42_marts).
        Sicherheitsnetz: Das Präfix muss mit dbt_ci beginnen, damit nie dev- oder prod-Schemas getroffen werden. -#}
    {% if not prefix.startswith('dbt_ci') %}
        {{ exceptions.raise_compiler_error("Präfix muss mit 'dbt_ci' beginnen, erhalten: " ~ prefix) }}
    {% endif %}

    {% set find_schemas %}
        select nspname from pg_namespace
        where nspname = '{{ prefix }}'
           or left(nspname, {{ prefix | length + 1 }}) = '{{ prefix }}_'
    {% endset %}

    {% for schema_name in run_query(find_schemas).columns[0].values() %}
        {% do run_query('drop schema if exists ' ~ schema_name ~ ' cascade') %}
        {% do log('Schema gelöscht: ' ~ schema_name, info=True) %}
    {% endfor %}
{% endmacro %}
