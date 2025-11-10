% function [dataQCtable] = OREP_prepro_withBEES(mffDir,hpFilt,lpFilt,lpFiltOrder,...
%     downSampRate,rmOuterBand,maxElInterp,happeWav,epochWin,bslWin,segAmpThres,outname,saveSET)
% EEG preprocessing function: filtering, bad channel detection and interp, epoching, artifact rejection
% Coded by Javier Lopez-Calderon (Newencode Analytics; www.newencode.com) for L. Scott projects; 
% Modified for OREP tasks by Maeve R Boylan (mboylan@ufl.edu), Grace Wallsinger, Aug 2024
% =============================================================================
% Inputs:
    % mffDir: directory with mff files 
    % onsetTags: all of the condition labels that mark trial onsets
    % hpFilt: high-pass filter cutoff in Hz (e.g. 0.1)
    % lpFilt: low-pass filter cutoff in Hz (e.g. 30)
    % lpFiltOrder: filter order for lowpass, 2 just doesn't cut it, seems like 8th order is the sweet spot
    % downSampRate: downsampling rate in Hz
    % rmOuterBand: true if you want to removed outer band of elecs, false if not
    % maxElInterp: max # of bad channels allowed to be interpolated, e.g., 11 elecs
    % happeWav: if empty, skip happe wavelet in prepro
    % epochWin: time window to epoch in milliseconds
    % bslWin: time window for baseline correction
    % segAmpThres: amplitude threshold for segment/epoch/trial based rejection
    % outname: appended name for prepro .set file, dataQC outputs, and condition .mat files
    % saveSET: empty if you don't want to save intervening .set files
        % NOTE: currently this script ALWAYS saves epoched .mat file per subj
    % MAT FILE OUTPUT:
        % timeData = segmented time series data -500:20s
        % goodTri_byCond/badTri_byCond = good/bad trial count by condition
        % amp12/amp6 = freqtag amplitude for 1.2 and 6 Hz
        % faxis12/faxis6 = frequency axes for 1.2 and 6 Hz
        % winmat12/winmat6 = trial averaged time data, post- sliding window 

% ==> ex: OREP_prepro_withBEES(pwd,.05,50,8,500,false,16,0,[-500 20000],[-500 0],[-300 300],'testing123',1); 
% ============================================================================= MB, Aug 2023
% clear ; clc
close all
dt1 = datetime;
% IF TESTING FUNCTION, EXAMPLE INPUTS (OREP):
    mffDir = '/Users/gwallsinger/Desktop/OREP/39_Files';
    lpFilt = 30; hpFilt = .1; lpFiltOrder = 8;
    downSampRate = 500; rmOuterBand = true; maxElInterp = 16;
    epochWin = [-500 20000]; bslWin = [-500 0];
    outname2 = '';
    segAmpThres = [-300 300];
    happeWav = 1; saveSET = 1;
if hpFilt > 3, error('Ope! Looks like your highpass filter is pretty high. Make sure you didn''t swap your high- and lowpass filters.'), end
% #######################  PARAMETERS AND PATHS  #############################
% path stuff for mff files, chan locs
    chanlocfolder = '/Users/gwallsinger/Desktop/MATLAB Resources/';
    chanlocfile   = 'GSN-HydroCel-129.sfp'; % channel location file
% set the path to save the output files 
    path_matfiles = ['/Users/gwallsinger/Desktop/OREP/109_newPrePro'];
% filters, DINs, etc
    typeFields = {'code'};
    linefreq = 60;
    rawnchan        = 129; % number of channels of raw data
    workingchannels = 129; % correct number of (final) channels
    propbadch = (maxElInterp/workingchannels).*100; % percent of bad channels
    InterpolbadChans = true;
    eblnkchan = [8 9 14 21 22 25]; % eye movement channels
    chouterband ={ 'E17' 'E43' 'E48' 'E49' 'E56' 'E63' 'E68'...
        'E73' 'E81' 'E88' 'E94' 'E99' 'E107' 'E113'...
        'E119' 'E120' 'E125' 'E126'...
        'E127' 'E128' } ;
    params.lowDensity         = 0;
    params.paradigm.task      = 1;
    params.paradigm.ERP.on    = 0;
    params.QCfreqs            = [ 2:3:8 12 20 30 45 70];
    params.loadInfo.inputFormat   = 3 ;
    params.loadInfo.layout        = [ 2 128] ;
    params.loadInfo.correctEGI    = 1 ;
    params.loadInfo.chanlocs.inc  = 1;
    params.loadInfo.chanlocs.file = fullfile(chanlocfolder, chanlocfile);
    params.loadInfo.typeFields    = typeFields ;
    params.chans.subset        =  []  ;
    params.chans.IDs           = chouterband;
    params.lineNoise.freq      = linefreq ;
    params.lineNoise.neighbors = [] ;
    params.lineNoise.legacy    = 0 ;
    params.downsample          = downSampRate;
    params.filt.butter         = [] ;
    params.badChans.rej        = InterpolbadChans ;
    params.badChans.legacy     = [] ;
    params.wavelet.legacy      = [] ;
    params.segment.on          = [];
    params.segment.interp      = InterpolbadChans ;
    params.segRej.on           = [] ;
    params.reref.on            = 1 ;
    params.reref.chan          = 'Cz'  ;
    params.reref.average       = 1 ;
    params.reref.subset        = { 'Cz' } ;
    params.outputFormat        = [];
    params.vis.enabled         = 0 ;
    params.vis.min             = 0 ;
    params.vis.max             = 0 ;
    params.vis.toPlot          = [ ] ;
    params.HAPPEver            = '2_2_0' ;

%if earlier you set rmOuterBand = true 
%then it will adjust the number of working channels by subtracting the outer bands size
%it then calculates the % of bad channels 
if rmOuterBand, workingchannels = rawnchan - size(chouterband,2); else workingchannels = rawnchan; end

% creates an empty array - will be used to store wavelet means 
    wavMeans = [];
% load in Prepro Info Table
    load('OREPpreproInfo.mat')
 
% ==========================================================================
%                               DATA QC
% ==========================================================================
% initialize data quality variables for excel sheet output
    fprintf('Initializing report metrics...\n') ;
     dataQCnames = {'Number_User-Selected_Chans', ...   % 1
        'Good_Chans', ...                               % 2
        'Percent_Good_Chans', ...                       % 3
        'Bad_Chan_IDs', ...                             % 4
        'Chans_Interpolated', ...                       % 5
        'Percent_Var_Retained_Post-Wav', ...            % 6
        'Filename', ...                                 % 7
        'Age', ...                                      % 8
        'Overall_Good_Trial_Count', ...                 % 9
        'BadChan_Artifact_QC', ...                      % 10
        '%_Tri_Rej', ...                                % 11
        'fam', ...                                      % 12
        'unfam', ...                                    % 13
        'cat', ...                                      % 14
        'indiv', ...                                    % 15
        'Notes'};                                       % 16
    
% ==========================================================================
%                          FILE LOOP
% ==========================================================================
%% gets all of the files in the directory that match the task name pattern 
    filemat = getfilesindir(mffDir, 'OREP*.mff');
    dataQC = cell(size(filemat,1), length(dataQCnames));
    for fileNo = 1:size(filemat,1) % loop over each file in task file matrix
        fileName = deblank(filemat(fileNo,:)); % get current file name
        % if fileNo == 49 || fileNo == 69 % skip these files for now, weird
        %     dataQC{fileNo,7}  = fileName; % filename
        %     dataQC{fileNo,16} = [dataQC{fileNo,16}  ' weird triggers?!?!;'];
        %     continue
        % end
        uscrIndex = regexp(fileName,'\_'); % index of all underscores
        if length(uscrIndex) == 1
            subID = fileName(uscrIndex(1)+1:end-4);
        else
            subID = fileName(uscrIndex(1)+1:uscrIndex(2)-1); % subject number
        end
        subIdx = find(OREPpreproInfo.subNo == str2num(subID)); % which line is sub in preproInfo table
        if isempty(subIdx), dataQC{fileNo,7}  = fileName; dataQC{fileNo,16} = [dataQC{fileNo,16}  ' not in PrePro info table;']; continue, end
        subAge = num2str(OREPpreproInfo.Age(subIdx)); % subject age
    % if sub has name runs
        if contains(fileName,'run1')
            extraOutName = '_run1';
        elseif contains(fileName,'run2')
            extraOutName = '_run2';
        else
            extraOutName = '';
        end
    % set outname 
        if contains(fileName,'POST')
            outName = ['OREP_' subID '_POST_' subAge extraOutName outname2];
        else
            outName = ['OREP_' subID '_PRE_' subAge extraOutName outname2];
        end

    % set epoch/condition/counterbalance info
        BookNo = string(OREPpreproInfo.bookNo(subIdx));
        Race = string(OREPpreproInfo.Race(subIdx));
        
        fullFilePath = fullfile(mffDir,fileName);
        fprintf(['\n\n\n\nCurrent Participant: ' subID '\n\n\n\n']) % progress indicator
    % #############################################################
    %                       LOAD RAW DATA
    % #############################################################
        fprintf(['Loading ' fileName '... \n']) % progress indicator
        % load the EEG data from the file 
        EEG = pop_mffimport(fullFilePath,params.loadInfo.typeFields);
        
    % check channel number (CHCK 1), if not the correct chan number, note it, skip to next file
        if EEG.nbchan~=rawnchan
            dataQC{fileNo,16} = [dataQC{fileNo,16}  ' wrong chan number;']; 
            dataQC{fileNo,10} = 'FAILED - WRONG CHAN COUNT';
            dataQC{fileNo,7}  = fileName; % filename
            dataQC{fileNo,8}  = subAge; % visit
            continue
        end  %error('wrong channel number'), end
        scalpchan = find(~ismember(1:EEG.nbchan, eblnkchan)); % comented out so scalp channels isn't defined by 129 elec
    % load chan loc info
        EEG = pop_chanedit(EEG, 'load', {params.loadInfo.chanlocs.file ...
                'filetype' 'autodetect'}) ;
    % validate data
        EEG = eeg_checkset(EEG);
    % #############################################################
    %               REMOVE OUTER BAND OF ELECTRODES
    % #############################################################
        if rmOuterBand
            %setdiff takes two dataset arrays and returns the data in A that is not in B
            %EEG.chanlocs.labels retrives all the labels/names of the channels in the dataset 
            %chan.IDs are the ones we want to keep (minus outer band) 
            chanIDs = setdiff({EEG.chanlocs.labels}, params.chans.IDs);
            %pop_select keeps only the channels requested 
            EEG = pop_select(EEG, 'channel', chanIDs) ;
            EEG.setname = [EEG.setname '_cs'] ;
            EEG = eeg_checkset( EEG );
        end
        chanIDs = {EEG.chanlocs(1:end-1).labels}; % skip Cz
%         scalpchan = find(~ismember(1:EEG.nbchan, eblnkchan)); % ****** moved down to after outer band is removed, scalp chans defined by 109 elec
    % report how many channels are present in the dataset as a data metric.
        dataQC{fileNo,1} = size(chanIDs,2);
    % check chan number (CHCK 2)
        if EEG.nbchan~=workingchannels, error('wrong channel number'), end
    % #############################################################
    %                DELETE IDLE EEG SEGMENT (ERPLAB)
    % #############################################################
%         try
%             EEG = nc_eegtrim(EEG, 1000, 1000, onsetTags);
%         catch
%             fprintf('\nOops!...There is not enough samples to keep the pre-stimulation window...\n');
%         end

    % #############################################################
    %                  APPLY HIGHPASS FILTER 
    % #############################################################
        fprintf('Highpass filtering the data...\n');
        %putting the defined high pass filter on every channel except cz
        EEG  = pop_basicfilter( EEG,  1:EEG.nbchan-1 , 'Boundary', 'boundary', 'Cutoff', hpFilt,...
            'Design', 'butter', 'Filter', 'highpass','Order',  2, 'RemoveDC', 'on');
    % #############################################################
    %                   RESAMPLE EEG DATA
    % #############################################################
        if params.downsample>1 && EEG.srate~=params.downsample
            EEG = pop_resample( EEG, params.downsample );
            EEG = eeg_checkset( EEG );
        end
    % #############################################################
    %                   LINE NOISE REMOVAL
    % #############################################################
%         if removelinenoise % skip Cz
%         % Apply cleanLineNoise
%             fprintf('Removing line noise (50 or 60 Hz)...\n');
%             if fileNo==1
%                 lineNoiseIn = struct('lineNoiseMethod', 'clean', 'lineNoiseChannels', ...
%                     1:EEG.nbchan-1, 'Fs', EEG.srate, 'lineFrequencies', params.lineNoise.freq,...
%                     'p', 0.01, 'fScanBandWidth', 2, 'taperBandWidth', 2,...
%                     'taperWindowSize', 4, 'taperWindowStep', 4, ...
%                     'tau', 100, 'pad', 2, 'fPassBand', [0 EEG.srate/2], ...
%                     'maximumIterations', 10) ;
%             end
%             EEG = cleanLineNoise(EEG, lineNoiseIn); %*changed from cleanLineNoise2 to cleanLineNoise
%         end

    % #############################################################
    %                 APPLY LOWPASS FILTER 
    % #############################################################
        fprintf('Lowpass filtering the data...\n'); % skip Cz
        EEG  = pop_basicfilter( EEG,  1:EEG.nbchan-1 , 'Boundary', 'boundary',...
            'Cutoff', lpFilt,'Design', 'butter', 'Filter', 'lowpass',...
            'Order',  lpFiltOrder);
    % #############################################################
    %               HAPPE WAVELET THRESHOLDING 
    %                   (happe_wavThresh)
    % #############################################################
        %controls if waveleting sould be applied. if happeWav is not empty
        %(contains some value or =true) then run this code 
        if ~isempty(happeWav)
            %converts data to double precision (computer stuff) 
            EEG.data = double(EEG.data);
            %srate = sampling rate. how man samples per second
            if EEG.srate > 500
                wavLvl = 10;
            elseif EEG.srate > 250 && EEG.srate <= 500
                wavLvl = 9;
            elseif EEG.srate <=250
                wavLvl = 8;
            end
            %reshapes the data for wavelet
            wdata = reshape(EEG.data, size(EEG.data, 1), [])';
            ThresholdRule = 'Hard';
            artifacts = wdenoise(wdata, wavLvl, 'Wavelet', 'coif4', 'DenoisingMethod', ...
                'Bayes', 'ThresholdRule', ThresholdRule, 'NoiseEstimate', ...
                'LevelDependent')';
            %reshpaes the original EEG data to original format before denoising
            preEEG      = reshape(EEG.data, size(EEG.data,1), []);
            %substracts estimated artifacts from OG data 
            postEEG     = preEEG - artifacts;
            %Cleaned data is assigned back to EEG.data 
            EEG.data    = postEEG ;
            EEG.setname = 'wavcleanedEEG';
        end
    % #############################################################
    %                      DETECT BAD CHANNELS 
    % #############################################################
        if params.badChans.rej
        % JAVIER BAD CHAN
            fprintf('\n*** Searching (Javier''s function) for bad channels...\n');
            badchan     = nc_detectBadChannels(EEG, [1 0 0 0],[300 0 0 0], 25);
            %stores the indicies of the bad channels 
            badchanindx_javier = find(badchan);
        % merge bad channel indices
            goodchanindx_all = 1:EEG.nbchan; % good channels (default all)
            badchanindx_all  = unique([badchanindx_javier]);
            %stores the number of bad channels
            lbch = length(badchanindx_all);
            if lbch>0
            % Javier's trick to carrier bad channel indices
            %the bad channel indicies are stored in the EEG strucutre comments field
                EEG.comments = badchanindx_all;
                %prints warning message with subject ID and indicies of bad channel
                fprintf('WARNING: Subject %s, has %g bad channels detected --> ', subID, lbch);
                fprintf('Channel indices: [ ');
                for kk=1:lbch
                    fprintf('%g  ', badchanindx_all(kk));
                end
                fprintf(' ]\n');
            % correct good channel indices - updates list of good channel by removing the bad channels 
                goodchanindx_all = goodchanindx_all(~ismember(goodchanindx_all, badchanindx_all));
            % correct bad chan data metric
                bchanstr = sprintfc('E%d', badchanindx_all);
                %number of good channels after bad channels are removed
                dataQC{fileNo,2} = dataQC{fileNo,1} - size(badchanindx_all,2);
                %percentage of good channels relative to total 
                dataQC{fileNo,3} = dataQC{fileNo,2}/dataQC{fileNo,1}*100;
                %list of bad channels
                dataQC{fileNo,4} = sprintf('%s ',bchanstr{:});
            else
                dataQC{fileNo,2} = size(chanIDs,2) ;
                dataQC{fileNo,3} = dataQC{fileNo,2}/dataQC{fileNo,1}*100;
                dataQC{fileNo,4} = 'NA' ;
                goodchanindx_all  = 1:EEG.nbchan; % good channels (default all)
            end
        end
    % WAVELETING QC METRICS: Assesses the performance of wavelet thresholding.
    %compares pre and post wavelet data. 
        if ~isempty(goodchanindx_all) % Only good channels
            if ~isempty(happeWav)
                wavMeans = assessPipelineStep('wavelet thresholding', preEEG(goodchanindx_all,:), ...
                    postEEG(goodchanindx_all,:), wavMeans, EEG.srate, params.QCfreqs) ;
                %stores the variance ratio of pre/post data as quality metric.
                dataQC{fileNo, 6} = var(postEEG(goodchanindx_all,:), 0, 'all')/var(preEEG(goodchanindx_all,:), ...
                    1, 'all')*100 ;
            end
        else
            %if no good channels remain it returns 'too bad' 
            dataQC{fileNo, 6} = 'too bad';
        end
    % #############################################################
    %                  INTERPOLATE BAD CHANNELS
    %                (using wavelet cleaned data)
    % #############################################################
        if params.segment.interp
            if length(badchanindx_all) < (EEG.nbchan*propbadch) && ~isempty(badchanindx_all) % if there are bad channels but less than maxElInterp, do it
                EEG = eeg_interp(EEG, badchanindx_all, 'spherical');
                dataQC{fileNo,5} = length(badchanindx_all) ; % Chans Interpolated. Saves number of interpolated channels 
            elseif length(badchanindx_all) < (EEG.nbchan*propbadch) && isempty(badchanindx_all) % if no bad chans, carry on
                dataQC{fileNo,5} = 'None, all good!'; 
            elseif length(badchanindx_all) > (EEG.nbchan*propbadch)  % if there are too many bad channels, make a note and skip to next
                dataQC{fileNo,5} = ['Too_many (' num2str(length(badchanindx_all)) ')' ] ; 
                dataQC{fileNo,10} = 'FAILED - BAD CHANNELS';
                dataQC{fileNo,16} = [dataQC{fileNo,16}  ' too many bad chan;']; 
                dataQC{fileNo,7}  = fileName; % filename
                dataQC{fileNo,8}  = subAge; % visit
                continue
            end
        else
            dataQC{fileNo,5} = 'N/A' ; % Chans Interpolated
        end
    % #############################################################
    %                   AVERAGE RE-REFERENCE
    % #############################################################
        if params.reref.on
            fprintf('Re-referencing...\n') ; %progress marker 
            %rereferences EEG to average of all electrodes. 
                %[] indicates that all channels are used for the average reference 
                %'keepref''on' means OG reference channel is kept in data 
            EEG = pop_reref(EEG, [], 'keepref', 'on') ;
            %labels the reference method as average or no referencing 
            refstr = 'avgref';
        else
            refstr = 'noreref';
        end
    % #############################################################
    %               SAVE PROCESSED CONTINUOUS DATASET
    % #############################################################
        pathname_write = fullfile(mffDir,subID);
    % if folder doesn't exist then make it
        if exist(pathname_write, 'dir')==0, mkdir(pathname_write); end
        EEG.setname = [outName '_Filt_DS_WavClean_' refstr];
        if ~isempty(saveSET), EEG = pop_saveset( EEG,  'filename', [EEG.setname '.set'], 'filepath', pathname_write); end
        dataQC{fileNo,10} = 'PASSED'; % Bad chan and artifacting QC status
    % #############################################################
    %            GET CONDITIONS AND EPOCH DATA ORDER
    % #############################################################
        condNames = ['fam'; 'unf'; 'cat'; 'ind'];
        conditionArray = {'Familiar', 'Untrained', 'Category', 'Individual'};
        if rmOuterBand
            eblnkchan = [8 9 14 20 21 24]; % index of eye movement channels in 109 montage
        else
            eblnkchan = [8 9 14 21 22 25]; % index of eye movement channels in 129 montage
        end
                %find all the indicies of channels expect for the eye channels 
                scalpchan = find(~ismember(1:EEG.nbchan, eblnkchan));
    % Create Event List
        EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
        condIndex = [];
    % loop over conditions to get event list and epoch based on Book/Race/Counterbalance
        for cond = 1:4
            Condition = conditionArray(cond);
            if strcmpi(Condition,'Familiar') == 1
                if Race == 'A'
                    EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                    'EEG', 'Voutput', 'EEG' );
                elseif Race == 'W'
                    EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                    'EEG', 'Voutput', 'EEG' );
                elseif Race == 'B'
                    EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                    'EEG', 'Voutput', 'EEG' );
                elseif Race == 'H'
                    EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                    'EEG', 'Voutput', 'EEG' );
                end
                
            elseif strcmpi(Condition,'Category') == 1
                if Race == 'A' 
                    if strcmpi(BookNo, '1') || strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C')
                        EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '3A') || strcmpi(BookNo, '3D')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '5')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race == 'W' 
                    if strcmpi(BookNo, '2A') || strcmpi(BookNo, '2D') || strcmpi(BookNo, '6A') || strcmpi(BookNo, '6D')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '2B') || strcmpi(BookNo, '2C') || strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C')
                         EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '3A') || strcmpi(BookNo, '3D') || strcmpi(BookNo, '6B') || strcmpi(BookNo, '6C')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race == 'B' 
                    if strcmpi(BookNo, '4') || strcmpi(BookNo, '5')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif  strcmpi(BookNo, '6A') || strcmpi(BookNo, '6D')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '6B') || strcmpi(BookNo, '6C')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race =='H' 
                    if strcmpi(BookNo, '1') || strcmpi(BookNo, '2B') || strcmpi(BookNo, '2C')
                        EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '2A') || strcmpi(BookNo, '2D')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '4')
                        EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                        'EEG', 'Voutput', 'EEG' );
                    end
                end %Condition Category
    
            elseif strcmpi(Condition,'Individual') == 1
                if Race == 'A' 
                   if strcmpi(BookNo,'3A') ||  strcmpi(BookNo,'3D')
                      EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C') || strcmpi(BookNo, '5') 
                      EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '1')
                      EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   end
                elseif Race == 'W' 
                   if strcmpi(BookNo, '2B') || strcmpi(BookNo, '2C') || strcmpi(BookNo, '6B') || strcmpi(BookNo, '6C') 
                      EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   elseif strcmpi(BookNo, '2A') || strcmpi(BookNo, '2D') || strcmpi(BookNo, '3A') || strcmpi(BookNo, '3D') 
                      EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                     'EEG', 'Voutput', 'EEG' );
                   elseif strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C') || strcmpi(BookNo, '6A') || strcmpi(BookNo, '6D') 
                      EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   end
                elseif Race =='B' 
                   if strcmpi(BookNo, '6B') || strcmpi(BookNo, '6C') || strcmpi(BookNo, '4')
                      EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '6A') || strcmpi(BookNo, '6D') || strcmpi(BookNo, '5')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                   end
                elseif Race =='H' 
                   if strcmpi(BookNo, '2A') || strcmpi(BookNo, '2D')
                      EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   elseif strcmpi(BookNo, '2B') || strcmpi(BookNo, '2C') || strcmpi(BookNo, '4')
                      EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   elseif strcmpi(BookNo, '1')
                      EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                      'EEG', 'Voutput', 'EEG' );
                   end
                end %Condition Individual        
                
            elseif strcmpi(Condition,'Untrained') == 1
                if Race == 'A' 
                    if strcmpi(BookNo, '1')
                          EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                          'EEG', 'Voutput', 'EEG' );
                        elseif strcmpi(BookNo, '5')
                          EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                          'EEG', 'Voutput', 'EEG' );            
                        elseif strcmpi(BookNo, '3A') || strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C') || strcmpi(BookNo, '3D')
                            EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                            'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race == 'W' 
                    if strcmpi(BookNo, '3A') || strcmpi(BookNo, '3B') || strcmpi(BookNo, '3C') || strcmpi(BookNo, '3D')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo,'2A') || strcmpi(BookNo, '2B') || strcmpi(BookNo, '2C') || strcmpi(BookNo, '2D')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '6A') || strcmpi(BookNo, '6B') || strcmpi(BookNo, '6C') || strcmpi(BookNo, '6D')
                       EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race == 'B' 
                    if strcmpi(BookNo, '4')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Hispanic.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '5')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '6A') || strcmpi(BookNo, '6B')|| strcmpi(BookNo, '6C')|| strcmpi(BookNo, '6D')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    end
                elseif Race == 'H' 
                    if strcmpi(BookNo, '4')
                       EEG2  = pop_binlister( EEG , 'BDF', 'AfAmerican.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '1') 
                       EEG2  = pop_binlister( EEG , 'BDF', 'Asian.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    elseif strcmpi(BookNo, '2A') || strcmpi(BookNo, '2B')|| strcmpi(BookNo, '2C')|| strcmpi(BookNo, '2D')
                       EEG2  = pop_binlister( EEG , 'BDF', 'Caucasian.txt', 'IndexEL',  1, 'SendEL2',...
                       'EEG', 'Voutput', 'EEG' );
                    end
                end % condition Untrained
            end % outermost condition loop

        % #############################################################
        %                       EPOCHING 
        % #############################################################  
        % Create bin-based epochs
            EEG3 = pop_epochbin( EEG2 , epochWin,bslWin); 
        % Artifact detection: 1st round
            %only use scalp channels, flag the epochs containing artifacts, use previously defined threshold, use epoch window for artifact detection 
            EEG3  = pop_artextval( EEG3 , 'Channel',  scalpchan, 'Flag',  1, 'Threshold', segAmpThres, 'Twindow', epochWin); % BEES PIPELINE
            % ###########################################################
                % check for remaining bad channels that takes most of
                % the artifact detection (usually 1 damn bad channel)
                % However, this time pick only 3 channels that explain
                % more than 50% of the artifacts
    
                %gets field names of the eeg.reject structure 
                Frej = fieldnames(EEG3.reject);
                %finds fields related to channels that might contain rejection information 
                sfields1 = regexpi(Frej, '\w*E$', 'match');
                sfields2 = [sfields1{:}];
                nfield   = length(sfields2);
                %calculates the number of rejected epochs per channel 
                histE    = zeros(EEG3.nbchan, EEG3.trials);
                %loops over each rejected channel and updates histE 
                for i=1:nfield
                    fieldnameE = char(sfields2{i});
                    if ~isempty(EEG3.reject.(fieldnameE))
                        histE = histE | [EEG3.reject.(fieldnameE)]; % electrodes
                    end
                end
                %caluclates the number of rejected epochs per channel
                histeEF = sum(histE,2)';
                Ttop = EEG3.trials;
                %channels where more than 50% of epochs are rejected 
                badchanindx = find([(histeEF/Ttop)*100]>50);
                %interpolating bad channels. limited to 5 channels 
                if ~isempty(badchanindx)
                    if length(badchanindx)>5
                        badchanindx = badchanindx(1:5);
                    end
                    fprintf('\n### Interpolating %g channels...\n', length(badchanindx));
                    EEG3 = eeg_interp(EEG3, badchanindx, 'spherical');
                end
            % ###########################################################
        % Artifact detection: 2nd round
        %making sure interpolation didn't create artifacts 
            EEG3  = pop_artextval( EEG3 , 'Channel',  scalpchan, 'Flag',  1, 'Threshold', segAmpThres,'Twindow', epochWin); % BEES PIPELINE  
            [~, tprej, acce,rej] = pop_summary_AR_eeg_detection(EEG3, 'none'); % summarize artifact detection 
            goodCondstmp = find(acce>0);
        % get epoch indices from "good" trials 
           if isempty(goodCondstmp)
                fprintf(['Oops! No good epochs were found for ' cell2mat(Condition) '...\n']);
                dataQC{fileNo,16} = [dataQC{fileNo,16}  ' no good epochs - ' cell2mat(Condition) ';']; 
                goodTri_byCond(:,cond) = acce;
                badTri_byCond(:,cond) = rej;
                continue
           else   
               EpochIndex  = getepochindex6(EEG3, 'Bin', goodCondstmp, 'Nepoch', 'amap','Artifact','good');
               EpochIndex  = cell2mat(EpochIndex);
            % get save good trials 
            % retrives idnex of good epochs. Epoch index has indicies of epochs that pass artifact rejection 
                fprintf(['Saving time data for ' cell2mat(Condition) '...\n']);
                eval(['timeData.' condNames(cond,:) ' = double(EEG3.data(:,:,EpochIndex));']) %
            end % if epoch index
        % pool good and bad trial counts across conds
            goodTri_byCond(:,cond) = acce;
            badTri_byCond(:,cond) = rej;
        end % condition loop, for event list & epoching (starts line 399ish)
    
    % #############################################################
    %               FREQTAG SLIDING WINDOW FFT
    % #############################################################
    fprintf('Running FreqTag sliding window and FFT...\n');
    amp12 = nan(109,2000,4); amp6 = nan(109,400,4);
    winmat12 = nan(109,4000,4); winmat6 = nan(109,800,4);
        for cond = 1:4
            if isfield(timeData,condNames(cond,:))
                inMat = eval(['timeData.' condNames(cond,:)]);
            % sliding window
                [~,tmp_winmat3d_12] = OREP_flex_slidewin_1mat(inMat, 0, 1:250, 251:10250, 1.2, 600, 500);
                [~,tmp_winmat3d_6] = OREP_flex_slidewin_1mat(inMat, 0, 1:250, 251:10250, 6, 600, 500);
            % FFT on trial avgs
                data12 = mean(tmp_winmat3d_12,3);
                    [amp12(:,:,cond), ~, faxis12] = freqtag_FFT(data12, 600);
                data6 = mean(tmp_winmat3d_6,3);
                    [amp6(:,:,cond), ~, faxis6] = freqtag_FFT(data6, 600);
                
                winmat12(:,:,cond) = data12; winmat6(:,:,cond) = data6;
                faxis12 = faxis12'; faxis6 = faxis6';
            end % if condition data exists
        end % cond, for frqtag sliding window

    % save mat output file
        fprintf(['Saving subj ' subID ' mat file...\n']);
        save(fullfile(path_matfiles,[outName '.mat']),'timeData','goodTri_byCond','badTri_byCond','amp12','amp6','faxis12','faxis6','winmat12','winmat6','badchanindx_all','-v7.3');
        % MAT FILE OUTPUT:
            % timeData = segmented time series data -500:20s
            % goodTri_byCond/badTri_byCond = good/bad trial count by condition
            % amp12/amp6 = freqtag amplitude for 1.2 and 6 Hz
            % faxis12/faxis6 = frequency axes for 1.2 and 6 Hz
            % winmat12/winmat6 = trial averaged time data, post- sliding window 

    % #############################################################
    %               FILL IN DATA QC METRICS
    % #############################################################
        dataQC{fileNo,7}  = fileName; % filename
        dataQC{fileNo,8}  = subAge; % visit
        dataQC{fileNo,9}  = sum(goodTri_byCond); % overall good trial count
        dataQC{fileNo,11} = (sum(badTri_byCond)./sum([goodTri_byCond badTri_byCond]))*100; % overall percent rejected trials 
        dataQC{fileNo,12} = goodTri_byCond(:,1); % good trial count Fam
        dataQC{fileNo,13} = goodTri_byCond(:,2); % good trial count Unfam 
        dataQC{fileNo,14} = goodTri_byCond(:,3); % good trial count Cat
        dataQC{fileNo,15} = goodTri_byCond(:,4); % good trial count Indiv
        clear EEG EEG2 EEG3 EpochIndex timeData  amp6 amp12 winmat12 winmat6 goodTri_byCond badTri_byCond 
    end % file
% #############################################################
%               WRITE DATA QC TABLE
% #############################################################  
    disp('Preprocessing Done!')
    fprintf('\nNow saving the table...\n') ;
    dataQCtable = cell2table(dataQC,'VariableNames',dataQCnames);
% reorganize variables of the table
    dataQCtable = movevars(dataQCtable,{'Filename','Percent_Good_Chans','BadChan_Artifact_QC',...
        'Overall_Good_Trial_Count','%_Tri_Rej'},'Before','Number_User-Selected_Chans');
% save the table & outmat
    taildate = str2mat(string(datetime,"MMMdd-HHmm"));
    tablename = ['OREP_OUTPUT' outname2 '_' taildate '.xlsx'];
    writetable(dataQCtable, tablename);
    disp('All Done!')
    dt2 = datetime;
    clc
    fprintf('\n* PrePro --> start: %s , end: %s , duration: %s\n',dt1,dt2,dt2-dt1); 
% Coded by J.L-C.
% Newencode Analytics
% www.newencode.com
% April-September, 2022
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.               