###################################
## fit the specified stan model
## to the specified clean dataset,
## and save the result as an .Rds
## file
##
####################################


## set up hyperparameters for models

debug <- FALSE ## set to TRUE to diagnose sampler problems

hyperparam_list <- list(
    intercept_prior_mean = 4, # official dose was 10^5 TCID50
    intercept_prior_sd = 1,
    decay_rate_prior_mean = 0.5,
    decay_rate_prior_sd = 4,
    lower_lim_decay_rate = 0,
    sigma_prior_mean = 0,
    sigma_prior_sd = 2,
    virus_decay_rate_mean_prior_mean = 0.25,
    virus_decay_rate_mean_prior_sd = 1,
    virus_decay_rate_sd_prior_mean = 0,
    virus_decay_rate_sd_prior_sd = 0.1,
    titer_prior_mean = 3,
    titer_prior_sd = 3,
    first_dilution = 0,
    last_dilution = 7,
    debug = debug)



## read command line args
args <- commandArgs(trailingOnly=TRUE)
model_src_path <- args[1]
titer_data_path <- args[2]
mcmc_output_path <- args[3]


## set stan options
n_cores <- parallel::detectCores()
options(mc.cores = n_cores)
rstan_options(auto_write = TRUE)
niter <- 2000
nchains <- n_cores
adapt_d <- 0.8
max_tree <- 15
fixed_seed <- 23032
inits_seed <- 13
set.seed(inits_seed) ## R's rng set for random inits

if (debug) {
    nchains <- 1
    niter <- 500
}


## calculate transformed data
replicates <- dat %>%
    group_by(trial_unique_id) %>%
    summarise(replicates = max(replicate),
              condition_name = factor(paste(virus, material))[1])

replicates$condition_id = as.numeric(replicates$condition_name)

replicates <- replicates %>%
    group_by(condition_id) %>%
    add_tally()

n_experiments <- max(dat$trial_unique_id)
n_experiments_check <- length(unique(dat$trial_unique_id))

if(abs(n_experiments - n_experiments_check) > 0.5){
    cat('warning: different number of unique ids from max unique id:',
        'max:', n_experiments, 'number unique', n_experiments_check,
        '\n')
}

n_conditions <- max(replicates$condition_id)
n_experiments_in_condition <- replicates$n


## make observation lists and set initial values    
observation_data_list <- list(
    n_total_datapoints = length(dat$log10_titer),
    observed_log_titers = dat$log10_titer,
    detection_limit_log_titer = dat$detection_limit_log10_titer)
    
init_val <- lapply(
    1:nchains,
    function(x){ list(decay_rate = runif(n_experiments, 0, 0.2),
                      sigma = runif(n_experiments, 20, 30),
                      virus_slope_mean = runif(n_conditions, 0, 0.2))})

## make data into list
general_data_list <- list(
    n_experiments = n_experiments,
    n_conditions = n_conditions,
    n_replicates = replicates$replicates[1],
    n_experiments_in_condition = n_experiments_in_condition,
    condition_id = replicates$condition_id,
    experiment_id = dat$trial_unique_id,
    replicate_id = dat$replicate,
    times = dat$time,
    n_wells = dat$n_wells)

## pass stan specific data,
## shared data, and hyperparams
stan_data <- c(
    observation_data_list,
    general_data_list,
    hyperparam_list)




