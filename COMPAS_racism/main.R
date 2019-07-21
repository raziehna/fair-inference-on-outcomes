
rm(list=ls(all=TRUE))
cat("\f") 

set.seed(0)

setwd("~/Downloads/Fairness_code/COMPAS_racism/")

library(devtools)
load_all("BayesTree_OddsRatio/")
source("funcs_compas.R")

k = floor(0.9*5278)
r = floor(0.9*k)
ndraws = 50
nskip = 50
tau_U = 1.06
tau_L = 0.94


# -------------------------------------
# Data
# -------------------------------------
compas_dat <- read.csv("compas_preprocessed.csv", sep = ",")
compas_dat$compas = NULL
compas_dat$AM = compas_dat$race*compas_dat$priors
compas_dat$AC1 = compas_dat$race*compas_dat$gender
compas_dat$AC2 = compas_dat$race*compas_dat$age
compas_dat$C1C2 = compas_dat$gender*compas_dat$age
compas_dat = data.frame(compas_dat$race, compas_dat$AM, compas_dat$AC1, compas_dat$AC2,  
                        as.double(compas_dat$gender), as.double(compas_dat$age), 
                        as.double(compas_dat$C1C2),
                        compas_dat$priors, compas_dat$recid)
colnames(compas_dat) = c("A", "AM", "AC1", "AC2", "C1", "C2", "C1C2", "M", "y")
idx_1 = sample(1:nrow(compas_dat), k)
train = compas_dat[idx_1, ]
idx_2 = sample(1:k, r)
dat = train[idx_2, ]
cv_dat = train[-idx_2, ]
test_dat = compas_dat[-idx_1, ]


# ------------------------------------------------------- 
# Important Features
# ------------------------------------------------------- 
fmla = as.formula("y ~ -1 + A + AM + AC1 + AC2 + C1C2 + M")
summary(glm(fmla, compas_dat, family = binomial))


# ------------------------------------------------------- 
# Find the weights (If A = 0 then w = 1/p(A = 0 | C))
# -------------------------------------------------------
# A | C
xA = dat[, 5:7] # no C1C2
yA = dat[, 1]
bart_AC = bart(xA, yA, xA, ndpost=ndraws, nskip=nskip, verbose=FALSE)
p = colMeans(pnorm(bart_AC$yhat.test))
weights = rep(0, r)
weights[yA == 0] = 1/(1-p[yA == 0])
weights[yA == 1] = 0


# -------------------------------------
# Y vs A, M, C 
# -------------------------------------
# FULL model 
xY = dat[, -c(5:6, ncol(dat))]
xY_cv = cv_dat[, -c(5:6, ncol(dat))]
xY_test = test_dat[, -c(5:6, ncol(dat))]
yY = dat$y
xtest_1 = cbind(A = 1, AM = 1, AC1 = 1, AC2 = 1, xY[,-c(1:4)])
xtest_0 = cbind(A = 0, AM = 0, AC1 = 0, AC2 = 0, xY[,-c(1:4)])
xtest = rbind(xtest_1, xtest_0, xY_cv, xY_test) 
bart_full = bart(xY, yY, xtest, ndpost=ndraws, nskip=nskip, verbose=FALSE)
yhat_full = colMeans(pnorm(bart_full$yhat.test))


# DROP-A model
xY_drop = xY[, -c(1:4)]
xtest_drop = xtest[, -c(1:4)]
bart_drop = bart(xY_drop, yY, xtest_drop, ndpost=ndraws, nskip=nskip, verbose=FALSE)
yhat_drop = colMeans(pnorm(bart_drop$yhat.test))

# Constrained model
bart_constrain = bart2(xY,yY,xtest,mass=weights,tau_U=tau_U,tau_L=tau_L,ndpost=ndraws,nskip=nskip)
yhat_constrain = colMeans(pnorm(bart_constrain$yhat.test))


# -------------------------------------
# Compute effects 
# -------------------------------------
compute_effect(bart_full, weights, r) # 1.307489
compute_effect(bart_constrain, weights, r) # 0.9994268


# ------------------------------------- 
# Find delta 
# -------------------------------------
y_cv = c(cv_dat$y, test_dat$y)
delta_vec = seq(0.05, 0.95, by=0.05)
(delta_full = find_delta(y_cv, yhat_full[(2*r+1):length(yhat_full)], delta_vec))
delta_drop = delta_full
delta_constrain = 0.5


# -------------------------------------------------------
# Compare accuracies 
# -------------------------------------------------------
y_test = c(rep(dat$y, 2), cv_dat$y, test_dat$y)

pref_full = contingency_table(y_test, yhat_full, delta_full, k, r, char="test")
compute_accuracy(pref_full) # 0.6769691

pref_drop = contingency_table(y_test, yhat_drop, delta_drop, k, r, char="test")
compute_accuracy(pref_drop) #  0.6450648

pref_constrain = contingency_table(y_test, yhat_constrain, delta_constrain, k, r, char="test")
compute_accuracy(pref_constrain)# 0.664008

