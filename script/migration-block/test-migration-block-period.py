def linear_interpolation(period, block_timestamp, inflation_day_zero, current_period, factor_current_period, factor_next_period):
    # Calculate the start of the current period in unix time
    start_of_period = inflation_day_zero + current_period * period

    # Calculate seconds into the current period
    seconds_into_current_period = block_timestamp - start_of_period

    # Check if (period - secondsIntoCurrentPeriod) is negative
    if period - seconds_into_current_period < 0:
        print("Error: period - secondsIntoCurrentPeriod is negative!")
        return None

    # Linear interpolation calculation
    rP = (factor_current_period * (period - seconds_into_current_period) +
          factor_next_period * seconds_into_current_period)

    return rP, seconds_into_current_period


# Example usage (with placeholder values):
period = 86400  # 1 day in seconds
block_timestamp = 172800  # Example block timestamp (2 days from 0)
inflation_day_zero = 0  # Example start time
current_period = 1  # Example current period
factor_current_period = 1.0  # Placeholder factor
factor_next_period = 1.1  # Placeholder factor

rP, seconds_into_current_period = linear_interpolation(
    period, block_timestamp, inflation_day_zero, current_period, factor_current_period, factor_next_period)

if rP is not None:
    print(f"Linear interpolation result: {rP}")
    print(f"Seconds into current period: {seconds_into_current_period}")
