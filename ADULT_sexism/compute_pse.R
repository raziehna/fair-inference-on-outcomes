

compute_pse <- function(beta_M,beta_L,beta_R1,beta_R2,beta_R3,beta_Y){
  
  y_a = beta_Y[2]
  y_m = beta_Y[3]
  y_l = beta_Y[4]
  y_r1 = beta_Y[5]
  y_r2 = beta_Y[6]
  y_r3 = beta_Y[7]
  r1_m = beta_R1[3]
  r1_l = beta_R1[4]
  r2_m = beta_R2[3]
  r2_l = beta_R2[4]
  r3_m = beta_R3[3]
  r3_l = beta_R3[4]
  l_m = beta_L[3]
  m_a = beta_M[2]
 
  pse_eff=exp(y_a+y_m*m_a+y_l*l_m*m_a+y_r1*(r1_m*m_a+r1_l*l_m*m_a)+y_r2*(r2_m*m_a+r2_l*l_m*m_a)+y_r3*(r3_m*m_a+r3_l*l_m*m_a))
  
  return(as.numeric(pse_eff))
}



