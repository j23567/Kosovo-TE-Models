'Defining Functions'
# I. General functions for data manipulation --------------------------------------------------------
# 1.1 Filtering columns ---------------------------------------------------
filter_columns <- function(data) {
  col_names <- colnames(data)
  # Define the pattern to include columns with "_adjusted" suffix
  include_pattern_adjusted <- "_adjusted$"
  # Define the pattern to include columns that start with "calc_"
  include_pattern_calc <- "^calc_"
  # Define the columns that you always want to keep
  cols_to_keep <- c("weight")
  # Find columns with the suffix "_adjusted"
  adjusted_cols <- col_names[grepl(include_pattern_adjusted, col_names)]
  # Find columns that start with "calc_"
  calc_cols <- col_names[grepl(include_pattern_calc, col_names)]
  # Combine the predefined columns, "_adjusted" columns, and "calc_" columns
  cols_to_keep <- c(cols_to_keep, adjusted_cols, calc_cols)
  # Filter the data to keep only the specified columns
  filtered_data <- data[, ..cols_to_keep, with = FALSE]
  return(filtered_data)
}

# 1.2 Weighting Function --------------------------------------------------
cal_weighting_fun <- function(sample_data, weights, growth_factors, columns_to_process) {
  # Debugging output
  print(paste("Number of rows in sample_data:", nrow(sample_data)))
  print(paste("Length of weights vector:", length(weights)))
  print(paste("Is weights numeric?:", is.numeric(weights)))
  
  # Check if weights and sample_data have the same length
  if (length(weights) != nrow(sample_data)) {
    stop("Weights must be a numeric vector with the same length as the number of rows in sample_data.")
  }
  
  # Proceed with the calculations
  for (col in columns_to_process) {
    if (col == "Value") {
      sample_data[, paste0(col, "_adjusted") := sample_data[[col]] * weights * growth_factors$Value]
    } else if (col == "Quantity") {
      sample_data[, paste0(col, "_adjusted") := sample_data[[col]] * weights * growth_factors$Quantity]
    } else if (is.numeric(sample_data[[col]])) {
      sample_data[, paste0(col, "_adjusted") := sample_data[[col]] * weights]
    } else {
      warning(paste("Skipping non-numeric column:", col))
    }
  }
  
  return(sample_data)
}

# Function to determine which dataset to use based on simulation_year
get_sim_dataset <- function(current_year, simulation_year) {
  if (current_year < simulation_year) {
    return(customs_simulation_parameters_raw)
  } else {
    return(customs_simulation_parameters_updated)
  }
}

# II. Function for 'What if analysis' --------------------------------------
# 1. Function to calculate customs duties
vec_calc_customs_duties_fun <- function(Value, Effective_Customs_rate) {
  Value <- ifelse(is.na(Value), 0, Value)
  Effective_Customs_rate <- ifelse(is.na(Effective_Customs_rate), 0, Effective_Customs_rate)
  calc_customs_duties <- Value * (Effective_Customs_rate / 100)
  return(calc_customs_duties)
}

# 2. Function to calculate excise duties
vec_calc_excise_fun <- function(Quantity, Effective_Excise_rate) {
  Quantity <- ifelse(is.na(Quantity), 0, Quantity)
  Effective_Excise_rate <- ifelse(is.na(Effective_Excise_rate), 0, Effective_Excise_rate)
  calc_excise <- Quantity * Effective_Excise_rate
  return(calc_excise)
}

# 3. Function to calculate VAT
vec_calc_vat_fun <- function(Value, calc_customs_duties, calc_excise, Effective_VAT_rate) {
  Value <- ifelse(is.na(Value), 0, Value)
  Effective_VAT_rate <- ifelse(is.na(Effective_VAT_rate), 0, Effective_VAT_rate)
  calc_vat <- (Value + calc_customs_duties + calc_excise) * (Effective_VAT_rate / 100)
  return(calc_vat)
}