#Set working directory 
setwd("C:/Users/walls/OneDrive/Desktop/Lab Projects/OREP/Data")
getwd()

#### NOTE: OREP is a lab acronym and is only used for naming convention reasons #### 

#Load required packages 
library(dplyr)
library(reshape2)
library(yarrr)

OREP <- read.csv("Plotting_Data.csv")

OREPplot1 <- subset(OREP, select = c(10,11))
OREPplot1b <- dplyr::mutate(OREPplot1, ID = row_number())
OREPplot1c <- melt(OREPplot1b, id = 'ID')
colnames(OREPplot1c) <- c("ID", "Condition", "Amplitude")

#### Base Frequency 6 Hz Age x Familiarity ####
#Data wrangling to get into the right format for this plot 
OREPplot2 <- subset(OREP, select = c(1,10,11))
OREPplot2b <- dplyr::mutate(OREPplot2, ID = row_number())
OREPplot2c <- melt(OREPplot2b, id.vars = c("Age", "ID"), measure.vars = c("Base_M_F", "Base_M_U"))

#pirate plot 
Plot2b_color <- yarrr::pirateplot(formula = Amplitude ~ Condition + Age,
    data = OREPplot2c,
    pal = piratepal("basel")[c(1,2)], 
    main = "6-Month vs. 9-Month \n6Hz + Harmonics",
    xlab = "Medial Occipital Sensors",
    ylab = "Amplitude (µV)",
    inf.method = "ci",
    bean.b.col = "gray17",
    bean.b.o = 1, 
    inf.b.col = "black",
    inf.f.o = 0,
    point.col = "black",
    point.cex = 0.5,
    point.o = 0.5,
    bar.f.o = 0.5, 
    bar.b.o = 0, 
    gl.col = 0, 
    bty = 'n'
)
box(bty="l")

#### 1.2 Hz ROI x Age ####
#read in ROI data 
OREP_ROI <- read.csv("Plotting_Data.csv")
#data wrangling to get the right format for this plot 
OREP_ROI <- OREP_ROI %>%
  mutate(AverageLeft = (Odd_L_F + Odd_L_U) / 2)
OREP_ROI <- OREP_ROI %>%
  mutate(AverageMid = (Odd_M_F + Odd_M_U) / 2)
OREP_ROI <- OREP_ROI %>%
  mutate(AverageRight = (Odd_R_F + Odd_R_U) / 2)
OREP_ROIxAge1 = subset(OREP_ROI, select = c(1,14,15,16))
OREP_ROIxAge <- melt(OREP_ROIxAge1, id = 'Age')
colnames(OREP_ROIxAge) <- c("Age", "Location", "Amplitude")

#this sets limits on the y-range to include the value needed for the noise line
y_range = range(OREP_ROIxAge$Amplitude)
y_range[1] <- min(y_range[1], 0.55)
y_range[2] <- max(y_range[2], 11)

# custom y-axis tick marks 
custom_y_ticks <- seq(1, 11, by = 1)
custom_y_labels <- as.character(custom_y_ticks)

# pirate plot 
ROI_color <- yarrr::pirateplot(
  formula = Amplitude ~ Location + Age, 
  data = OREP_ROIxAge,
  pal = "basel", 
  main = "1.2Hz + Harmonics", 
  xlab = "ROI",
  ylab = "Amplitude (µV)",
  inf.method = "ci",
  bean.b.col = "gray17",
  bean.b.o = 1, 
  inf.b.col = "black",
  inf.f.o = 0,
  point.col = "black",
  point.cex = 0.5,
  point.o = 0.5,
  bar.f.o = 0.5, 
  bar.b.o = 0, 
  gl.col = 0, 
  bty = 'n',
  ylim = y_range,
  yaxt = "n"
)
box(bty = "l")

# Add dashed horizontal line at average noise 
abline(h = 0.44618159, lty = 2, col = "black")
axis(2, at = custom_y_ticks, labels = custom_y_labels)


#### 1.2 Hz Oddball by ROI #### 
#data wrangling into the right format for this plot 
OREP_ROIa <- subset(OREP_ROI, select = c(14,15,16))
OREP_ROIb <- dplyr::mutate(OREP_ROIa, ID = row_number())
OREP_ROIc <- melt(OREP_ROIb, id = 'ID')
colnames(OREP_ROIc) <- c("ID", "Location", "Amplitude")

#pirate plot 
ROI_color <- yarrr::pirateplot(
  formula = Amplitude ~ Location, 
  data = OREP_ROIc,
  pal = "basel", 
  main="1.2Hz + Harmonics", 
  xlab = "ROI",
  ylab = "Amplitude (µV)",
  inf.method = "ci",
  bean.b.col = "gray17",
  bean.b.o = 1, 
  inf.b.col = "black",
  inf.f.o = 0,
  point.col = "black",
  point.cex = 0.5,
  point.o = 0.5,
  bar.f.o = 0.5, 
  bar.b.o = 0, 
  gl.col = 0, 
  bty = 'n'
)
box(bty="l")

