{% macro two_sample_paired_t_test(column_1, column_2, source_relation, direction='=', alpha=0.0, where='true') %}
    {{ return(adapter.dispatch('two_sample_paired_t_test', 'dbt_stat_test')(column_1, column_2, source_relation, direction, alpha, where)) }}
{% endmacro %}

{% macro default__two_sample_paired_t_test(column_1, column_2, source_relation, direction, alpha, where) %}

    {% set stats_query %}
        select
            avg({{ column_2 }} - {{ column_1 }}) as mean_diff,
            stddev({{ column_2 }} - {{ column_1 }}) as stddev_diff,
            count(*) as n
        from {{ source_relation }}
        where
            true
            and {{ column_1 }} is not null 
            and {{ column_2 }} is not null
            and {{ where }}
    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set mean_diff = stats.columns[0][0] | float %}
        {% set stddev_diff = stats.columns[1][0] | float %}
        {% set n = stats.columns[2][0] | float %}
        
        {# Standard error of the mean difference #}
        {% set std_error = stddev_diff / dbt_stat_test._sqrt(n) %}
        
        {# Degrees of freedom #}
        {% set df = n - 1 %}
        
        {# T-statistic #}
        {% set t_stat = mean_diff / std_error %}
        
        {# Critical value and p-value #}
        {# TODO: Add one-tailed critical t value calculation -> see: https://github.com/Matts52/ECO304/blob/main/Scripts/StatisticalHelpers.js#L217 #}
        
        {% if direction == '=' %} 
            {% set p_value = 2 * (1 - dbt_stat_test._t_dist_cdf(dbt_stat_test._abs(t_stat), df)) %}
        {% elif direction == '<' %}
            {% set p_value = dbt_stat_test._t_dist_cdf(t_stat, df) %} 
        {% elif direction == '>' %}
            {% set p_value = 1 - dbt_stat_test._t_dist_cdf(t_stat, df) %}
        {% endif %}
        
        {% set reject_null = p_value < alpha %}

    {% else %}
        {% set mean_diff = none %}
        {% set stddev_diff = none %}
        {% set n = none %}
        {% set std_error = none %}
        {% set df = none %}
        {% set t_stat = none %}
        {% set p_value = none %}
        {% set reject_null = none %}
    {% endif %}

    select
        {{ mean_diff }} as mean_diff,
        {{ stddev_diff }} as stddev_diff,
        {{ n }} as n,
        {{ std_error }} as std_error,
        {{ df }} as degrees_of_freedom,
        {{ t_stat }} as t_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null

{% endmacro %}
