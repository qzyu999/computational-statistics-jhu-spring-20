###
### Required functions are at the end of the script in area labeled "Functions"
###
oilspills <- read.table(file = "oilspills.dat", header = TRUE)
x = oilspills; epsilon = 1e-10
alpha1_init = 0.7; alpha2_init = 0.5

alpha1_new <- alpha1_old <- alpha1_init  # Initialize variables
alpha2_new <- alpha2_old <- alpha2_init
convergence_flag <- TRUE; count <- 0; backtracks <- 0; alpha <- 1

### Run 1
alpha1_old <- alpha1_new; alpha2_old <- alpha2_new; alpha <- 1

# Tune alpha
alpha_tune_vec <- alpha_tuner(x = x,
                              alpha1_old_at = alpha1_old,
                              alpha2_old_at = alpha2_old,
                              alpha_at = alpha,
                              backtracks_at = backtracks)
alpha <- alpha_tune_vec[1]; backtracks <- alpha_tune_vec[2] # alpha(1) = 0.0625

# Update old / new variables
# theta_vec <- c(alpha1_old, alpha2_old) + alpha * h_fisher(x, alpha1_old, alpha2_old)
theta_vec <- c(alpha1_old, alpha2_old) + alpha * g3(x, alpha1_old, alpha2_old)
alpha1_new <- theta_vec[1]; alpha2_new <- theta_vec[2]; count <- count + 1
# alpha1(1) = 0.9188692, alpha2(1) = 2.1659375

# Check for convergence
convergence_vec <- relative_convergence(alpha1_old, alpha1_new, alpha2_old,
                                        alpha2_new, epsilon)
convergence_value <- convergence_vec[1]; convergence_flag <- convergence_vec[2]

### Run 2
alpha1_old <- alpha1_new; alpha2_old <- alpha2_new; alpha <- 1

# Tune alpha
alpha_tune_vec <- alpha_tuner(x = x, ### log(alpha1 * b1 + alpha2 * b2) : NaNs produced
                              alpha1_old_at = alpha1_old,
                              alpha2_old_at = alpha2_old,
                              alpha_at = alpha,
                              backtracks_at = backtracks)
### Debug alpha_tuner() on iteration 2
x = x; alpha1_old_at = alpha1_old; alpha2_old_at = alpha2_old; alpha_at = alpha; backtracks_at = backtracks

backtrack_flag <- TRUE  # (Re-)Initialize blacktracking variables

# while (backtrack_flag) {  # while-loop paused
  theta_test <- c(alpha1_old_at, alpha2_old_at) +
    alpha_at * g3(x, alpha1_old_at, alpha2_old_at)
  # alpha1_proposal(t=2)(b=1) = -7.646657, alpha2_proposal(t=2)(b=1) = -4.712663
  
  ### what could produce negative alphas?
  
  # log() warning occurs in this line at the start of the second iteration, first backtrack
  # t=2, b=1
  backtrack_vec <- backtrack_check(x = x,
                                   alpha1_old_btc = alpha1_old_at,
                                   alpha1_test = theta_test[1],
                                   alpha2_old_btc = alpha2_old_at,
                                   alpha2_test = theta_test[2],
                                   alpha_btc = alpha_at,
                                   backtracks_btc = backtracks_at,
                                   backtrack_flag_btc = backtrack_flag)
### Debug backtrack_check() for t=2, b=1
x = x; alpha1_old_btc = alpha1_old_at;  alpha1_test = theta_test[1];  alpha2_old_btc = alpha2_old_at
alpha2_test = theta_test[2];  alpha_btc = alpha_at;  backtracks_btc = backtracks_at;  backtrack_flag_btc = backtrack_flag

step_old <- g0(x = x,
               alpha1 = alpha1_old_btc,
               alpha2 = alpha2_old_btc)
step_test <- g0(x = x, # log() warning, NaNs produced
                alpha1 = alpha1_test,
                alpha2 = alpha2_test)
### Debug g0()
x = x; alpha1 = alpha1_test; alpha2 = alpha2_test
# g0 <- function(x = oilspills, alpha1, alpha2) {
  n <- x[,2]; b1 <- x[,3]; b2 <- x[,4]
  
# Error line here, log(alpha1 * b1 + alpha2 * b2) produces all negatives
# b1 and b2 are all positive values, while alpha1 and alpha2 are both negative
# -4.634568, -3.303951, leading to log(-x) and error.

  # sum(n * log(alpha1 * b1 + alpha2 * b2)) +
  
# below never run due to log error
  # sum(n * log(alpha1 * b1 + alpha2 * b2)) +
  #   sum(-alpha1 * b1 - alpha2 * b2) -
  #   sum(log(factorial(n)))
# }

if(step_test < step_old) {  # Check if "downhill" or sideways
  alpha_btc <- alpha_btc / 2
  backtracks_btc <- backtracks_btc + 1
} else {  # Stop tuning alpha
  backtrack_flag_btc <- FALSE
}
# return(c(alpha_btc, backtracks_btc, backtrack_flag_btc))
  
### Below never run due to log() warning  
  alpha_at <- backtrack_vec[1]; backtracks_at <- backtrack_vec[2]
  backtrack_flag <- backtrack_vec[3]
# }

### Below is never run due to log() warning
alpha <- alpha_tune_vec[1]; backtracks <- alpha_tune_vec[2]

# Update old / new variables
# theta_vec <- c(alpha1_old, alpha2_old) + alpha * h_fisher(x, alpha1_old, alpha2_old)
theta_vec <- c(alpha1_old, alpha2_old) + alpha * g3(x, alpha1_old, alpha2_old)
alpha1_new <- theta_vec[1]; alpha2_new <- theta_vec[2]; count <- count + 1

# Check for convergence
convergence_vec <- relative_convergence(alpha1_old, alpha1_new, alpha2_old,
                                        alpha2_new, epsilon)
convergence_value <- convergence_vec[1]; convergence_flag <- convergence_vec[2]

###
### Functions
###
backtrack_check <- function(x = oilspills,
                            alpha1_old_btc,
                            alpha1_test,
                            alpha2_old_btc,
                            alpha2_test,
                            alpha_btc,
                            backtracks_btc,
                            backtrack_flag_btc) {
  step_old <- g0(x = x,  # Calculate steps
                 alpha1 = alpha1_old_btc,
                 alpha2 = alpha2_old_btc)
  step_test <- g0(x = x,
                  alpha1 = alpha1_test,
                  alpha2 = alpha2_test)
  
  if(step_test <= step_old) {  # Check if "downhill" or sideways
    alpha_btc <- alpha_btc / 2
    backtracks_btc <- backtracks_btc + 1
  } else {  # Stop tuning alpha
    backtrack_flag_btc <- FALSE
  }
  return(c(alpha_btc, backtracks_btc, backtrack_flag_btc))
}

alpha_tuner <- function(x = oilspills,
                        alpha1_old_at,
                        alpha2_old_at,
                        alpha_at,
                        backtracks_at) {
  backtrack_flag <- TRUE  # (Re-)Initialize blacktracking variables
  
  while (backtrack_flag) {  # Loop until a suitable alpha is found
    theta_test <- c(alpha1_old_at, alpha2_old_at) + # trying to find first update
      alpha_at * g3(x, alpha1_old_at, alpha2_old_at)
    backtrack_vec <- backtrack_check(x = x,
                                     alpha1_old_btc = alpha1_old_at,
                                     alpha1_test = theta_test[1],
                                     alpha2_old_btc = alpha2_old_at,
                                     alpha2_test = theta_test[2],
                                     alpha_btc = alpha_at,
                                     backtracks_btc = backtracks_at,
                                     backtrack_flag_btc = backtrack_flag)
    alpha_at <- backtrack_vec[1]; backtracks_at <- backtrack_vec[2]
    backtrack_flag <- backtrack_vec[3]
  }
  return(c(alpha_at, backtracks_at))
}

### part a
# log-likelihood of Poisson
g0 <- function(x = oilspills, alpha1, alpha2) {
  n <- x[,2]; b1 <- x[,3]; b2 <- x[,4]
  sum(n * log(alpha1 * b1 + alpha2 * b2)) +
    sum(-alpha1 * b1 - alpha2 * b2) -
    sum(log(factorial(n)))
}

# dg/dalpha1
g1 <- function(x = oilspills, alpha1, alpha2) {
  n <- x[,2]; b1 <- x[,3]; b2 <- x[,4]
  sum((n * b1) / (alpha1 * b1 + alpha2 * b2)) - sum(b1)
}

# dg/dalpha2
g2 <- function(x = oilspills, alpha1, alpha2) {
  n <- x[,2]; b1 <- x[,3]; b2 <- x[,4]
  sum((n * b2) / (alpha1 * b1 + alpha2 * b2)) - sum(b2)
}

# gradient(alpha1, alpha2)
g3 <- function(x = oilspills, alpha1, alpha2) {
  return(
    matrix(
      c(g1(x, alpha1, alpha2), g2(x, alpha1, alpha2)),
      ncol = 1))
}

relative_convergence <- function(alpha1_old, alpha1_new,  # Test for convergence
                                 alpha2_old, alpha2_new, epsilon) {
  old_vec <- c(alpha1_old, alpha2_old)
  new_vec <- c(alpha1_new, alpha2_new)
  relative_convergence_criterion <- sqrt(sum((new_vec - old_vec)^2)) /
    (sqrt(sum(old_vec^2)) + epsilon)
  bool_flag <- ifelse(relative_convergence_criterion < epsilon, FALSE, TRUE)
  return(c(relative_convergence_criterion, bool_flag))
}