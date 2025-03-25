with test_input as (
    select * from {{ ref('test_two_sample_f_test_input') }}
),

{# https://www.statskingdom.com/220VarF2.html #}
expected_output as (
    select * from {{ ref('test_two_sample_f_test_output') }}
),

actual_output as (
    select 
        'input_1' as input,
        f_test.*
    from ({{ dbt_stat_test.two_sample_f_test(
        'input_1_value',
        'input_1_group',
        'r',
        'w',
        ref('test_two_sample_f_test_input')
    ) }}) AS f_test

    union all

    select 
        'input_2' as input,
        f_test.*
    from ({{ dbt_stat_test.two_sample_f_test(
        'input_2_value',
        'input_2_group',
        'apple',
        'pear',
        ref('test_two_sample_f_test_input')
    ) }}) AS f_test
)

select
    actual_output.input,
    actual_output.variance_1 as actual_variance_1,
    expected_output.variance_1 as expected_variance_1,
    actual_output.variance_2 as actual_variance_2,
    expected_output.variance_2 as expected_variance_2,
    actual_output.n1 as actual_n1,
    expected_output.n1 as expected_n1,
    actual_output.n2 as actual_n2,
    expected_output.n2 as expected_n2,
    actual_output.f_stat as actual_f_stat,
    expected_output.f_stat as expected_f_stat,
    actual_output.p_value as actual_p_value,
    expected_output.p_value as expected_p_value,
    actual_output.reject_null as actual_reject_null,
    expected_output.reject_null as expected_reject_null
from actual_output
left join expected_output
    on actual_output.input = expected_output.input
