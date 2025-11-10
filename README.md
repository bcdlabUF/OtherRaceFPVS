OREP READ ME 

Data and code for the Other Race Effect FPVS (OREP) study can be found in Databrary and Github. This code and data were used to generate all figures and statistics used in Wallsinger et al. (2025). This project also had a broader longitudinal training component that was not analyzed as part of the current study, but information related to this larger study may also be found in the data repositories. 
Methods, final statistics, and figures can be seen in the final published manuscript at https://doi.org/10.1002/dev.70050 

Databrary (Databrary) 
* Links to full face stimulus set, frequency tagging Github, final published paper, code GitHub
* Folder: EEG Data
  * Data_NamingConventions: Excel spreadsheet that explains all abbreviations used when labeling the columns for all data files.
  * .csv files of final data that went into SPSS and R Studio analyses
    * BayesianData_BaseFrequency: Data used to run the Bayesian ANOVA for the 6 Hz base frequency. This same data was used in SPSS to run the frequentist ANOVA also. 
    * BayesianData_OddballFrequency: Data used to run the Bayesian ANOVA for the 1.2 Hz oddball frequency. This same data was used in SPSS to run the frequentist ANOVA also.
    * Plotting_Data: Data used for the R Plotting Code to create pirate plots
    * Note: All of this data is the same, just in slightly different formats based on what was needed for the analysis/plotting code. 

GitHub (https://github.com/bcdlabUF/OtherRaceFPVS)
* Experimental Paradigm
  *OREP_SSVEP_face_discrimination_vpixx.m: Final experiential paradigm created with MATLAB PsychToolbox. 
* EEG Preprocessing
  * OREP_Preprocessing.m: Code used for preprocessing all EEG data. Output will be the data mats for each individual participant and an excel spreadsheet with all of the data quality metrics. There are several dependencies needed in order to run this code. Some are publicly available (EEGlab, HAPPE pipeline) but you will also need the files below:
    * OREP_flex_slidewin_1mat.m: Code used during the preprocessing pipeline to apply the frequency-tagging toolbox. You must have this added to your path before running the preprocessing pipeline. More information about freq-tag can be found at https://github.com/csea-lab/freqTag 
    * GSN-HydroCel-129.sfp: Channel location file for the Geodesic 129 electrode net  
    * .txt Files: One for each race/ethnic group (AfAmerican, Asian, Caucasian, Hispanic). Used during designating trial types. 
    * OREPpreproInfo.mat: Data mat created from an excel spreadsheet. Contains columns for SubNo (subject number), age, race (for familiarity coding), and bookNo (the book itself doesn t matter for this study, but these are what was used to determine which race/ethnic groups were familiar/unfamiliar and given individual/category labels for the broader study)
* MATLAB Code 
  * OREP_n49.m: MATLAB file used to export data for the final 49 participants included in the final sample for the manuscript. This also contains all of the plotting code used to create the figures in the manuscript. It will require several dependencies listed below. 
    * elec109.mat: Mat file used to determine the index of each electrode in the 129 original net montage to the 109 montage with the outer band removed. The electrode numbers used when the outer band is removed will not match the original numbers. 
    * EGI_109.spl: spline file used to create the head plots based on the 109-electrode montage. 
    * OREP_n49.mat: Mat file that will read in the data for the final 49 participants separated by frequency and age. File too large for GitHub. Contact lscott@ufl.edu or gwallsinger@ufl.edu for access to these files. 
    * Note: text, color, and font for figures were all edited outside of MATLAB using an image editing software. 
* R Code
  * BayesianANOVA_Code: R file with code used to run the Bayesian ANOVAs for both the base and oddball frequency. All packages needed to run this code are labeled at the top of the script. 
  * SensitivityAnalysis_Code: R file used to calculate the minimal effect size the data was able to detect. Degrees of freedom were taken from the SPSS output. All packages needed to run this code and labeled at the top of the script. 
  * Note: The frequentist ANOVAs were run using IBM SPSS Statistics 29.0 using the specifications found in the final manuscript. 
  * Plotting_Code: R file containing the script needed to create the pirate plots for the final manuscript figures. 
    * Note: colors, font, and text for figures were all edited outside of R using an image editing software. 
* Audio
  * In this folder are audio files that were used for a different aspect of a broader study that were not analyzed as part of the current study 
  * Distractor folder holds the audio clips paired with images designed to redirect infants  attention back to the screen during the FPVS task. 
* Images
  * The final images used in the study for each race/ethnic group. Files are labeled by race/ethnic group, model number, and luminance change from baseline. 
* New Lists 
  * This folder contains .txt files corresponding to books used as part of the broader project and are not needed for anything related to the current study. 
