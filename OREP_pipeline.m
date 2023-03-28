s%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%OREP Preprocessing%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Step 1: Get .mff files, downsample to 500Hz, save as .set files (run as a
%batch)

%Step 2: Filter data, create event list, assign bins (run individually)

%Step 3: Remove bad sensors and re-reference

%Step 4: Artifact detection

%Step 5: Artifact Rejection based on step 4 and on runsheet

%Step 6: Convert .set files (eeglab) to mat files to use FreqTag TOOLBOX

%Step 7: Run slidind window (run this step twice: one for 1.2Hz and one for 6Hz)

%Step 8: Run FFT (run this step twice: one for 1.2Hz and one for 6Hz)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 1   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%Assign the folder containing the raw .mff files
%i. Enter the directory to the folder containing your raw .set files

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_RawMFF'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_RawMFF'))
end

Mypathrawmff = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_RawMFF/';
cd(Mypathrawmff)

%ii. Enter the pattern you want to use to find files
filematALL = dir('OREP*.mff'); % This loads a struct of files fitting that pattern   
filemat = {filematALL.name}'; % This takes just the names from that struct and transposes the list so its in the correct format

%iii. Create a directory for the raw .set files

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_1_RawSET'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_1_RawSET'))
end
    
Mypathrawset = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_1_RawSET/';

%iv. Get the raw mff files, downsample and save as .set files

for j = 1:size(filemat,1)
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(Mypathrawmff,Csubject);

EEG = pop_mffimport({filename},{'code'}); %import data
EEG = eeg_checkset( EEG );
EEG = pop_resample( EEG, 500); %resample to 500Hz
EEG = pop_editset(EEG, 'setname', strcat(file,'_downsampled'));
EEG = pop_saveset( EEG, 'filename',strcat(Mypathrawset, Csubject,'.set')); %save as .set file

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 2   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%i. Go to the folder containing the raw .set files
% 
% Mypathrawset = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_1_RawSET/';
% cd(Mypathrawset)
% 
% %ii. Assign the folder containing the .txt for each condition
% Mypathtxt = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_txtcondition/';
% 
% %iii. Create a directory for the new files 
% 
% if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_2_SplitbyCond_NEW'),'dir')
%         mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_2_SplitbyCond_NEW'))
% end
% Mypathcondition ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_2_SplitbyCond_NEW/';

% Important information: 
    %Each participant has to be run 8 times (for each condition and for each time point: PRE and POST) 
    %Epoch lengh: -100.0  20000.0
    
    
 %function [] = OREP_dataprocessing_Conditions()

    % Prompt information
    prompt = {'subject','BookNum','Race'};
    defaults = {'1','1','C'};
    answer = inputdlg(prompt,'subject',1,defaults);

    [subject, BookNum, Race] = deal(answer{:});
    
    % PRE or POST?
    timeArray = {'Pre', 'Post'};
    [selectionIndex3, leftBlank] = listdlg('PromptString', 'Select a time point:', 'SelectionMode', 'single', 'ListString', timeArray);
    timepoint= timeArray{selectionIndex3};
    
    % Get the age of the participant
    ageArray = {'6', '9', '12', 'Adult'};
    [selectionIndex, leftBlank] = listdlg('PromptString', 'Select an age:', 'SelectionMode', 'single', 'ListString', ageArray);
    age = ageArray{selectionIndex};
    
    % Select the Condition you want to Run
    conditionArray = {'Familiar', 'Category', 'Individual', 'Untrained'};
    [selectionIndex2, leftBlank] = listdlg('PromptString', 'Select a Condition to Run:', 'SelectionMode', 'single', 'ListString', conditionArray);
    Condition = conditionArray{selectionIndex2};
    
    %Creating filenames based on PRE and POST 
    
    if strcmp(timepoint,'Pre') == 1
        filename = strcat(Mypathrawset, '/OREP_',char(subject), '_', char(Race), '_', age, '.set');
    elseif strcmp(timepoint,'Post') == 1
        filename = strcat(Mypathrawset, '/OREP_POST_',char(subject), '_', char(Race), '_', age, '.set');
    end

    %Initial processing steps
  
        %Load data
        EEG = pop_loadset('filename', filename);

        % Create Event List
        EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
    
        % Bandpass filter from 0.5-30 Hz
        dataAK=double(EEG.data); 
        [alow, blow] = butter(6, 0.12); 
        [ahigh, bhigh] = butter(3,0.002, 'high'); 

        dataAKafterlow = filtfilt(alow, blow, dataAK'); 
        dataAKafterhigh = filtfilt(ahigh, bhigh, dataAKafterlow)'; 

        EEG.data = single(dataAKafterhigh); 
     
    %Assign bins via BINLISTER
 
    if strcmp(Condition,'Familiar') == 1
            if Race == 'A'
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt,'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif Race == 'C'
                EEG  = pop_binlister( EEG , 'BDF', '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_txtcondition/Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' );
            elseif Race == 'B'
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif Race == 'H'
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            end
            
        elseif strcmp(Condition,'Category') == 1
            if Race == 'A' 
                if strcmp(BookNum, '1') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            end
                
        elseif Race == 'C' 
            if strcmp(BookNum, '2A') || strcmp(BookNum, '2D') || strcmp(BookNum, '6A') || strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3D') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            end
                
        elseif Race == 'B' 
            if strcmp(BookNum, '4') || strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif  strcmp(BookNum, '6A') || strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '6B') || strcmp(BookNum, '6C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            end
                
        elseif Race =='H' 
            if strcmp(BookNum, '1') || strcmp(BookNum, '2B') || strcmp(BookNum, '2C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            elseif strcmp(BookNum, '4')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
            end
            end %Condition Category
            
  
        elseif strcmp(Condition,'Individual') == 1
            if Race == 'A' 
               if strcmp(BookNum,'3A') ||  strcmp(BookNum,'3D')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '5') 
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '1')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               end
                    
            elseif Race == 'C' 
               if strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C') 
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2D') || strcmp(BookNum, '3A') || strcmp(BookNum, '3D') 
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                 'EEG', 'Voutput', 'EEG' ));
               elseif strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '6A') || strcmp(BookNum, '6D') 
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               end
                    
            elseif Race =='B' 
               if strcmp(BookNum, '6B') || strcmp(BookNum, '6C') || strcmp(BookNum, '4')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6D') || strcmp(BookNum, '5')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
               end
                    
            elseif Race =='H' 
               if strcmp(BookNum, '2A') || strcmp(BookNum, '2D')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               elseif strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '4')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               elseif strcmp(BookNum, '1')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
               end
        
         end %Condition Individual        
            
        elseif strcmp(Condition,'Untrained') == 1
            if Race == 'A' 
               if strcmp(BookNum, '1')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '5')
                  EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                  'EEG', 'Voutput', 'EEG' ));            
                elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '3D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                'EEG', 'Voutput', 'EEG' ));
             end
               
            elseif Race == 'C' 
                if strcmp(BookNum, '3A') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '3D')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum,'2A') || strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '2D')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C') || strcmp(BookNum, '6D')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
            end
                
            elseif Race == 'B' 
                if strcmp(BookNum, '4')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '5')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6B')|| strcmp(BookNum, '6C')|| strcmp(BookNum, '6D')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
            end
                
            elseif Race == 'H' 
                if strcmp(BookNum, '4')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '1') 
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2B')|| strcmp(BookNum, '2C')|| strcmp(BookNum, '2D')
                   EEG  = pop_binlister( EEG , 'BDF', strcat(Mypathtxt, 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                   'EEG', 'Voutput', 'EEG' ));
                end
            end %condition Untrained
    end %Final loop
        
    % Create bin-based epochs
    EEG = pop_epochbin( EEG , [-100.0  20000.0],  'pre'); 

    % Save new file 
    if strcmp(timepoint,'Pre') == 1
    EEG = pop_saveset( EEG, 'filename',strcat(Mypathcondition, 'OREP_',num2str(subject),'_',char(Race),'_',num2str(age),'_',Condition,'.set'));
    elseif strcmp(timepoint,'Post') == 1
    EEG = pop_saveset( EEG, 'filename',strcat(Mypathcondition, 'OREP_POST_',num2str(subject),'_',char(Race),'_',num2str(age),'_',Condition,'.set'));
    end

%end

%Do it again for the next condition

%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 3   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%i. Go to the folder containing the files split by condtions 
Mypathcondition = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_2_SplitbyCond_NEW/';
cd(Mypathcondition); 

%ii. Find the files 
filematALL = dir('OREP*.set'); % This loads a struct of files fitting that pattern   
filemat = {filematALL.name}'; % This takes just the names from that struct and transposes the list so its in the correct format

%iii. Create a directory for the new files 

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_3_SplitbyCond_CleanChan'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_3_SplitbyCond_CleanChan'))
end
Mypathcleanchan ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_3_SplitbyCond_CleanChan_NEW';


%iv. Remove outer band of electrodes, identify and replace bad electrodes, apply average reference.



for j = 1:size(filemat,1)
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(Mypathcondition,Csubject);
                EEG = pop_loadset('filename',filename);
                EEG = eeg_checkset( EEG );
                % remove outer band of electrodes
                EEG = pop_select( EEG,'nochannel',{'E17' 'E43' 'E48' 'E49' 'E56' 'E63'... 
                    'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107' 'E113' 'E119' 'E120' ...
                    'E125' 'E126' 'E127' 'E128'});
                EEG = eeg_checkset( EEG );
                % loads the EEG data into a 3D matrix channels x time x trial
                inmat3d = EEG.data; 

                % Load sensor locations for 109 channel net
                load locsEEGLAB109HCL.mat 
                % Create an empty matrix to hold interpolated channels
                interpsensvec = zeros(4,30); 
                % Creates an empty matrix the same size as the input matrix
                outmat3d = zeros(size(inmat3d)); 
                % Creates an empty variable for cartisian coordinates & corresponding data
                cartesianmat109 = zeros(109,3); 

                % find X, Y, Z for each sensor
                for elec = 1:109
                   cartesianmat109(elec,1) =  locsEEGLAB109HCL((elec)).X;
                   cartesianmat109(elec,2) =  locsEEGLAB109HCL((elec)).Y;
                   cartesianmat109(elec,3) =  locsEEGLAB109HCL((elec)).Z;
                end

                % Go through data matrix trial by trial and identify noisy channels,
                % replace those electrodes with the average of the closest 6, and 
                % apply the average reference
                for trial = 1:size(inmat3d,3)

                    %Get the data for one trial
                    trialdata2d = inmat3d(:, :, trial); 

                    % caluclate three metrics of data quality at the channel level
                    absvalvec = median(abs(trialdata2d)'); % Median absolute voltage value for each channel
                    stdvalvec = std(trialdata2d'); % SD of voltage values
                    maxtransvalvec = max(diff(trialdata2d')); % Max diff of voltage values

                    % calculate compound quality index
                    qualindex = absvalvec+ stdvalvec+ maxtransvalvec; 

                    % detect indices of bad channels; currently anything farther than 2.5 SD
                    % from the median quality index value %% 
                    interpvec1 =  find(qualindex > median(qualindex) + 2.5.* std(qualindex))

                    % Second run through of bad channel detection, after removing extremely bad channels from first run  
                    qualindex2 = qualindex;

                    % if the channels has already been detected as bad, assign the median 
                    % quality index value
                    for a = 1:length(qualindex)
                        extremechan = ismember(a,interpvec1);
                        if extremechan == 1
                            qualindex2(:,a) = median(qualindex);
                        end
                    end

                    % detect indices of bad channels; currently anything farther than 3.5 SD
                    % from the median quality index value %% 
                    interpvec2 = find(qualindex2 > median(qualindex2) + 3.5.* std(qualindex2));

                    % append channels from second run through for a complete list
                    interpvec = [interpvec1,interpvec2]; 

                    % append channels that are bad so that we have them after going through
                    % the trials

                    interpsensvec(trial,1:size(interpvec,2))=interpvec;

                    % copy the trialdata to a new matrix for cleaning
                    cleandata = trialdata2d; 

                    % set bad data channels nan, so that they are not used for inerpolating each other  
                    cleandata(interpvec,:) = nan; 

                    % If there are no bad channels, skip the cleaning
                    if length(interpvec)==0
                        outmat3d(:, :, trial) = cleandata;
                    end

                    % interpolate bad channels from 6 nearest neighbors in the cleandata

                    for badsensor = 1:length(interpvec)
                        % find nearest neighbors
                        for elec2 = 1:109
                            distvec(elec2) = sqrt((cartesianmat109(elec2,1)-cartesianmat109(interpvec(badsensor),1)).^2 + (cartesianmat109(elec2,2)-cartesianmat109(interpvec(badsensor),2)).^2 + (cartesianmat109(elec2,3)-cartesianmat109(interpvec(badsensor),3)).^2);
                        end

                       [dist, index]= sort(distvec); 

                       size( trialdata2d(interpvec(badsensor),:)), size(mean(trialdata2d(index(2:7), :),1))

                       trialdata2d(interpvec(badsensor),:) = nanmean(cleandata(index(2:7), :),1); 

                       outmat3d(:, :, trial) = trialdata2d; % Creates output file where bad channels have been replaced with interpolated data

                    end
                end

                    %create a list of all of the interpolated channels
                    interpsensvec_unique = unique(interpsensvec); 

                    %re-reference to the average
                    outmat3d = avg_ref3d_baby109_noOuter(outmat3d);

                    %put back into EEGlab format so we can plot it
                    EEG.data = single(outmat3d);
                    EEG = pop_saveset( EEG, 'filename',strcat(file,'_CLEAN.set'),'filepath',Mypathcleanchan);

                    EEG = eeg_checkset( EEG );
            %         pop_eegplot( EEG, 1, 1, 1);
                    save(strcat('interpvec_', file,'.mat'),'interpsensvec');

            end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 4   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%i. Go to the folder containing the files that have been filtered, split by conditions and interpolated 
Mypathcleanchan ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_3_SplitbyCond_CleanChan_NEW/';
cd(Mypathcleanchan)

%ii. Find the files 
filematALL = dir('OREP*.set'); % This loads a struct of files fitting that pattern   
filemat1 = {filematALL.name}'; % This takes just the names from that struct and transposes the list so its in the correct format

%iii. Create a directory for the new files 

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_4_SplitbyCond_CleanChan_AD_NEW/'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_4_SplitbyCond_CleanChan_AD_NEW/'))
end
MypathAD ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_4_SplitbyCond_CleanChan_AD_NEW/';

 for j = 1:size(filemat1,1)
    %extract filename
    subject_string = deblank(filemat1(j,:));
    Csubject = char(subject_string);
    C = strsplit(Csubject,'.');
    file = char(C(1,1));
    filename = strcat(Mypathcleanchan,Csubject);
    
    %load file
    EEG = pop_loadset('filename',filename);
    
    % Check for artifacts. Here, I'm using a simple voltage threshold- you can find other
    % methods in ERPlab
    EEG  = pop_artextval( EEG , 'Channel',  1:109, 'Flag',  1, 'Threshold', [ -300 300], 'Twindow', [ -100 20000] ); 
    EEG = eeg_checkset( EEG );
    
    % this saves a copy of the file were the bad trials are marked but
    % still included in the file
    EEG = pop_saveset( EEG, 'filename',strcat(file, '_AD.set'), 'filepath', MypathAD);
    
 end
 
 %% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 5   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%i. Go to the folder containing the files that have been filtered, split by conditions, interpolated and marked   
MypathAD ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_4_SplitbyCond_CleanChan_AD_NEW/';
cd(MypathAD)

%ii. Create a directory for the new files 

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_5_SplitbyCond_CleanChan_AD_preprodone/'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_5_SplitbyCond_CleanChan_preprodone/'))
end
Mypathbadrmv ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_5_SplitbyCond_CleanChan_preprodone_NEW/';


%iii. Get the dataset to remove trials from
filename = 'OREP_85_C_9_Untrained_CLEAN_AD.set';

%this extracts filename without extension
C = strsplit(filename,'.');
file = char(C(1,1));

%load the file
EEG = pop_loadset('filename',filename);

%plot the data 
pop_eegplot(EEG, 1,1,1)

% in brackets, list the trials you want to remove (no comma needed)
EEG = pop_select( EEG,'notrial',[1 4]);

%save file after trial rejection
EEG = pop_saveset( EEG, 'filename',strcat(file, '_BadRemoved.set'), 'filepath', Mypathbadrmv);

%%Preprocessing done! 
   
%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 6   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%Prepare files to run slidewin: convert set to mat files
clear all

%i. Create folder to host the mat files

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_7_preprodone_mat_NEW files/'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_7_preprodone_mat_NEW files/'))
end
Mypathmat = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_7_preprodone_mat_NEW files/';

%ii. Go to the folder containing the files after the prepocessing
Mypathbadrmv ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_6_SplitbyCond_CleanChan_preprodone_onlyOKAYbabies_NEW/';
cd(Mypathbadrmv)

%iii. Find the files and create a list with all set files to be convertedt
%to mat files 

filematALL = dir('OREP*.set'); % This loads a struct of files fitting that pattern   
filemat = {filematALL.name}'; % This takes just the names from that struct and transposes the list so its in the correct format

%iv. Convert set to 3-d mat files (20s long = 10000sample pts, if SR=500mHz)

for j = 1:size(filemat, 1)
                
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(Mypathbadrmv,Csubject);
                EEG = pop_loadset('filename',filename);
                EEG = eeg_checkset( EEG );
                
                inmat3d = EEG.data(:,51:end,:); %remove 100ms of baseline
                data3d = double(inmat3d); 
                %cd(Mypathmat)
                
                save(strcat(Mypathmat, file,'.mat'),'data3d');
                %eval(['save ' Csubject(1:19) '.mat inmat3ddouble -mat'])
                
end 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 7   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%Run SlideWin 

clear all

%i. Create folder to host the mat files

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_8_preprodone_mat_slidewin_NEW/'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_8_preprodone_mat_slidewin_NEW/'))
end
Mypathslidewin = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_8_preprodone_mat_slidewin_NEW/';

%ii. Go to the folder containing the files after the prepocessing
Mypathmat ='/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_7_preprodone_mat_NEW files/';
cd(Mypathmat)

%iii. Find the files and create a list with all set files to be convertedt
%to mat files 

filematALL = dir('OREP*.mat'); % This loads a struct of files fitting that pattern   
filemat = {filematALL.name}'; % This takes just the names from that struct and transposes the list so its in the correct format



[trialamp,winmat3d,phasestabmat,trialSNR] = OREP_flex_slidewin(filemat, 0, 1:100, 1:10000, 1.2, 600, 500, '1.2Hz');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%    STEP 8   %%%%%%%%%%%%%%%%%%%%%%%%%%%% %%

%Run fft after slidewin

clear all

%i. Create folder to host the fft files

if ~exist(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_8_slidewin_fft/'),'dir')
        mkdir(strcat('/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/', 'OREP_8_slidewin_fft/'))
end
Mypathfft = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_8_slidewin_fft';

%ii. Go to the folder containing the win mat files

Mypathslidewin = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_7_preprodone_mat_slidewin_6hz';
cd(Mypathslidewin)

Mypathslidewin = '/Users/jessica.sanchesb/Dropbox (UFL)/OREP_jessica/OREP_7_preprodone_mat_slidewin/OREP_7_preprodone_mat_slidewin_1.2Hz';
cd(Mypathslidewin)

%iii. Get the files

filemat = getfilesindir(pwd, 'O*6Hz.winmat*.mat')

%iv. Run fft

for fileindex = 1:size(filemat,1)
     amp = [];
     freqs = [];
     phase = [];
     data2d = [];
     
    outname  = deblank(filemat(fileindex,:)); %create a variable to hold the name

    a = load(deblank(filemat(fileindex,:)));
    
    data = eval(['a.' char(fieldnames(a))]);
    
    data2d = mean(data,3);
    
    [amp, phase, freqs, fftcomp] = freqtag_FFT(data2d, 600);
    
    eval(['save ' outname(1:end-24) '.fft_6.mat amp -mat']);
    
end

% Repeat the process for the 1.2Hz files

