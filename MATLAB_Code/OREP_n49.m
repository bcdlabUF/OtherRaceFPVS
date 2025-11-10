%% Exporting EEG Data for Analysis in SPSS and R 
%% Data Import 
%Data was sent by Maeve Boylan as a .mat file 
load('/Users/gwallsinger/Desktop/OREP/MATLAB Files/orep_n49.mat')
%this has the data for all 49 included participants 
%this also loads in the faxis information needed for plotting
%data is separated by age and frequency 
%109 electrodes x frequency (400 or 2000) x 4 race conditions x 49 subj 
%% ROI selection in 109 montage 
load('/Users/gwallsinger/Desktop/MATLAB Resources/elec109.mat')
%Because outerband was removed, we need the index of the electrodes in the 109 file 
% left roi
find(elec109==58)
find(elec109==64)
find(elec109==65)
% medial roi
find(elec109==74)
find(elec109==75)
find(elec109==82)
% right roi
find(elec109==90)
find(elec109==95)
find(elec109==96)
%combine the rois into one object 
newelecs_LMR = [62 59 58; 66 67 73; 79 80 84];
%% Actual Data Export 
%in the second dimensions, sum the harmonics selected drivd on the topographies
%columns will be age, then organized by frequency first (all driv then all oddball)
%then by ROI (L first, then M, then R) 
%finally by familiarity (familiar then unfamiliar) 
%this is how I created the column names for the data spreadsheets on teams/Databrary 
ages = [ones(25,1)*6; ones(24,1)*9];
data4spss_orep = [];
for freq = 1:2
    for roi = 1:3
        if freq == 1, tmp1 = [squeeze(nanmean(sum(orep_n49_odd6mo(newelecs_LMR(roi,:),9:8:33,:,:),2),1))'; squeeze(nanmean(sum(orep_n49_odd9mo(newelecs_LMR(roi,:),9:8:33,:,:),2),1))'];
        elseif freq == 2, tmp1 = [squeeze(nanmean(sum(orep_n49_driv6mo(newelecs_LMR(roi,:),9:8:25,:,:),2),1))'; squeeze(nanmean(sum(orep_n49_driv9mo(newelecs_LMR(roi,:),9:8:25,:,:),2),1))'];
        end
        data4spss_orep = [data4spss_orep tmp1];
    end
end
data4spss_orep = [ages data4spss_orep];

%% Matrix with everyone for oddball to get signal to noise
orep_n49_oddall = cat(4,orep_n49_odd6mo, orep_n49_odd9mo);
%% Average Signal + Noise 
%Average signal
%signal_bins = [9 17 25 33];
ages = [ones(25,1)*6; ones(24,1)*9];
signal_average = [];
for roi = 1:3 
    tmp2 = [squeeze(mean(mean(sum(orep_n49_odd6mo(newelecs_LMR(roi,:),[9 17 25 33],:,:),2),3),1)); ...
            squeeze(mean(mean(sum(orep_n49_odd9mo(newelecs_LMR(roi,:),[9 17 25 33],:,:),2),3),1))];
    signal_average = [signal_average, tmp2];
end
signal_average = [ages signal_average];

%% Finding avg noise around each harmonic and avg them together 
%find 6 bins for surrounding each harmonic (exlcuding bins immediately adjacent to the signal bin)
%average two bins for each harmonic 
%add together the 4 averages 
%do this for each of the 3 harmonics 

noisebins1_2 = [5 6 7 11 12 13];
noisebins2_4 = [13 14 15 19 20 21];
noisebins3_6 = [21 22 23 27 28 29];
noisebins4_8 = [29 30 31 35 36 37];
noisebins = [noisebins1_2; noisebins2_4; noisebins3_6; noisebins4_8];

ages = [ones(25,1)*6; ones(24,1)*9];

noise_average = [];
for roi = 1:3 
    for harmo = 1:4 
        noise_average(:,roi,harmo) = [squeeze(mean(mean(mean(orep_n49_odd6mo(newelecs_LMR(roi,:),noisebins(harmo,:),:,:),2),3),1));...
                squeeze(mean(mean(mean(orep_n49_odd9mo(newelecs_LMR(roi,:),noisebins(harmo,:),:,:),2),3),1))];
    end
end
noise_average1 = sum(noise_average,3);

%noise_average turns into subj x roi x harmonic 
%noise_average1 then sums the harmonics together

SignalvNoise = [signal_average noise_average1];
%The output of this is signal_L, signal_M, signal_R, noise_L, noise_M, noise_R


%% Plotting Settings 
set(0, 'DefaultLineLineWidth', 2.5);
set(0, 'DefaultLineMarkerSize', 15);
set(0, 'DefaultAxesFontSize', 17);
set(0, 'defaultfigurecolor',[1 1 1])
set(0, 'DefaultAxesLinewidth', 3);
set(0, 'DefaultAxesBox','off');
set(0, 'DefaultFigureColormap',turbo);

%% combining data across ages 
combinedage_base = cat(4, orep_n49_driv6mo, orep_n49_driv9mo); 
combinedage_oddball = cat(4, orep_n49_odd6mo, orep_n49_odd9mo);
size(combinedage_base)
size(combinedage_oddball)

%% 6 Hz Frequency Spectra by Age 
%Figure 3 in final manuscript 
gm_6mo_6hz = mean(orep_n49_driv6mo,4);
gm_9mo_6hz = mean(orep_n49_driv9mo,4); 
gm_6mo_6hz_mid = squeeze(mean(gm_6mo_6hz([66 67 73],:,:),1));
gm_9mo_6hz_mid = squeeze(mean(gm_9mo_6hz([66 67 73],:,:),1));

figure(1)

    subplot(1,2,1)
    plot(faxis6(1:27), gm_6mo_6hz_mid(1:27,:))
    box off 
    xticks(6:6:36)
    xlabel('frequency (Hz)')
    ylabel('amplitude (µV)')
    title('6-Month Mid-Occipital 6Hz')
    legend({'Familiar', 'Unfamiliar'}, 'box', 'off')

    subplot(1,2,2)
    plot(faxis6(1:27), gm_9mo_6hz_mid(1:27,:))
    box off 
    xticks(6:6:36)
    ylim([0 1.4])
    yticks(0:0.2:1.4)
    xlabel('frequency (Hz)')
    ylabel('amplitude (µV)')
    title('9-Month Mid-Occipital 6Hz')
    legend({'Familiar', 'Unfamiliar'}, 'box', 'off')

%% ROI freq spectra (combined age and familiarity condition) 
%Figure 5a in final manuscript
%make combined age oddball 
combinedage_oddball = cat(4, orep_n49_odd6mo, orep_n49_odd9mo); 
size(combinedage_oddball)
%average across participants 
gm_both_1_2hz = mean(combinedage_oddball, 4); 
%combine across condition 
gm_both_1_2hz_bothcondition = mean(gm_both_1_2hz, 3); 
size(gm_both_1_2hz_bothcondition)
%get only the 3 ROI 
gm_both_1_2hz_bothcondition_left = squeeze(mean(gm_both_1_2hz_bothcondition([62 59 58],:),1)); 
gm_both_1_2hz_bothcondition_mid = squeeze(mean(gm_both_1_2hz_bothcondition([66 67 73],:),1)); 
gm_both_1_2hz_bothcondition_right = squeeze(mean(gm_both_1_2hz_bothcondition([79 80 84],:),1)); 
gm_bothconditionage_byROI = cat(1, gm_both_1_2hz_bothcondition_left, gm_both_1_2hz_bothcondition_mid, gm_both_1_2hz_bothcondition_right);
size(gm_bothconditionage_byROI)

%newelecs_LMR = [62 59 58; 66 67 73; 79 80 84];

figure(2)
plot(faxis1_2(1:35), gm_bothconditionage_byROI(:, 1:35))
box off 
xticks(1.2:1.2:7.2)
xlabel('frequency (Hz')
ylabel('amplitude (µV)')
title('ROI (combined age and condition')
legend({'left', 'medial', 'right'}, 'box', 'off')
%% Headplots for each harmonic for each age group (Fig3A)
%6-month-olds
mo6_base_fam = gm_6mo_6hz(:,:,1,:);
mo6_base_unfam = gm_6mo_6hz(:,:,2,:);
size(mo6_base_fam)

figure(3)
    subplot(3,2,1)
        headplot(mo6_base_fam(:,9), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc 
    subplot(3,2,2)
        headplot(mo6_base_unfam(:,9), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,3)
        headplot(mo6_base_fam(:,17), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,4)
        headplot(mo6_base_unfam(:,17), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc 
    subplot(3,2,5)
        headplot(mo6_base_fam(:,25), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,6)
        headplot(mo6_base_unfam(:,25), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc

%9-month-olds
mo9_base_fam = gm_9mo_6hz(:,:,1,:);
mo9_base_unfam = gm_9mo_6hz(:,:,2,:);
size(mo9_base_fam)

figure(4)
    subplot(3,2,1)
        headplot(mo9_base_fam(:,9), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc 
    subplot(3,2,2)
        headplot(mo9_base_unfam(:,9), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,3)
        headplot(mo9_base_fam(:,17), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,4)
        headplot(mo9_base_unfam(:,17), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc 
    subplot(3,2,5)
        headplot(mo9_base_fam(:,25), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc
    subplot(3,2,6)
        headplot(mo9_base_unfam(:,25), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 1.25], 'view', 'b'); clc

%% Headplots of summed 6 Hz + harmonics by age (Fig3b) 
%6-month-olds
mo6_6hz_fam_sum = sum(mo6_base_fam(:,[9 17 25],:,:),2);
size(mo6_6hz_fam_sum)
mo6_6hz_unfam_sum = sum(mo6_base_unfam(:,[9 17 25],:,:),2);
size(mo6_6hz_unfam_sum)

figure(5)
    subplot(1,2,1) %summed familiar headplot
        headplot(mo6_6hz_fam_sum(:,1),'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc 
    subplot(1,2,2)
        headplot(mo6_6hz_unfam_sum(:,1),'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc 

%9-month-olds
mo9_6hz_fam_sum = sum(mo9_base_fam(:,[9 17 25],:,:),2);
size(mo9_6hz_fam_sum)
mo9_6hz_unfam_sum = sum(mo9_base_unfam(:,[9 17 25],:,:),2);
size(mo9_6hz_unfam_sum)

figure(6)
    subplot(1,2,1) %summed familiar headplot
        headplot(mo9_6hz_fam_sum(:,1),'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc 
    subplot(1,2,2)
        headplot(mo9_6hz_unfam_sum(:,1),'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc
%% ROI Combined Condition Headplot (by age) summed 4 harmos (Fig 4b)
mo6_ROI_harmosum = sum(mean(mean(orep_n49_odd6mo(:,[9 17 25 33],:,:),4),3),2); 
size(mo6_ROI_harmosum)
mo9_ROI_harmosum = sum(mean(mean(orep_n49_odd9mo(:,[9 17 25 33],:,:),4),3),2); 
size(mo9_ROI_harmosum)

figure(7)
    subplot(1,2,1)
        headplot(mo6_ROI_harmosum(:,:), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 4], 'view', 'b'); clc
    subplot(1,2,2)
        headplot(mo9_ROI_harmosum(:,:), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 4], 'view', 'b'); clc
%% Headplots for each ROI based harmonic (Fig 5a)
gm_combinedage_oddball = mean(combinedage_oddball,4);
gm_combinedage_combinedcondition_oddball = mean(gm_combinedage_oddball,3);
size(gm_combinedage_combinedcondition_oddball)
gm_combinedage_combinedcondition_oddball_left = mean(gm_combinedage_combinedcondition_oddball([53 58 59],:),1);
gm_combinedage_combinedcondition_oddball_medial = mean(gm_combinedage_combinedcondition_oddball([66 67 73],:),1);
gm_combinedage_combinedcondition_oddball_right = mean(gm_combinedage_combinedcondition_oddball([80 84 85],:),1);
size(gm_combinedage_combinedcondition_oddball_right)

figure(8)
    subplot(1,4,1)
headplot(gm_combinedage_combinedcondition_oddball(:,9), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc
    subplot(1,4,2)
headplot(gm_combinedage_combinedcondition_oddball(:,17), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc
    subplot(1,4,3)
headplot(gm_combinedage_combinedcondition_oddball(:,25), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc
    subplot(1,4,4)
headplot(gm_combinedage_combinedcondition_oddball(:,33), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 2], 'view', 'b'); clc 
%% Summed harmonics ROI (combined age and condition) grandest mean 
%Figure 5b
ROI_harmosum = sum(gm_combinedage_combinedcondition_oddball(:,[9 17 25 33],:,:),2);
size(ROI_harmosum)

figure(9)
headplot(ROI_harmosum(:,:), 'EGI_109.spl', 'electrodes', 'off', 'maplimits', [0 4], 'view', 'b'); clc