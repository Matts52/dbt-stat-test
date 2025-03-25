with test_input as (
    select * from {{ ref('test_one_way_anova_input') }}
),

{# For calculator: https://www.socscistatistics.com/tests/anova/default2.aspx #}
expected_output as (
    select * from {{ ref('test_one_way_anova_output') }}
),

actual_output as (

    -- https://datatab.net/tutorial/levene-test
    select
        'input_1' as input,
        one_way_anova.*
    from ({{ dbt_stat_test.one_way_anova(
        value_column='input_1_value',
        group_column='input_1_group',
        groups=['Math', 'History', 'Psychology'],
        source_relation=ref('test_one_way_anova_input')
    ) }}) AS one_way_anova

    union all

    --https://www.qualitygurus.com/analysis-of-variance-anova-explained-with-formula-and-an-example/
    select
        'input_2' as input,
        one_way_anova.*
    from ({{ dbt_stat_test.one_way_anova(
        value_column='input_2_value',
        group_column='input_2_group',
        groups=['Machine 1', 'Machine 2', 'Machine 3'],
        source_relation=ref('test_one_way_anova_input')
    ) }}) AS one_way_anova
)

select
    actual_output.input,
    actual_output.k_groups as actual_k_groups,
    expected_output.k_groups as expected_k_groups,
    actual_output.total_n as actual_total_n,
    expected_output.total_n as expected_total_n,
    actual_output.f_stat as actual_f_stat,
    expected_output.f_stat as expected_f_stat,
    actual_output.p_value as actual_p_value,
    expected_output.p_value as expected_p_value,
    actual_output.reject_null as actual_reject_null,
    expected_output.reject_null as expected_reject_null
from actual_output
left join expected_output
    on actual_output.input = expected_output.input
