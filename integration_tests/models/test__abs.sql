{% set data = [
    (1, 1),
    (-1, 1),
    (0, 0),
    (2.5, 2.5),
    (-2.5, 2.5),
    (-0, 0)
] %}
{% for row in data %}
    select
        {{ dbt_stat_test._abs(row[0]) }} as actual,
        {{ row[1] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
