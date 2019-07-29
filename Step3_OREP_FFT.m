clear
clc
filematALL = dir('OREP_POST_53_*_CLEAN.set'); % This loads a struct of files of a specific condition e.g. (Pre)    
filemat = {filematALL.name}'; % This takes the just the names from that struct and transposes the list so its in the correct format
pathToFiles='/Users/BCDLAB1600/Desktop/SSVEP files/SSVEP processing_OREP/Split_Condition/CLEAN CHAN/'


for j = 1:size(filemat,1)
    %get filename
    subject_string = deblank(filemat(j,:));
    %turn filename into a character string
    Csubject = char(subject_string);
    %split the filename by .
    C = strsplit(Csubject,'.');
    %Get the filename without the extension
    Csubject = char(C(1,1))
    filename = strcat(pathToFiles,Csubject, '.set');  
    %load file into EEGlab
    EEG = pop_loadset('filename', filename);
    EEG = eeg_checkset( EEG );
    %save EEG data as a variable
    inmat3d = EEG.data;  
    %average over trial
    mat2d = nanmean(inmat3d, 3);


%This removes the 100ms baseline and first second of data so that the
%trials are 5000 ms (exactly 30 6Hz cycles and 25 5Hz cycles)
     [pow, phase, freqs] = FFT_spectrum(mat2d(:, 51:end), 500); 
     MYpath = '/Users/BCDLAB1600/Desktop/SSVEP files/SSVEP processing_OREP/AVGthenFFT/'
     save(strcat(MYpath,Csubject,'.mat'),'pow');
end