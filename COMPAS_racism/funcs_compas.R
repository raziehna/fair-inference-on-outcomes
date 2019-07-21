

# -------------------------------------------------------
# Compile the cpp files from the command line
# -------------------------------------------------------
# cd ~Downloads/BayesTree_/src$
# rm *.o 
# rm *.so
# R CMD SHLIB *.cpp -o BayesTree.so


# Sanity check for the constrianed bart
compute_effect <- function(bart_m, weights, r){
  yhat = colMeans(pnorm(bart_m$yhat.test))
  # Ey0 = mean(yhat[(r+1):(2*r)])
  Ey0 = mean(yhat[(r+1):(2*r)]*weights)
  Ey1m0 = mean(yhat[1:r]*weights)
  oddsRatio = (Ey1m0/(1-Ey1m0))/(Ey0/(1-Ey0))
  return(oddsRatio)
}


find_delta <- function(y, ypred, delta_vec){
  accuracy = c()
  for(d in delta_vec){
    yhat = ypred
    idx = which(ypred > d)
    if (length(idx) == length(ypred)){
      acc=0 
    }else{
      yhat[idx] = 1
      yhat[-idx] = 0
      acc = mean(yhat==y)
    } 
    accuracy = c(accuracy, acc)
  }
  delta = delta_vec[which(accuracy == max(accuracy))]
  return(delta)
}


contingency_table <- function(y, ypred, delta, k, r, char){
  if (char == "test"){
    y = y[(2*r + 1):length(y)]
    ypred = ypred[(2*r + 1):length(ypred)]
  }else{
    
  }
  idx = which(ypred > delta)
  ypred[idx] = 1
  ypred[-idx] = 0
  
  t = table(Predictions = ypred, TrueLabels = y)
  tpr = t[2, 2]/(t[1, 2] + t[2, 2])
  fnr = t[1, 2]/(t[1, 2] + t[2, 2])
  fpr = t[2, 1]/(t[1, 1] + t[2, 1])
  tnr = t[1, 1]/(t[1, 1] + t[2, 1])
  return(list(t = t, tp = t[2, 2], fn = t[1, 2], fp = t[2, 1], 
              tn = t[1, 1], tpr = tpr, fnr = fnr, fpr = fpr, tnr = tnr))
}

compute_accuracy <- function(perf){
  accuracy = (perf$tp + perf$tn)/sum(perf$t)
  return(accuracy)
}


