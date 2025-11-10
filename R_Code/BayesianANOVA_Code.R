#Set working directory 
setwd("C:/Users/walls/OneDrive/Desktop/Lab Projects/OREP/Data")
getwd()

#load packages needed 
library(BayesFactor)
library(psych)
library(dplyr)
library(tidyr)
library(coda)

#### NOTE: OREP is a lab acronym for the study and is just used as for naming conventions ####

#### Base Frequency 6 Hz ####
OREPbase <- read.csv("BayesianData_BaseFrequency.csv")

#Converting data to long format and factorizing/naming variables 
OREPbase2 <- dplyr::mutate(OREPbase, ID = row_number())
OREPbase_long <- OREPbase2 %>%
  pivot_longer(cols = 2:3, 
               names_to = "Condition", 
               values_to = "Amplitude")
OREPbase_long$Familiarity <- rep(c("Familiar", "Unfamiliar"), length.out = nrow(OREPbase_long))
OREPbase_long$Age <- as.factor(OREPbase_long$Age)
OREPbase_long$Familiarity <- as.factor(OREPbase_long$Familiarity)
OREPbase_long$ID <- as.factor(OREPbase_long$ID)  

# Check the structure of the dataframe to ensure the variables are factors
str(OREPbase_long)

#Base Bayesian ANOVA
bfOREPbase <- anovaBF(
  Amplitude ~ Age + Familiarity + Age*Familiarity + ID,  # Model
  data = OREPbase_long,  # Data frame
  whichRandom = "ID",  # Specify random effects
  whichModels = "all"  # Consider all possible models
)
bfOREPbase

# BF Inclusions
(bfincAge = bfOREPbase[4]/bfOREPbase[2])
(bfincFamiliarity = bfOREPbase[4]/bfOREPbase[1])
(bfincAgeFamInteraction = bfOREPbase[7]/bfOREPbase[4])


#### Oddball Frequency 1.2 Hz ####

OREPOddball <- read.csv("BayesianData_OddballFrequency.csv")

#Converting data to long format and factorizing/naming variables 
OREPOddball2 <- dplyr::mutate(OREPOddball, ID = row_number())
OREPOddball_long <- OREPOddball2 %>%
  pivot_longer(cols = 2:7, 
               names_to = "Condition/ROI", 
               values_to = "Amplitude")
OREPOddball_long$Familiarity <- rep(c("Familiar", "Unfamiliar"), length.out = nrow(OREPOddball_long))
OREPOddball_long$ROI <- rep(c("Left", "Left", "Medial", "Medial", "Right", "Right"), length.out = nrow(OREPOddball_long))
OREPOddball_long$Age <- as.factor(OREPOddball_long$Age)
OREPOddball_long$Familiarity <- as.factor(OREPOddball_long$Familiarity)
OREPOddball_long$ROI <- as.factor(OREPOddball_long$ROI)
OREPOddball_long$ID <- as.factor(OREPOddball_long$ID)  

# Check the structure of the dataframe to ensure the variables are factors
str(OREPOddball_long)

#Base Bayesian ANOVA
bfOREPOddball <- anovaBF(
  Amplitude ~ Age + Familiarity + ROI + ID, 
  data = OREPOddball_long, 
  whichRandom = "ID",  
  whichModels = "all"  
)
bfOREPOddball

#BF Inclusions
(oddball_bfincAge = bfOREPOddball[29]/bfOREPOddball[14])
(oddball_bfincFamiliarity = bfOREPOddball[29]/bfOREPOddball[9])
(oddball_bfincROI = bfOREPOddball[29]/bfOREPOddball[8])
















