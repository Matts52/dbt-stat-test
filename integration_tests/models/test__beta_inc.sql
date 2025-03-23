{% set data = [
    (0.5, 0.25, 0.25, 5.244113913653807),
    (0.75, 0.5, 0.5, 4.836792902152969),
    (2, 1, 1, -1)
]
%}

{% for row in data %}
    select
        {{ dbt_stat_test._beta_inc(row[0], row[1], row[2]) }} as actual,
        {{ row[3] }} as expected

    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}
