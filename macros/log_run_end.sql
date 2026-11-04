{% macro log_run_end(results) %}
  {% if execute %}
    {% set errors = results | selectattr('status', 'equalto', 'error') | list | length %}
    insert into {{ target.schema }}.audit_log values
      ('{{ invocation_id }}', '{{ target.name }}', now(), {{ results | length }}, {{ errors }})
  {% endif %}
{% endmacro %}
