{% macro one_sample_t_test(column, source_relation, H0=0, direction='=', alpha=0.05) %}
    {{ return(adapter.dispatch('one_sample_t_test', 'dbt_stat_test')(column, source_relation, H0, direction, alpha)) }}
{% endmacro %}

{% macro default__one_sample_t_test(column, source_relation, H0=0, direction='=', alpha=0.05) %}

    {% set stats_query %}
        select
            avg({{ column }}) as mu,
            stddev({{ column }}) as sigma,
            count(*) as n
        from {{ source_relation }}
    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set mu = stats.columns[0][0] | float %}
        {% set sigma = stats.columns[1][0] | float %}
        {% set n = stats.columns[2][0] | float %}
        {% set t_stat = (mu - H0) / (sigma / dbt_stat_test._sqrt(n)) %}
        {# TODO: Add one-tailed critical t value calculation -> see: https://github.com/Matts52/ECO304/blob/main/Scripts/StatisticalHelpers.js#L217 #}

        {% if direction == '=' %} 
            {% set p_value = 2 * (1 - dbt_stat_test._t_dist_cdf(dbt_stat_test._abs(t_stat), n - 1)) %}
        {% elif direction == '<' %}
            {% set p_value = dbt_stat_test._t_dist_cdf(t_stat, n - 1) %} 
        {% elif direction == '>' %}
            {% set p_value = 1 - dbt_stat_test._t_dist_cdf(t_stat, n - 1) %}
        {% endif %}
        
        {% set reject_null = p_value < alpha %}

    {% else %}
        {% set mu = none %}
        {% set sigma = none %}
        {% set n = none %}
        {% set t_stat = none %}
        {% set reject_null = none %}
    {% endif %}

    select
        {{ mu }} as mu,
        {{ sigma }} as sigma,
        {{ n }} as n,
        {{ t_stat }} as t_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null

{% endmacro %}
