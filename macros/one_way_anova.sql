{% macro one_way_anova(value_column, group_column, groups, source_relation, alpha=0.05, where='true') %}
    {{ return(adapter.dispatch('one_way_anova', 'dbt_stat_test')(value_column, group_column, groups, source_relation, alpha, where)) }}
{% endmacro %}

{% macro default__one_way_anova(value_column, group_column, groups, source_relation, alpha, where) %}

    {% if groups | length < 3 %}
        {{ exceptions.raise_compiler_error("One-way ANOVA requires at least 3 groups. Got " ~ groups | length ~ " groups.") }}
    {% endif %}

    {% set stats_query %}
        with overall_stats as (
            select
                avg({{ value_column }}) as overall_mean,
                var_pop({{ value_column }}) as overall_variance,
                count(*) as total_n
            from {{ source_relation }}
            where
                true
                and {{ value_column }} is not null
                and {{ where }}
        ),
        
        group_stats as (
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

        sum_squares_within as (
            select
                group_stats.group_name,
                sum(power(sr.{{ value_column }} - group_stats.group_mean, 2)) as ss_within
            from {{ source_relation }} as sr
            inner join group_stats
                on sr.{{ group_column }} = group_stats.group_name
            group by
                group_stats.group_name
        ),
        
  		sum_squares_between as (
  			select
  				sum(power(group_stats.group_mean - (select overall_mean from overall_stats), 2) * group_stats.group_n) as ss_between
  			from group_stats
  		),      
  
        mean_ss_between as (
            select
                ss_between / 2 as mean_ss_between
            from sum_squares_between
        ),

        mean_ss_within as (
            select
                sum(sum_squares_within.ss_within) / (select total_n - {{ groups | length }} from overall_stats) as mean_ss_within
            from sum_squares_within
        )

        select
            (select total_n from overall_stats) as total_n,
            (select mean_ss_between from mean_ss_between) / (select mean_ss_within from mean_ss_within) as f_stat



    {% endset %}

    {% set stats = run_query(stats_query) %}

    {% if execute %}
        {% set k_groups = groups | length | float %}
        {% set total_n = stats.columns[0][0] | float %}
        {% set f_stat = stats.columns[1][0] | float %}

        {# Calculate p-value using F distribution #}
        {% set p_value = dbt_stat_test._f_dist_cdf(f_stat, k_groups - 1, total_n - k_groups) %}
        
        {# Test decision #}
        {% set reject_null = p_value < alpha %}
        
    {% else %}
        {% set k_groups = none %}
        {% set total_n = none %}
        {% set f_stat = none %}
        {% set p_value = none %}
        {% set reject_null = none %}
    {% endif %}

    select
        {{ k_groups }} as k_groups,
        {{ total_n }} as total_n,
        {{ f_stat }} as f_stat,
        {{ p_value }} as p_value,
        {{ reject_null }} as reject_null


{% endmacro %}
