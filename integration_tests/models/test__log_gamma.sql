{% set data = [
    (0.5, 0.572365),
    (1, 0.0),
    (1.5, -0.120782),
    (2, 0.0),
    (2.5, 0.284683),
    (3, 0.693147),
    (4, 1.791759),
    (5, 3.178054)
] %}

{% for row in data %}
    select
        {{ dbt_stat_test._log_gamma(row[0]) }} as actual,
        {{ row[1] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
