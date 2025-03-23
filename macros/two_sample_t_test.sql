{% macro two_sample_t_test(column, group_column, group_1_value, group_2_value, source_relation, direction='=', alpha=0.05) %}
    {{ return(adapter.dispatch('two_sample_t_test', 'dbt_stat_test')(column, group_column, group_1_value, group_2_value, source_relation, direction, alpha)) }}
{% endmacro %}

{% macro default__two_sample_t_test(column, group_column, group_1_value, group_2_value, source_relation, direction='=', alpha=0.05) %}

    {% set stats_query %}
        select
            max(case when {{ group_column }} = '{{ group_1_value }}' then avg_val end) as mu1,
            max(case when {{ group_column }} = '{{ group_2_value }}' then avg_val end) as mu2,
            max(case when {{ group_column }} = '{{ group_1_value }}' then stddev_val end) as sigma1,
            max(case when {{ group_column }} = '{{ group_2_value }}' then stddev_val end) as sigma2,
            max(case when {{ group_column }} = '{{ group_1_value }}' then n end) as n1,
            max(case when {{ group_column }} = '{{ group_2_value }}' then n end) as n2
        from (
            select 
                {{ group_column }},
                avg({{ column }}) as avg_val,
                stddev({{ column }}) as stddev_val,
                count(*) as n
            from {{ source_relation }}
            where {{ group_column }} in ('{{ group_1_value }}', '{{ group_2_value }}')
            group by {{ group_column }}
        ) subq
    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set mu1 = stats.columns[0][0] | float %}
        {% set mu2 = stats.columns[1][0] | float %}
        {% set sigma1 = stats.columns[2][0] | float %}
        {% set sigma2 = stats.columns[3][0] | float %}
        {% set n1 = stats.columns[4][0] | float %}
        {% set n2 = stats.columns[5][0] | float %}
        
        {# Pooled standard error #}
        {% set pooled_variance = ((n1 - 1) * (sigma1 * sigma1) + (n2 - 1) * (sigma2 * sigma2)) / (n1 + n2 - 2) %}
        {% set std_error = dbt_stat_test._sqrt(pooled_variance) * dbt_stat_test._sqrt(1.0 / n1 + 1.0 / n2) %}
        
        {# Degrees of freedom (pooled) #}
        {% set df = n1 + n2 - 2 %}
        
        {# T-statistic #}
        {% set t_stat = (mu1 - mu2) / std_error %}
        
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
        {% set mu1 = none %}
        {% set mu2 = none %}
        {% set sigma1 = none %}
        {% set sigma2 = none %}
        {% set n1 = none %}
        {% set n2 = none %}
        {% set t_stat = none %}
        {% set p_value = none %}
        {% set reject_null = none %}
        {% set pooled_variance = none %}
        {% set std_error = none %}
        {% set df = none %}
    {% endif %}

    select
        {{ mu1 }} as mu1,
        {{ mu2 }} as mu2,
        {{ sigma1 }} as sigma1,
        {{ sigma2 }} as sigma2,
        {{ n1 }} as n1,
        {{ n2 }} as n2,
        {{ pooled_variance }} as pooled_variance,
        {{ std_error }} as std_error,
        {{ df }} as degrees_of_freedom,
        {{ t_stat }} as t_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null

{% endmacro %}
