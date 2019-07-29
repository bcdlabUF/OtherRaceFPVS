function [] = OREP_dataprocessing_Conditions()
    %% OREP ssvep data processing
    % Read in set file & process data so it's ready to be cleaned
    %
    % Raw data and Event Info must have already been imported, and the file
    % must be saved as a .set file: OREP_#_race_age (e.g., OREP_2_C_9)

    %% Prompt information
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
    
    %UPDATE NEXT LINE WITH YOUR CORRECT FILE PATH
    pathToFiles = ['/Users/BCDLAB1600/Desktop/SSVEP files/SSVEP processing_OREP/'];
    if strcmp(timepoint,'Pre') == 1
        filename = strcat(pathToFiles, 'DATA FILES/OREP_',char(subject), '_', char(Race), '_', age, '.set');
    elseif strcmp(timepoint,'Post') == 1
        filename = strcat(pathToFiles, 'DATA FILES/OREP_POST_',char(subject), '_', char(Race), '_', age, '.set');
    end

    %% Initial processing steps
    
    
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
     
    %% Assign bins via BINLISTER
 
        if strcmp(Condition,'Familiar') == 1
            if Race == 'A'
            EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
            elseif Race == 'C'
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles, 'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
            elseif Race == 'B'
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles, 'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
            elseif Race == 'H'
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles, 'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
            end
            
        elseif strcmp(Condition,'Category') == 1
            if Race == 'A' 
                if strcmp(BookNum, '1') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
                
            elseif Race == 'C' 
                if strcmp(BookNum, '2A') || strcmp(BookNum, '2D') || strcmp(BookNum, '6A') || strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3D') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
                
            elseif Race == 'B' 
                if strcmp(BookNum, '4') || strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif  strcmp(BookNum, '6A') || strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '6B') || strcmp(BookNum, '6C')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
                
             elseif Race =='H' 
                 if strcmp(BookNum, '1') || strcmp(BookNum, '2B') || strcmp(BookNum, '2C')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2D')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '4')
                 EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                 end
            end
            
  
        elseif strcmp(Condition,'Individual') == 1
            if Race == 'A' 
                    if strcmp(BookNum,'3A') ||  strcmp(BookNum,'3D')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '5') 
                         EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '1')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    end
                    
            elseif Race == 'C' 
                    if strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C') 
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2D') || strcmp(BookNum, '3A') || strcmp(BookNum, '3D') 
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '6A') || strcmp(BookNum, '6D') 
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    end
                    
            elseif Race =='B' 
                    if strcmp(BookNum, '6B') || strcmp(BookNum, '6C') || strcmp(BookNum, '4')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6D') || strcmp(BookNum, '5')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    end
                    
             elseif Race =='H' 
                    if strcmp(BookNum, '2A') || strcmp(BookNum, '2D')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '4')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    elseif strcmp(BookNum, '1')
                        EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                    end
        
            end         
            
        elseif strcmp(Condition,'Untrained') == 1
            if Race == 'A' 
                if strcmp(BookNum, '1')
                EEG  = pop_binlister( EEG , 'BDF',strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );            
                elseif strcmp(BookNum, '3A') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '3D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
               
            elseif Race == 'C' 
                if strcmp(BookNum, '3A') || strcmp(BookNum, '3B') || strcmp(BookNum, '3C') || strcmp(BookNum, '3D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum,'2A') || strcmp(BookNum, '2B') || strcmp(BookNum, '2C') || strcmp(BookNum, '2D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6B') || strcmp(BookNum, '6C') || strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
                
            elseif Race == 'B' 
                if strcmp(BookNum, '4')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Hispanic.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '5')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '6A') || strcmp(BookNum, '6B')|| strcmp(BookNum, '6C')|| strcmp(BookNum, '6D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
                
            elseif Race == 'H' 
                if strcmp(BookNum, '4')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'AfAmerican.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '1') 
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Asian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                elseif strcmp(BookNum, '2A') || strcmp(BookNum, '2B')|| strcmp(BookNum, '2C')|| strcmp(BookNum, '2D')
                EEG  = pop_binlister( EEG , 'BDF', strcat(pathToFiles,'Caucasian.txt'), 'IndexEL',  1, 'SendEL2',...
 'EEG', 'Voutput', 'EEG' );
                end
            end
        end
        

    % Create bin-based epochs
    EEG = pop_epochbin( EEG , [-100.0  20000.0],  'pre'); 
  
    NEWpath= strcat(pathToFiles, 'Split_Condition/');

    if strcmp(timepoint,'Pre') == 1
    EEG = pop_saveset( EEG, 'filename',strcat(NEWpath, 'OREP_',num2str(subject),'_',char(Race),'_',num2str(age),'_',Condition,'.set'));
    elseif strcmp(timepoint,'Post') == 1
    EEG = pop_saveset( EEG, 'filename',strcat(NEWpath, 'OREP_POST_',num2str(subject),'_',char(Race),'_',num2str(age),'_',Condition,'.set'));
    end

end

