setwd("C:/Users/walls/OneDrive/Desktop/Lab Projects/OREP/Data")

# Load required packages
library(pwr)

#####Notes#####
# Familiarity, Age, Age x Familiarity all have same parameters for both frequencies 
# ROI, Age x ROI, Familiarity x ROI, and Familiarity x Age x ROI all have the same parameters for both frequencies

###### Familiarity Sensitivity Analysis ######
u <- 1  
v <- 47  
alpha <- 0.05  
power <- 0.80  

# Minimum effect size
sensitivity_result <- pwr.f2.test(u = u, v = v, sig.level = alpha, power = power)
print(sensitivity_result)

# Convert to eta-squared
eta2_detectable <- sensitivity_result$f2 / (1 + sensitivity_result$f2)
print(eta2_detectable)

##### ROI Sensitivity Analysis ##### 
u <- 2  
v <- 94  
alpha <- 0.05  
power <- 0.80  

# Minimum effect size
sensitivity_result <- pwr.f2.test(u = u, v = v, sig.level = alpha, power = power)
print(sensitivity_result)

# Convert to eta-squared
eta2_detectable <- sensitivity_result$f2 / (1 + sensitivity_result$f2)
print(eta2_detectable)

###### Age Sensitivity Analysis ##### 
u <- 1  # 
v <- 47 
alpha <- 0.05  
power <- 0.80  

# Minimum effect size
sensitivity_result <- pwr.f2.test(u = u, v = v, sig.level = alpha, power = power)
print(sensitivity_result)

# Convert to eta-squared
eta2_detectable <- sensitivity_result$f2 / (1 + sensitivity_result$f2)
print(eta2_detectable)



