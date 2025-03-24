{% set data = [
    (5, 3, 10),
    (10, 4, 210),
    (3, 2, 3),
    (3, 3, 1),
]
%}

{% for row in data %}
    select
        {{ dbt_stat_test._n_choose_k(row[0], row[1]) }} as actual,
        {{ row[2] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}