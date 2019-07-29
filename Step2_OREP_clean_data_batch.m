%format: (filemat, path, Remove outer band?, Baby?)
%enter 0 for N or 1 for Y for outerband
%enter 1 for baby and 0 for adult
function [outmat3d] = Step2_OREP_clean_data_batch(filemat, MYpath,outerband, Baby)
     % check for the CLEAN CHAN folder and create it if it doesn't
    % exist
    if ~exist(strcat(MYpath, 'CLEAN CHAN/'),'dir')
        mkdir(strcat(MYpath, 'CLEAN CHAN/'))
    end
    
    if Baby==1;
        if outerband==1;
            for j = 1:size(filemat,1)
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(MYpath,Csubject);
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
                    EEG = pop_saveset( EEG, 'filename',strcat(file,'_CLEAN.set'),'filepath',strcat(MYpath,'CLEAN CHAN/'));

                    EEG = eeg_checkset( EEG );
            %         pop_eegplot( EEG, 1, 1, 1);
                    save(strcat('interpvec_', file,'.mat'),'interpsensvec');

            end


        elseif outerband==0
            for j = 1:size(filemat,1)
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(MYpath,Csubject);
                EEG = pop_loadset('filename',filename);
                EEG = eeg_checkset( EEG );

                % loads the EEG data into a 3D matrix channels x time x trial
                inmat3d = EEG.data; 
                % deletes eye channels
                inmat3d(125:129,:) = 0; 
                % Load sensor locations for 129 channel net
                load locsEEGLAB129HCL.mat 
                % Create an empty matrix to hold interpolated channels
                interpsensvec = zeros(4,30); 
                % Creates an empty matrix the same size as the input matrix
                outmat3d = zeros(size(inmat3d)); 
                % Creates an empty variable for cartisian coordinates & corresponding data
                cartesianmat129 = zeros(129,3); 

                % find X, Y, Z for each sensor
                for elec = 1:129
                   cartesianmat129(elec,1) =  locsEEGLAB129HCL((elec)).X;
                   cartesianmat129(elec,2) =  locsEEGLAB129HCL((elec)).Y;
                   cartesianmat129(elec,3) =  locsEEGLAB129HCL((elec)).Z;
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
                    interpvec1 =  find(qualindex > median(qualindex(1,(1:124))) + 2.5.* std(qualindex(1,(1:124))));
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
                    interpvec2 = find(qualindex2 > median(qualindex2(1,(1:124))) + 3.5.* std(qualindex2(1,(1:124))));

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
                        for elec2 = 1:129
                            distvec(elec2) = sqrt((cartesianmat129(elec2,1)-cartesianmat129(interpvec(badsensor),1)).^2 + (cartesianmat129(elec2,2)-cartesianmat129(interpvec(badsensor),2)).^2 + (cartesianmat129(elec2,3)-cartesianmat129(interpvec(badsensor),3)).^2);
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
                    outmat3d = avg_ref3d_baby129(outmat3d);

                    %put back into EEGlab format so we can plot it
                    EEG.data = single(outmat3d);
                    EEG = pop_saveset( EEG, 'filename',strcat(file,'_CLEAN.set'),'filepath',strcat(MYpath,'CLEAN CHAN/'));

                    EEG = eeg_checkset( EEG );
            %         pop_eegplot( EEG, 1, 1, 1);
                    save(strcat('interpvec_', file,'.mat'),'interpsensvec');

            end
        end
    elseif Baby==0
        if outerband ==1
            disp('ERROR! You do not want to remove the outerband for adults')
            return
        elseif outerband ==0
            for j = 1:size(filemat,1)
                subject_string = deblank(filemat(j,:));
                Csubject = char(subject_string);
                C = strsplit(Csubject,'.');
                file = char(C(1,1));
                filename = strcat(MYpath,Csubject);
                EEG = pop_loadset('filename',filename);
                EEG = eeg_checkset( EEG );

                % loads the EEG data into a 3D matrix channels x time x trial
                inmat3d = EEG.data; 

                % Load sensor locations for 129 channel net
                load locsEEGLAB129HCL.mat 
                % Create an empty matrix to hold interpolated channels
                interpsensvec = zeros(4,30); 
                % Creates an empty matrix the same size as the input matrix
                outmat3d = zeros(size(inmat3d)); 
                % Creates an empty variable for cartisian coordinates & corresponding data
                cartesianmat129 = zeros(129,3); 

                % find X, Y, Z for each sensor
                for elec = 1:129
                   cartesianmat129(elec,1) =  locsEEGLAB129HCL((elec)).X;
                   cartesianmat129(elec,2) =  locsEEGLAB129HCL((elec)).Y;
                   cartesianmat129(elec,3) =  locsEEGLAB129HCL((elec)).Z;
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
                        for elec2 = 1:129
                            distvec(elec2) = sqrt((cartesianmat129(elec2,1)-cartesianmat129(interpvec(badsensor),1)).^2 + (cartesianmat129(elec2,2)-cartesianmat129(interpvec(badsensor),2)).^2 + (cartesianmat129(elec2,3)-cartesianmat129(interpvec(badsensor),3)).^2);
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
                    outmat3d = avg_ref3d(outmat3d);

                    %put back into EEGlab format so we can plot it
                    EEG.data = single(outmat3d);
                    EEG = pop_saveset( EEG, 'filename',strcat(file,'_CLEAN.set'),'filepath',strcat(MYpath,'CLEAN CHAN/'));

                    EEG = eeg_checkset( EEG );
            %         pop_eegplot( EEG, 1, 1, 1);
                    save(strcat('interpvec_', file,'.mat'),'interpsensvec');

            end
        end
    end
end





