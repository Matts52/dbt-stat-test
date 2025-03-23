with test_input as (
    select * from {{ ref('test_two_sample_t_test_input') }}
),

expected_output as (
    select * from {{ ref('test_two_sample_t_test_output') }}
),

actual_output as (
    select 
        'input_1' as input,
        t_test.* 
    from ({{ dbt_stat_test.two_sample_t_test(
        'input_1_value',
        'input_1_group',
        'man',
        'woman',
        ref('test_two_sample_t_test_input')
    ) }}) AS t_test

    union all

    select
        'input_2' as input,
        t_test.*
    from ({{ dbt_stat_test.two_sample_t_test('input_2_value', 'input_2_group', 'group_1', 'group_2', ref('test_two_sample_t_test_input')) }}) AS t_test

)

select
    a.input,
    a.mu1 as actual_mu1,
    e.mu1 as expected_mu1,
    a.mu2 as actual_mu2,
    e.mu2 as expected_mu2,
    a.sigma1 as actual_sigma1,
    e.sigma1 as expected_sigma1,
    a.sigma2 as actual_sigma2,
    e.sigma2 as expected_sigma2,
    a.n1 as actual_n1,
    e.n1 as expected_n1,
    a.n2 as actual_n2,
    e.n2 as expected_n2,
    a.pooled_variance as actual_pooled_variance,
    e.pooled_variance as expected_pooled_variance,
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
