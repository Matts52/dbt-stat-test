{% macro one_sample_t_test(X, df) %}
    {{ return(adapter.dispatch('one_sample_t_test', 'dbt_stat_test')(X, df)) }}
{% endmacro %}

{% macro default__one_sample_t_test(X, df) %}
    {{ return(dbt_stat_test._t_dist_cdf(X, df)) }}
{% endmacro %}

