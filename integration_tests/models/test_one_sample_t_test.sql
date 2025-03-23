with test_input as (
    select * from {{ ref('test_one_sample_t_test_input') }}
),

expected_output as (
    select * from {{ ref('test_one_sample_t_test_output') }}
),

actual_output as (
    select 
        'input_1' as input,
        t_test.* 
    from ({{ dbt_stat_test.one_sample_t_test('input_1', ref('test_one_sample_t_test_input'), H0=50) }}) AS t_test

    union all

    select
        'input_2' as input,
        t_test.*
    from ({{ dbt_stat_test.one_sample_t_test('input_2', ref('test_one_sample_t_test_input'), H0=10) }}) AS t_test

)

select
    a.input,
    a.mu as actual_mu,
    e.mu as expected_mu,
    a.sigma as actual_sigma,
    e.sigma as expected_sigma,
    a.n as actual_n,
    e.n as expected_n,
    a.t_stat as actual_t_stat,
    e.t_stat as expected_t_stat,
    a.p_value as actual_p_value,
    e.p_value as expected_p_value,
    a.reject_null as actual_reject_null,
    e.reject_null as expected_reject_null
from actual_output as a
inner join expected_output as e
    on a.input = e.input
