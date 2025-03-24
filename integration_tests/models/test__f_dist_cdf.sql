{% set data = [
    (1, 2, 3, 0.4647),
    (1, 2, 5, 0.4312),
    (0.5, 37, 25, 0.9729),
    (1.2, 15, 12, 0.38021)
]
%}

{% for row in data %}
    select
        {{ dbt_stat_test._f_dist_cdf(row[0], row[1], row[2]) }} as actual,
        {{ row[3] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
