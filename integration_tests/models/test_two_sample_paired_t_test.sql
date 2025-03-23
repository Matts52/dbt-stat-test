with test_input as (
    select * from {{ ref('test_two_sample_paired_t_test_input') }}
),

expected_output as (
    select * from {{ ref('test_two_sample_paired_t_test_output') }}
),

actual_output as (
    select 
        'input_1' as input,
        t_test.* 
    from ({{ dbt_stat_test.two_sample_paired_t_test(
        column_1='input_1_1',
        column_2='input_1_2',
        source_relation=ref('test_two_sample_paired_t_test_input')
    ) }}) as t_test

    union all

    select
        'input_2' as input,
        t_test.*
    from ({{ dbt_stat_test.two_sample_paired_t_test(
        column_1='input_2_1',
        column_2='input_2_2',
        source_relation=ref('test_two_sample_paired_t_test_input')
    ) }}) as t_test
)

select
    a.input,
    a.mean_diff as actual_mean_diff,
    e.mean_diff as expected_mean_diff,
    a.stddev_diff as actual_stddev_diff,
    e.stddev_diff as expected_stddev_diff,
    a.n as actual_n,
    e.n as expected_n,
    a.std_error as actual_std_error,
    e.std_error as expected_std_error,
    a.degrees_of_freedom as actual_degrees_of_freedom,
    e.degrees_of_freedom as expected_degrees_of_freedom,
    a.t_stat as actual_t_stat,
    e.t_stat as expected_t_stat,
    a.p_value as actual_p_value,
    e.p_value as expected_p_value,
    a.reject_null as actual_reject_null,
    e.reject_null as expected_reject_null
from actual_output as a
inner join expected_output as e
    on a.input = e.input
