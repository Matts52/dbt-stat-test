/*
==============================================
see view-source:https://www.math.ucla.edu/~tom/distributions/tDist.html
for estimation details
==============================================
*/

/* Square Root Function */
{% macro _sqrt(x) %}
    {% set x = x | float %}
    {% set result = x ** 0.5 %}
    {{ return(result) }}
{% endmacro %}

/* Natural Logarithm Function */
{% macro _ln(x) %}
    {% set x = x | float %}
    
    -- Handle special cases
    {% if x < 0 %}
        {{ exceptions.raise_compiler_error("Cannot calculate logarithm of negative number") }}
    {% elif x == 0 %}
        {{ return(-100000000) }}
    {% endif %}

    /* Use Logarithm rule for small values of x */
    {% if x < 0.75 %}
        {{ return(dbt_stat_test._ln_small(x)) }}
    /* Use Taylor series for small values of x */
    {% elif x < 2.0 %}
        {{ return(dbt_stat_test._ln_taylor(x)) }}
    /* Use asymptotic expansion for large values of x */
    {% else %}
        {{ return(dbt_stat_test._ln_large(x)) }}
    {% endif %}

{% endmacro %}

{% macro _ln_taylor(x) %}
    -- For x close to 1, use Taylor series
    {% set y = (x - 1.0) / (x + 1.0) %}
    {% set y2 = y * y %}
    
    -- Use the first 7 terms of the series for good precision
    {% set result = y * (2.0 + y2 * (2.0/3.0 + y2 * (2.0/5.0 + y2 * (2.0/7.0 + y2 * (2.0/9.0 + y2 * (2.0/11.0 + y2 * 2.0/13.0)))))) %}
    
    {{ return(result) }}
{% endmacro %}

/* https://www.physicsforums.com/threads/good-approximation-to-the-log-function.569352/ */
/* rule that division in a log can be represented as a subtraction of the logs */
{% macro _ln_small(x) %}
    {% set result = dbt_stat_test._ln_large(x * 1000000) - dbt_stat_test._ln_large(1000000) %}

    {{ return(result) }}
{% endmacro %}

/* See https://math.stackexchange.com/questions/977586/is-there-an-approximation-to-the-natural-log-function-at-large-values */
{% macro _ln_large(x) %}
    {% set result = 1000000 * (x ** (1.0/1000000)) - 1000000 %}

    {{ return(result) }}
{% endmacro %}

/* Exponential Function */
/* Using Taylor series expansion */
{% macro _exp(x) %}
    {% set x = x | float %}
    
    -- Use the approximation of e^x = 2^(x / ln(2))
    {% set result = 2 ** (x / dbt_stat_test._ln(2)) %}

    {{ return(result) }}
{% endmacro %}

/* Absolute Value Function */
{% macro _abs(x) %}
    {% set x = x | float %}
    
    {% if x < 0.0 %}
        {{ return(-1.0 * x) }}
    {% else %}
        {{ return(x) }}
    {% endif %}
{% endmacro %}

/* Log Gamma Function */
/* Lanczos Approximation - https://en.wikipedia.org/wiki/Lanczos_approximation*/
{% macro _log_gamma(Z) %}
    {% set Z = Z | float %}  -- Ensure Z is float
    
    {% set S = 1.0
        + (76.18009173 / Z)
        - (86.50532033 / (Z + 1.0))
        + (24.01409822 / (Z + 2.0))
        - (1.231739516 / (Z + 3.0))
        + (0.00120858003 / (Z + 4.0))
        - (0.00000536382 / (Z + 5.0))
    %}

    -- Stirling's Approximation Core + Lanczos Correction
    {% set LG = (Z - 0.5) * dbt_stat_test._ln(Z + 4.5)
        - (Z + 4.5)
        + dbt_stat_test._ln(S * 2.50662827465)
    %}

    {{ return(LG) }}
{% endmacro %}

/* T Distribution CDF Function */
{% macro _t_dist_cdf(X, df) %}
    {% if df <= 0 %}
        {{ exceptions.raise_compiler_error("Degrees of freedom must be positive") }}
    {% endif %}

    {% set vars = namespace(
        X = X | float,
        df = df | float,
        A = df / 2.0,
        S = 0.0,
        Z = 0.0,
        BT = 0.0,
        betacdf = 0.0,
        tcdf = 0.0
    ) %}
    
    {% set vars.S = vars.A + 0.5 %}
    {% set vars.Z = vars.df / (vars.df + vars.X * vars.X) %}

    -- Breaking down BT into components
    {% set vars.BT = dbt_stat_test._exp(
        dbt_stat_test._log_gamma(vars.S) 
        - dbt_stat_test._log_gamma(0.5) 
        - dbt_stat_test._log_gamma(vars.A) 
        + vars.A * dbt_stat_test._ln(vars.Z) 
        + 0.5 * dbt_stat_test._ln(1.0 - vars.Z)
    ) %}
    
    -- Determine which formula to use based on Z value
    {% if vars.Z < (vars.A + 1.0) / (vars.S + 2.0) %}
        {% set vars.betacdf = vars.BT * dbt_stat_test._beta_inc(vars.Z, vars.A, 0.5) %}
    {% else %}
        {% set vars.betacdf = 1.0 - vars.BT * dbt_stat_test._beta_inc(1.0 - vars.Z, 0.5, vars.A) %}
    {% endif %}
    
    -- Final t-distribution calculation based on X sign
    {% set vars.tcdf = vars.betacdf / 2.0 if vars.X < 0.0 else 1.0 - vars.betacdf / 2.0 %}

    -- Round
    {% set vars.tcdf = (vars.tcdf * 100000 | round) / 100000 %}

    {{ return(vars.tcdf) }}
{% endmacro %}

/* Incomplete Beta Function */
{% macro _beta_inc(X, A, B) %}
    {% set input = namespace(
        X = X | float,
        A = A | float,
        B = B | float
    ) %}

    {% set vars = namespace(
        A0 = 0.0,
        B0 = 1.0,
        A1 = 1.0,
        B1 = 1.0,
        M9 = 0.0,
        A2 = 0.0,
        C9 = 0.0
    ) %}
    
    {% set max_iterations = 100000 %}  -- Safety limit to prevent infinite loops
    {% set tolerance = 0.00001 %}
    
    {% for i in range(max_iterations) %}
        {% set vars.A2 = vars.A1 %}
        
        -- First part of the iteration
        {% set vars.C9 = -1.0 * (input.A + vars.M9) * (input.A + input.B + vars.M9) * input.X / (input.A + 2.0 * vars.M9) / (input.A + 2.0 * vars.M9 + 1.0) %}
        {% set vars.A0 = vars.A1 + vars.C9 * vars.A0 %}
        {% set vars.B0 = vars.B1 + vars.C9 * vars.B0 %}
        {% set vars.M9 = vars.M9 + 1.0 %}
        
        -- Second part of the iteration
        {% set vars.C9 = vars.M9 * (input.B - vars.M9) * input.X / (input.A + 2.0 * vars.M9 - 1.0) / (input.A + 2.0 * vars.M9) %}
        {% set vars.A1 = vars.A0 + vars.C9 * vars.A1 %}
        {% set vars.B1 = vars.B0 + vars.C9 * vars.B1 %}
        
        -- Normalize values
        {% set vars.A0 = vars.A0 / vars.B1 %}
        {% set vars.B0 = vars.B0 / vars.B1 %}
        {% set vars.A1 = vars.A1 / vars.B1 %}
        {% set vars.B1 = 1.0 %}
        
        -- Check convergence
        {% if dbt_stat_test._abs((vars.A1 - vars.A2) / vars.A1) <= tolerance %}
            {% break %}
        {% endif %}
    {% endfor %}

    {{ return(vars.A1 / input.A) }}
{% endmacro %}




