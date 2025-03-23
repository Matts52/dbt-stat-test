{% set data = [
    (0.01, -4.605170186),
    (0.25, -1.38629436112),
    (0.5, -0.69314718056),
    (1, 0),
    (2, 0.69314718056),
    (3, 1.09861228867),
    (4, 1.38629436112),
    (5, 1.60943791243),
] %}

{% for row in data %}
    select
        {{ dbt_stat_test._ln(row[0]) }} as actual,
        {{ row[1] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
