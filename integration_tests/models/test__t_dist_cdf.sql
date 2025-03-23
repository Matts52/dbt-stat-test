{% set data = [
    (1.96, 10, 0.96078),
    (-0.5, 150, 0.3089),
    (0, 100, 0.5),
    (0.8753, 52, 0.80728),
    (-0.99, 5, 0.18382),
    (100, 100, 0.999999)
] %}

{% for row in data %}
    select
        {{ dbt_stat_test._t_dist_cdf(row[0], row[1]) }} as actual,
        {{ row[2] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}