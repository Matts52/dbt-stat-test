{% set data = [
    (3, 5, 0.0095238095),
    (5, 2, 0.3333333333),
    (0.5, 0.5, 3.14159),
    (10, 1, 0.1),
    (0.1, 10, 7.59138)
]
%}

{% for row in data %}
    select
        {{ dbt_stat_test._beta(row[0], row[1]) }} as actual,
        {{ row[2] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}