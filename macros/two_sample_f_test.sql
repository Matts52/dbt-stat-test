{% macro two_sample_f_test(column, group_column, group_1_value, group_2_value, source_relation, alpha=0.05, where='true') %}
    {{ return(adapter.dispatch('two_sample_f_test', 'dbt_stat_test')(column, group_column, group_1_value, group_2_value, source_relation, alpha, where)) }}
{% endmacro %}

{% macro default__two_sample_f_test(column, group_column, group_1_value, group_2_value, source_relation, alpha, where) %}

    {% set stats_query %}
        select
            max(case when {{ group_column }} = '{{ group_1_value }}' then stddev_val end) as sigma1,
            max(case when {{ group_column }} = '{{ group_2_value }}' then stddev_val end) as sigma2,
            max(case when {{ group_column }} = '{{ group_1_value }}' then n end) as n1,
            max(case when {{ group_column }} = '{{ group_2_value }}' then n end) as n2
        from (
            select 
                {{ group_column }},
                stddev({{ column }}) as stddev_val,
                count(*) as n
            from {{ source_relation }}
            where
                true
                and {{ group_column }} in ('{{ group_1_value }}', '{{ group_2_value }}')
                and {{ where }}
            group by {{ group_column }}
        ) subq
    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set var_1 = stats.columns[0][0] | float %}
        {% set var_2 = stats.columns[1][0] | float %}
        {% set n1 = stats.columns[2][0] | float %}
        {% set n2 = stats.columns[3][0] | float %}
        
        {% set f_stat = var_1 ** 2 / var_2 ** 2 %}

        {# https://math.stackexchange.com/questions/2725996/finding-the-p-value-of-a-2-sided-f-test #}
        {% if var_1 > var_2 %}
            {% set p_value_part_1 = dbt_stat_test._f_dist_cdf(f_stat, n1 - 1, n2 - 1) %}
            {% set p_value_part_2 = 1 - dbt_stat_test._f_dist_cdf(1 / f_stat, n1 - 1, n2 - 1) %}
        {% else %}
            {% set p_value_part_1 = 1 - dbt_stat_test._f_dist_cdf(f_stat, n1 - 1, n2 - 1) %}
            {% set p_value_part_2 = dbt_stat_test._f_dist_cdf(1 / f_stat, n1 - 1, n2 - 1) %}
        {% endif %}

        {% set p_value = p_value_part_1 + p_value_part_2 %}

        {% set reject_null = p_value < alpha %}

    {% else %}
        {% set var_1 = none %}
        {% set var_2 = none %}
        {% set n1 = none %}
        {% set n2 = none %}
        {% set f_stat = none %}
        {% set reject_null = none %}
    {% endif %}


    select
        {{ var_1 }} as variance_1,
        {{ var_2 }} as variance_2,
        {{ n1 }} as n1,
        {{ n2 }} as n2,
        {{ f_stat }} as f_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null

{% endmacro %}


