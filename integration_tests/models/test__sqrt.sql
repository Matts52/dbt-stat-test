{% set data = [
    (1, 1),
    (2, 1.41421356237),
    (3, 1.73205080757),
    (4, 2),
    (5, 2.2360679775),
    (100, 10),
    (1000, 31.6227766017)
] %}

{% for row in data %}
    select
        {{ dbt_stat_test._sqrt(row[0]) }} as actual,
        {{ row[1] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}