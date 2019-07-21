

# -------------------------------------- 
# Optimize a constrained logistic model
# --------------------------------------
constrained_mle <- function(dat,fmla_M,fmla_L,fmla_R1,fmla_R2,fmla_R3,fmla_Y,func,tau_u,tau_l){
  
  # Define the negative log likelihood function
  eval_f <- function(beta, dat, Y, R1, R2, R3, L, M, Xy, Xr1, Xr2, Xr3, Xl, Xm, func, tau_u, tau_l){
    
    beta_M = beta[1:ncol(Xm)]
    beta_L = beta[(ncol(Xm) + 1):(ncol(Xm) + ncol(Xl))]
    beta_R1 = beta[(ncol(Xm) + ncol(Xl) + 1):(ncol(Xm) + ncol(Xl) + ncol(Xr1))]
    beta_R2 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2))]
    beta_R3 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3))]
    beta_Y = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3)+1):length(beta)]
    
    names(beta_M) = colnames(Xm)
    names(beta_L) = colnames(Xl)
    names(beta_R1) = colnames(Xr1)
    names(beta_R2) = colnames(Xr2)
    names(beta_R3) = colnames(Xr3)
    names(beta_Y) = colnames(Xy)
    
    M = as.matrix(M)
    L = as.matrix(L)
    R1 = as.matrix(R1)
    R2 = as.matrix(R2)
    R3 = as.matrix(R3)
    Y = as.matrix(Y)
    
    f =  t(M-Xm%*%beta_M)%*%(M-Xm%*%beta_M)+t(L-Xl%*%beta_L)%*%(L-Xl%*%beta_L)+t(R1-Xr1%*%beta_R1)%*%(R1-Xr1%*%beta_R1)+t(R2-Xr2%*%beta_R2)%*%(R2-Xr2%*%beta_R2)+t(R3-Xr3%*%beta_R3)%*%(R3-Xr3%*%beta_R3)+sum(Y*log(1+exp(-Xy%*%beta_Y))+(1-Y)*log(1+exp(Xy%*%beta_Y))) 
    return(f/nrow(dat))
  }
  
  # Define the inequlity constraint 
  eval_g_ineq <- function(beta, dat, Y, R1, R2, R3, L, M, Xy, Xr1, Xr2, Xr3, Xl, Xm, func, tau_u, tau_l){
    beta_M = beta[1:ncol(Xm)]
    beta_L = beta[(ncol(Xm) + 1):(ncol(Xm) + ncol(Xl))]
    beta_R1 = beta[(ncol(Xm) + ncol(Xl) + 1):(ncol(Xm) + ncol(Xl) + ncol(Xr1))]
    beta_R2 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2))]
    beta_R3 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3))]
    beta_Y = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3)+1):length(beta)]
    
    names(beta_M) = colnames(Xm)
    names(beta_L) = colnames(Xl)
    names(beta_R1) = colnames(Xr1)
    names(beta_R2) = colnames(Xr2)
    names(beta_R3) = colnames(Xr3)
    names(beta_Y) = colnames(Xy)
    
    pse = func(beta_M,beta_L,beta_R1,beta_R2,beta_R3,beta_Y)
    eval_g =  c(pse - tau_u, tau_l - pse)
    return(eval_g)
  }
  
  # Prepare the data
  Xm = as.matrix(model.matrix(fmla_M, data=model.frame(dat)))
  Xl = as.matrix(model.matrix(fmla_L, data=model.frame(dat)))
  Xr1 = as.matrix(model.matrix(fmla_R1, data=model.frame(dat)))
  Xr2 = as.matrix(model.matrix(fmla_R2, data=model.frame(dat)))
  Xr3 = as.matrix(model.matrix(fmla_R3, data=model.frame(dat)))
  Xy = as.matrix(model.matrix(fmla_Y, data=model.frame(dat)))
  M = model.frame(fmla_M,dat)[, 1]
  L = model.frame(fmla_L,dat)[, 1]
  R1 = model.frame(fmla_R1,dat)[, 1]
  R2 = model.frame(fmla_R2,dat)[, 1]
  R3 = model.frame(fmla_R3,dat)[, 1]
  Y = model.frame(fmla_Y,dat)[, 1]
  
  # Initialize parameters
  beta_M_0 = rep(0, ncol(Xm))
  beta_L_0 = rep(0, ncol(Xl))
  beta_R1_0 = rep(0, ncol(Xr1))
  beta_R2_0 = rep(0, ncol(Xr2))
  beta_R3_0 = rep(0, ncol(Xr3))
  beta_Y_0 = rep(0, ncol(Xy))
  # names(beta_Y_start) = colnames(Xy)
  
  beta_start = c(beta_M_0, beta_L_0, beta_R1_0, beta_R2_0, beta_R3_0, beta_Y_0)
  
  # Solve the constrained optimization problem
  mle = nloptr(x0=beta_start, 
               eval_f=eval_f, 
               eval_g_ineq=eval_g_ineq,
               opts = list("algorithm"="NLOPT_LN_COBYLA","xtol_rel"=1.0e-8, "maxeval"=5000),
               dat=dat, Y=Y, R1=R1, R2=R2, R3=R3, L=L, M=M, 
               Xy=Xy, Xr1=Xr1, Xr2=Xr2, Xr3=Xr3, Xl=Xl, Xm=Xm, 
               func=func, tau_u=tau_u, tau_l=tau_l)
  
  # Returnt parameters
  beta = mle$solution
  beta_M = beta[1:ncol(Xm)]
  beta_L = beta[(ncol(Xm) + 1):(ncol(Xm) + ncol(Xl))]
  beta_R1 = beta[(ncol(Xm) + ncol(Xl) + 1):(ncol(Xm) + ncol(Xl) + ncol(Xr1))]
  beta_R2 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2))]
  beta_R3 = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+1):(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3))]
  beta_Y = beta[(ncol(Xm)+ncol(Xl)+ncol(Xr1)+ncol(Xr2)+ncol(Xr3)+1):length(beta_start)]
  
  names(beta_M) = colnames(Xm)
  names(beta_L) = colnames(Xl)
  names(beta_R1) = colnames(Xr1)
  names(beta_R2) = colnames(Xr2)
  names(beta_R3) = colnames(Xr3)
  names(beta_Y) = colnames(Xy)
  
  return(list(beta_M=beta_M, 
              beta_L=beta_L, 
              beta_R1=beta_R1, 
              beta_R2=beta_R2, 
              beta_R3=beta_R3,
              beta_Y=beta_Y))
}


