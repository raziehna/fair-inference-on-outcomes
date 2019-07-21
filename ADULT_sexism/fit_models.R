

fit_logistic <- function(dat, fmla){
  beta = glm(fmla, dat, family = "binomial")$coefficients
  return(beta)
}

fit_regression <- function(dat, fmla){
  beta = lm(fmla, dat)$coefficients
  return(beta)
}

fit_models <- function(dat,fmla_M, fmla_L, fmla_R1,fmla_R2,fmla_R3,fmla_Y){
  beta_M = fit_regression(dat, fmla_M)
  beta_L = fit_regression(dat, fmla_L)
  beta_R1 = fit_regression(dat, fmla_R1)
  beta_R2 = fit_regression(dat, fmla_R2)
  beta_R3 = fit_regression(dat, fmla_R3)
  beta_Y = fit_logistic(dat, fmla_Y)
  
  return(list(beta_M=beta_M, 
              beta_L=beta_L, 
              beta_R1=beta_R1, 
              beta_R2=beta_R2, 
              beta_R3=beta_R3,
              beta_Y=beta_Y))
}

