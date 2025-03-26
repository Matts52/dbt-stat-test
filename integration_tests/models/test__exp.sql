{% set data = [
    (0.5, 1.648721271),
    (0, 1),
    (1, 2.71828182846),
    (2, 7.38905609893),
    (3, 20.0855369232),
    (4, 54.5981500331),
]
%}

{% for row in data %}
    select
        {{ dbt_stat_test._exp(row[0]) }} as actual,
        {{ row[1] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
