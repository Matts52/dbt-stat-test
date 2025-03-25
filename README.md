
![](./public/dbt_stat_test_logo.webp)
*Logo created by Dall-E 3*


This [dbt](https://github.com/dbt-labs/dbt) package contains macros that can be (re)used across dbt projects.

**Current supported tested databases include:**
- Postgres
- DuckDB

## Statistical Test Macros

| **Method** | **Postgres** | **DuckDB** | **Precision** |
|------------|--------------|------------|---------------|
| [one_sample_t_test](#one_sample_t_test) | ✅ | ✅ | 2 decimal places |
| [one_way_anova](#one_way_anova) | ✅ | ✅ | 2 decimal places |
| [paired_t_test](#paired_t_test) | ✅ | ✅ | 2 decimal places |
| [two_sample_f_test](#two_sample_f_test) | ✅ | ✅ | 2 decimal places |
| [two_sample_t_test](#two_sample_t_test) | ✅ | ✅ | 2 decimal places |

Each statistical test macro includes:
- Null hypothesis testing of a two-tailed hypothesis (and one tailed hypotheses in select macros)
- P-value calculation
- Decision making based on significance level (default α = 0.05)

## Installation Instructions

To import this package into your dbt project, add the following to either the `packages.yml` or `dependencies.yml` file:

```
packages:
  - package: "Matts52/dbt-stat-test"
    version: [">=0.1.0"]
```

and run a `dbt deps` command to install the package to your project.

Check [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## dbt Versioning

This package currently support dbt versions 1.1.0 through 2.0.0

## Adapter Support

Currently this package supports:
- `dbt-duckdb`
- `dbt-postgres`

----

* [Installation Instructions](#installation-instructions)
* [Statistical Tests](#statistical-tests)
    * [one_sample_t_test](#one_sample_t_test)
    * [two_sample_t_test](#two_sample_t_test)
    * [paired_t_test](#paired_t_test)
    * [one_way_anova](#one_way_anova)
    * [two_sample_f_test](#two_sample_f_test)

----

## Statistical Tests

### one_sample_t_test
([source](macros/one_sample_t_test.sql))

This macro performs a one-sample t-test to determine if the mean of a population differs from a hypothesized value.

**Args:**

- `column` (required): Name of the field containing the sample data
- `source_relation` (required): A Relation (a `ref` or `source`) containing the sample data
- `H0` (optional): The hypothesized population mean. Defaults to 0
- `direction` (optional): The direction of the alternative hypothesis. Options are:
  - `'='` (default): Two-tailed test (μ ≠ H0)
  - `'<'`: One-tailed test (μ < H0)
  - `'>'`: One-tailed test (μ > H0)
- `alpha` (optional): The significance level. Defaults to 0.05

**Returns:**

- `mu`: Sample mean
- `sigma`: Sample standard deviation
- `n`: Sample size
- `t_stat`: The calculated t-statistic
- `p_value`: The calculated p-value
- `reject_null`: Boolean indicating whether to reject the null hypothesis

**Usage:**

```sql
{{
    dbt_stat_test.one_sample_t_test(
        column='test_scores',
        source_relation=ref('my_model'),
        H0=75,
        direction='=',
        alpha=0.05
   )
}}
```

### one_way_anova
([source](macros/one_way_anova.sql))

This macro performs a one-way analysis of variance (ANOVA) to determine if there are statistically significant differences between the means of three or more independent groups.

**Args:**

- `value_column` (required): Name of the field containing the dependent variable values
- `group_column` (required): Name of the field containing the group identifiers
- `groups` (required): List of group names to compare. Must contain at least 3 groups
- `source_relation` (required): A Relation (a `ref` or `source`) containing the data
- `alpha` (optional): The significance level. Defaults to 0.05

**Returns:**

- `k_groups`: Number of groups being compared
- `total_n`: Total number of observations across all groups
- `f_stat`: The calculated F-statistic
- `p_value`: The calculated p-value
- `reject_null`: Boolean indicating whether to reject the null hypothesis (all group means are equal)

**Usage:**

```sql
{{
    dbt_stat_test.one_way_anova(
        value_column='test_scores',
        group_column='subject',
        groups=['Math', 'History', 'Psychology'],
        source_relation=ref('my_model'),
        alpha=0.05
   )
}}
```

### two_sample_f_test
([source](macros/two_sample_f_test.sql))

This macro performs a two-sample F-test to determine if the variances of two populations are equal. This test is often used as a preliminary check before performing a two-sample t-test to determine which version of the t-test to use.

**Args:**

- `column` (required): Name of the field containing the sample data
- `group_column` (required): Name of the field containing the group identifiers
- `group_1_value` (required): Value identifying the first group
- `group_2_value` (required): Value identifying the second group
- `source_relation` (required): A Relation (a `ref` or `source`) containing the data
- `alpha` (optional): The significance level. Defaults to 0.05

**Returns:**

- `variance_1`: Sample variance of the first group
- `variance_2`: Sample variance of the second group
- `n1`: Sample size of the first group
- `n2`: Sample size of the second group
- `f_stat`: The calculated F-statistic (ratio of variances)
- `p_value`: The calculated p-value
- `reject_null`: Boolean indicating whether to reject the null hypothesis (variances are equal)

**Usage:**

```sql
{{
    dbt_stat_test.two_sample_f_test(
        column='test_scores',
        group_column='treatment',
        group_1_value='Control',
        group_2_value='Treatment',
        source_relation=ref('my_model'),
        alpha=0.05
   )
}}
```

### two_sample_paired_t_test
([source](macros/two_sample_paired_t_test.sql))

This macro performs a paired t-test to determine if there is a significant difference between two related samples. This test is appropriate when the same subjects are measured twice (e.g., before and after treatment) or when subjects are matched in pairs.

**Args:**

- `column_1` (required): Name of the field containing the first set of measurements
- `column_2` (required): Name of the field containing the second set of measurements
- `source_relation` (required): A Relation (a `ref` or `source`) containing the paired data
- `direction` (optional): The direction of the alternative hypothesis. Options are:
  - `'='` (default): Two-tailed test (μ1 ≠ μ2)
  - `'<'`: One-tailed test (μ1 < μ2)
  - `'>'`: One-tailed test (μ1 > μ2)
- `alpha` (optional): The significance level. Defaults to 0.05

**Returns:**
- `mean_diff`: Mean of the differences between paired measurements
- `stddev_diff`: Standard deviation of the differences
- `n`: Number of paired observations
- `std_error`: Standard error of the mean difference
- `degrees_of_freedom`: Degrees of freedom (n-1)
- `t_stat`: The calculated t-statistic
- `p_value`: The calculated p-value
- `reject_null`: Boolean indicating whether to reject the null hypothesis (no difference between paired measurements)

**Usage:**

```sql
{{
    dbt_stat_test.two_sample_paired_t_test(
        column_1='pre_test_scores',
        column_2='post_test_scores',
        source_relation=ref('my_model'),
        direction='=',
        alpha=0.05
   )
}}
```

### two_sample_t_test
([source](macros/two_sample_t_test.sql))

This macro performs an independent two-sample t-test to determine if there is a significant difference between the means of two independent groups. This test assumes equal variances between the groups (pooled t-test).

**Args:**

- `column` (required): Name of the field containing the sample data
- `group_column` (required): Name of the field containing the group identifiers
- `group_1_value` (required): Value identifying the first group
- `group_2_value` (required): Value identifying the second group
- `source_relation` (required): A Relation (a `ref` or `source`) containing the data
- `direction` (optional): The direction of the alternative hypothesis. Options are:
  - `'='` (default): Two-tailed test (μ1 ≠ μ2)
  - `'<'`: One-tailed test (μ1 < μ2)
  - `'>'`: One-tailed test (μ1 > μ2)
- `alpha` (optional): The significance level. Defaults to 0.05

**Returns:**
- `mu1`: Mean of the first group
- `mu2`: Mean of the second group
- `sigma1`: Standard deviation of the first group
- `sigma2`: Standard deviation of the second group
- `n1`: Sample size of the first group
- `n2`: Sample size of the second group
- `pooled_variance`: Pooled variance estimate
- `std_error`: Standard error of the difference in means
- `degrees_of_freedom`: Degrees of freedom (n1 + n2 - 2)
- `t_stat`: The calculated t-statistic
- `p_value`: The calculated p-value
- `reject_null`: Boolean indicating whether to reject the null hypothesis (no difference between group means)

**Usage:**

```sql
{{
    dbt_stat_test.two_sample_t_test(
        column='test_scores',
        group_column='treatment',
        group_1_value='Control',
        group_2_value='Treatment',
        source_relation=ref('my_model'),
        direction='=',
        alpha=0.05
   )
}}
```
