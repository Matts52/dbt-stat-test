{% macro one_way_anova(value_column, group_column, groups, source_relation, alpha=0.05) %}
    {{ return(adapter.dispatch('one_way_anova', 'dbt_stat_test')(value_column, group_column, groups, source_relation, alpha)) }}
{% endmacro %}

{% macro default__one_way_anova(value_column, group_column, groups, source_relation, alpha=0.05) %}

    {% if groups | length < 3 %}
        {{ exceptions.raise_compiler_error("One-way ANOVA requires at least 3 groups. Got " ~ groups | length ~ " groups.") }}
    {% endif %}

    {% set stats_query %}
        with group_stats as (
            select
                {{ group_column }} as group_name,
                avg({{ value_column }}) as group_mean,
                count(*) as group_n,
                var_pop({{ value_column }}) as group_variance
            from {{ source_relation }}
            where {{ value_column }} is not null
            and {{ group_column }} in (
                {% for group in groups %}
                    '{{ group }}'{% if not loop.last %},{% endif %}
                {% endfor %}
            )
            group by {{ group_column }}
        ),
        
        overall_stats as (
            select
                avg({{ value_column }}) as overall_mean,
                count(*) as total_n,
                count(distinct {{ group_column }}) as k_groups
            from {{ source_relation }}
            where {{ value_column }} is not null
        ),
        
        ss_calculations as (
            select
                -- Between group sum of squares
                sum(g.group_n * power(g.group_mean - o.overall_mean, 2)) as ss_between,
                -- Within group sum of squares (sum of squared deviations from group means)
                sum(g.group_n * g.group_variance) as ss_within,
                -- Degrees of freedom
                o.k_groups - 1 as df_between,
                o.total_n - o.k_groups as df_within,
                o.k_groups as k_groups,
                o.total_n as total_n
            from group_stats g
            cross join overall_stats o
        )
        
        select
            *,
            ss_between / df_between as ms_between,
            ss_within / df_within as ms_within,
            (ss_between / df_between) / (ss_within / df_within) as f_stat
        from ss_calculations
    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set ss_between = stats.columns[0][0] | float %}
        {% set ss_within = stats.columns[1][0] | float %}
        {% set df_between = stats.columns[2][0] | float %}
        {% set df_within = stats.columns[3][0] | float %}
        {% set k_groups = stats.columns[4][0] | float %}
        {% set total_n = stats.columns[5][0] | float %}
        {% set ms_between = stats.columns[6][0] | float %}
        {% set ms_within = stats.columns[7][0] | float %}
        {% set f_stat = stats.columns[8][0] | float %}
        
        {# Calculate p-value using F distribution #}
        {% set p_value = 1 - dbt_stat_test._f_dist_cdf(f_stat, df_between, df_within) %}
        
        {# Test decision #}
        {% set reject_null = p_value < alpha %}
        
        {# Effect size - Eta squared #}
        {% set eta_squared = ss_between / (ss_between + ss_within) %}
        
    {% else %}
        {% set ss_between = none %}
        {% set ss_within = none %}
        {% set df_between = none %}
        {% set df_within = none %}
        {% set k_groups = none %}
        {% set total_n = none %}
        {% set ms_between = none %}
        {% set ms_within = none %}
        {% set f_stat = none %}
        {% set p_value = none %}
        {% set reject_null = none %}
        {% set eta_squared = none %}
    {% endif %}

    select
        {{ k_groups }} as k_groups,
        {{ total_n }} as total_n,
        {{ ss_between }} as ss_between,
        {{ ss_within }} as ss_within,
        {{ df_between }} as df_between,
        {{ df_within }} as df_within,
        {{ ms_between }} as ms_between,
        {{ ms_within }} as ms_within,
        {{ f_stat }} as f_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null,
        {{ eta_squared }} as eta_squared

{% endmacro %}
