
find_delta <- function(cv_dat, beta, delta_vec){
  x = data.frame("intercept" = 1, cv_dat[, -1])
  if (length(beta) != ncol(x)){
    x$male = NULL
  }
  y = cv_dat[, 1]
  accuracy = c()
  for(d in delta_vec){
    rates = contingency_table(x, y, beta, d, ndraws = 0, type = "sth")
    if(class(rates) != "list"){
      accuracy = c(accuracy, 0)
    }else{
      acc = (rates$tp + rates$tn)/sum(rates$t)
      accuracy = c(accuracy, acc)
    }
  }
  delta = delta_vec[which(accuracy == max(accuracy))]
  return(delta)
}


sample_norm <- function(x, beta, cov_x, ndraws){
  sd = t(beta)%*%cov_x%*%beta
  if (nrow(x) == 1){
    y = sum(x*beta)
    draws = rnorm(ndraws, y, sd)
  }else{
    x = as.matrix(x)
    y = x%*%beta
    draws = apply(y, 1, function(r) rnorm(ndraws, r, sd))
    draws = as.vector(t(as.matrix(draws)))
  }
  return(draws)
}

pred_constrain <- function(x, beta, ndraws){
  beta_M = beta$beta_M
  beta_L = beta$beta_L 
  beta_R1 = beta$beta_R1
  beta_R2 = beta$beta_R2
  beta_R3 = beta$beta_R3
  beta_Y = beta$beta_Y
  
  # M | A, C
  x_M = x[, c(1, 2, 8:10)]
  cov_M = cov(x_M)
  
  # L | M, A, C
  x_L = x[, c(1:3, 8:10)]
  cov_L = cov(x_L)
  
  # R1 | L, M, A, C
  x_R1 = x[, c(1:4, 8:10)]
  cov_R1 = cov(x_R1)
  
  ypred = c()
  for (i in 1:nrow(x)){
    # M | A, C
    yM_s = sample_norm(x_M[i, ], beta_M, cov_M, ndraws)
    # yM_s = as.vector(t(as.matrix(yM_s)))
    
    # L | M, A, C
    xL = do.call("rbind", replicate(ndraws, x_L[i, ], simplify = FALSE))
    xL$married = yM_s
    yL_s = sample_norm(xL, beta_L, cov_L, ndraws)
    
    # R1 | L, M, A, C
    # xR1 = do.call("rbind", replicate(ndraws^2, x_R1[i, ], simplify = FALSE))
    xR1 = t(matrix(rep(as.numeric(x_R1[i, ]), ndraws^2), nrow = ncol(x_R1)))
    xR1[, 3] = rep(yM_s, ndraws)
    xR1[, 4] = yL_s
    yR1_s = sample_norm(xR1, beta_R1, cov_R1, ndraws)
    
    # R2 | L, M, A, C
    yR2_s = sample_norm(xR1, beta_R2, cov_R1, ndraws)
    
    # R3 | L, M, A, C
    yR3_s = sample_norm(xR1, beta_R3, cov_R1, ndraws)
    
    # Y | R, L, M, A, C
    # xY = do.call("rbind", replicate(ndraws^3, x[i, ], simplify = FALSE))
    xY = t(matrix(rep(as.numeric(x[i, ]), ndraws^3), nrow = ncol(x)))
    xY[, 3] = rep(yM_s, ndraws^2)
    xY[, 4] = rep(yL_s, ndraws)
    xY[, 5] = yR1_s
    xY[, 6] = yR2_s
    xY[, 7] = yR3_s
    xY = as.matrix(xY)
    yY_hat = 1/(1+exp(-xY%*%beta_Y))
    # yY_hat = matrix(yY_hat, nrow = nrow(x))
    yhat = mean(yY_hat)
    ypred = c(ypred, yhat)
    # cat(i, "\n")
  }
  
  return(ypred)
}


contingency_table <- function(x, y, beta, delta, ndraws, type){
  if (type == "constrained"){
    ypred = pred_constrain(x, beta, ndraws)
  }else{
    x = as.matrix(x)
    ypred = 1/(1+exp(-x%*%beta))
  }
  idx = which(ypred > delta)
  if (length(idx) == length(y) | length(idx) == 0) return(0)
  ypred[idx] = 1
  ypred[-idx] = 0
  
  t = table(Predictions = ypred, TrueLabels = y)
  tpr = t[2, 2]/(t[1, 2] + t[2, 2])
  fnr = t[1, 2]/(t[1, 2] + t[2, 2])
  fpr = t[2, 1]/(t[1, 1] + t[2, 1])
  tnr = t[1, 1]/(t[1, 1] + t[2, 1])
  return(list(t = t, 
              tp = t[2, 2],
              fn = t[1, 2], 
              fp = t[2, 1], 
              tn = t[1, 1], 
              tpr = tpr, 
              fnr = fnr, 
              fpr = fpr, 
              tnr = tnr))
}

compute_accuracy <- function(perf){
  accuracy = (perf$tp + perf$tn)/sum(perf$t)
  return(accuracy)
}




