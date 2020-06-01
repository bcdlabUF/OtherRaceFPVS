function y = OREP_SSVEP_face_discrimination()
%% Initial set-up
clc;  
clear;      
%  

      
if usejava('System.time')
    disp('error loading java package "System.time"');
    return;
end
if usejava('java.util.LinkedList') 
    disp('error loading java package "java.util.ArrayDeque"');
    return;  
end
try
    AssertOpenGL;
    
    % Prompt box for subnum and counterbalance; creates variables for these
    prompt = {'Subject Number','Counterbalance', 'Book Number'};
    defaults = {'1','1','0'}; %default book number 0 doesn't exist... look into the correct way to format three input boxes
    answer = inputdlg(prompt,'Subnum',1,defaults);
    if(size(answer) ~= 3)
        clear;
        clc;
        disp('Exiting.'); % program exits here because of booknum...
        return;
    end
    
    
    Priority(2);
    [subject,counterbalance,bookNum] = deal(answer{:});
    
    counterbalance = str2num(counterbalance);
    
%     rng('Shuffle');
    fid = fopen('Subinfo.txt','a+');
    
    
    % Set stimuli directories for each race (to present images)
    AfrAm = dir(fullfile('/Images/AfrAm/*.png'));
    Caucasian = dir(fullfile('/Images/Caucasian/*.png'));
    Asian = dir(fullfile('/Images/Asian/*.png'));
    Hispanic = dir(fullfile('/Images/Hispanic/*.png'));
    
    
    afrList = 'NewLists/BF';
    caucList = 'NewLists/WF';
    asiaList = 'NewLists/AF';
    hispList = 'NewLists/HF';
    
    text = '.txt';
    
    %this code above breaks down the file name parts, necessary for the list to be read
    % this code below adds these file name parts together, will be the variable
    % of the file that 'textread' reads from.
    
    afrAmFile = [afrList bookNum text];
    caucFile = [caucList bookNum text];
    asianFile = [asiaList bookNum text];
    hispanicFile = [hispList bookNum text];
    
    
    
    
    % Read in text files for stim lists
    [AfrAmNames] = textread(afrAmFile,'%s'); %#ok<*REMFF1>
    [CaucasianNames] = textread(caucFile,'%s'); %#ok<*REMFF1>
    [AsianNames] = textread(asianFile,'%s'); %#ok<*REMFF1>
    [HispanicNames] = textread(hispanicFile,'%s'); %#ok<*REMFF1>
    
    
    % Shuffle order of each race and create a randomized list of each
    % race
    % length of text file changes so check length first, store in variable,
    % to be used in randperm and shuffle. etc..
    
    nAfrAm = length(AfrAmNames);
    nCaucasian = length(CaucasianNames);
    nAsian = length(AsianNames);
    nHispanic = length(HispanicNames);
    
    RandAfrAm = randperm(nAfrAm);
    RandCaucasian = randperm(nCaucasian);
    RandAsian = randperm(nAsian);
    RandHispanic = randperm(nHispanic);
    
    AfrAmShuffle = AfrAmNames(RandAfrAm);
    CaucasianShuffle = CaucasianNames(RandCaucasian);
    AsianShuffle = AsianNames(RandAsian);
    HispanicShuffle = HispanicNames(RandHispanic);
    
    
    % Randomize divvying up 4 faces/race per task - random, no replacement
    
    
    AfrAmList = [AfrAmShuffle(1:nAfrAm)];
    CaucasianList = [CaucasianShuffle(1:nCaucasian)];
    AsianList = [AsianShuffle(1:nAsian)];
    HispanicList = [HispanicShuffle(1:nHispanic)];
    
    fprintf(fid,'SubNum\tCounterbalance\tBookNum\tBlock\tTrial\tStimulus\tRace\n');
    
    
    % Connect to NetStation
    DAC_IP = '10.10.10.42';
    NetStation('Connect', DAC_IP, 55513);
    NetStation('Synchronize');
    NetStation('StartRecording');
    
    % Set up the screen
    Screen('Preference', 'SkipSyncTests', 2);
    screennum = 2;
%     white = WhiteIndex(screennum);
    gray = GrayIndex(screennum);
    black = BlackIndex(screennum);
    [w, wRect] = Screen('OpenWindow',screennum,gray);
    Screen('BlendFunction',w ,GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    fps = 120;
    hz=Screen(screennum,'FrameRate',[], fps);
    

    % Set up for ssVEP size variation
    xsize = 600;
    ysize = 600;
    x = 0; % Drawing position relative to center
    y = 0;
    x0 = wRect(3)/2; % Screen center
    y0 = wRect(4)/2;
    sizevary = [.90,.94,.98,1.02,1.06,1.10];
    
    
    %% Run through the tasks in the correct order
    nTask = 1;
    nSpecies = 4;
    nStimuli = 6;
    TimessVEP = 20; % 
    FreqssVEP = 6; % Hz
    nTrialssVEP = 1; % number of ssVEP trials - 1
    nImagesssVEP = floor(TimessVEP*FreqssVEP); % floor stops presenting at an image instead of half an image or something
    
    %nAlpha = 10.75 ;  % the amount of different alpha values to be presented per stimuli; 10 for 120Hz and 5 for 60Hz 
    nAlpha =40 ;
    framesPerStimuli = floor(1 / (FreqssVEP * nAlpha));  % calculate the exact number of frames per stimulus
    waitTime = 0; 
    
    milli = 1000000;   % one millisecond
    nMillis = 2;
    %     secs = 1 / (FreqssVEP * nStimuli * nAlpha);
    %     secs = .0099;
    
    
    % initialize stimuli for ssVEP tasks
    import java.util.LinkedList;
    import java.util.ArrayDeque;
    presStims1 = LinkedList();
    presStims2 = LinkedList();
    
    destrect1 = LinkedList();
    destrect2 = LinkedList();
    
    %% Preload the stimuli for ssVEP tasks
    
    Screen('DrawText', w, 'Preparing stimuli', x0 - 110, y0, black, gray);
    [standon] = Screen('Flip', w);
    
    ssVEPStims1 = presStims1.clone();
    ssVEPStims2 = presStims2.clone();
    
    Screen('DrawText', w, 'Finished preparing stimuli, press any key to begin', x0 - 400, y0, black, gray);
    [standon] = Screen('Flip', w);
    
    KbWait([], 2);    % postpone the presentation of the stimuli until any key is pressed
    KbEventFlush;
    Screen(w, 'FillRect', gray);
    [standon] = Screen('Flip', w);
    
    %% Begin Executing Tasks
    numTimesRun = 8;
    for trialNum=1:numTimesRun
        disimagedata1 = imread(char('Images/Distractors/d2.bmp'));
        disimagedata2 = imread(char('Images/Distractors/d4.bmp'));
        
        KbQueueCreate()
        %     newSec = GetSecs;
        %     initialTime = GetSecs;
        
        imageCount = 0;
        
        times = LinkedList();
        
        
        % creates event labels based on the specific counterbalance value
        
        for stim=1 : nSpecies
            if (stim == 1 && counterbalance == 1) || (stim == 2 && counterbalance == 2) ...
                    || (stim == 4 && counterbalance == 3) || (stim == 4 && counterbalance == 4) ...
                    || (stim == 3 && counterbalance == 5) || (stim == 3 && counterbalance == 6) ...
                    || (stim == 1 && counterbalance == 7) || (stim == 1 && counterbalance == 8) ...
                    || (stim == 4 && counterbalance == 9) || (stim == 4 && counterbalance == 10) ...
                    || (stim == 3 && counterbalance == 11) || (stim == 3 && counterbalance == 12) ...
                    || (stim == 1 && counterbalance == 13) || (stim == 1 && counterbalance == 14) ...
                    || (stim == 3 && counterbalance == 15) || (stim == 3 && counterbalance == 16) ...
                    || (stim == 2 && counterbalance == 17) || (stim == 2 && counterbalance == 18) ...
                    || (stim == 1 && counterbalance == 19) || (stim == 1 && counterbalance == 20) ...
                    || (stim == 4 && counterbalance == 21) || (stim == 4 && counterbalance == 22) ...
                    || (stim == 2 && counterbalance == 23) || (stim == 2 && counterbalance == 24)
                speciesName = 'Caucasian';
            elseif (stim == 2 && counterbalance == 1) || (stim == 1 && counterbalance == 2) ...
                    || (stim == 1 && counterbalance == 3) || (stim == 1 && counterbalance == 4) ...
                    || (stim == 1 && counterbalance == 5) || (stim == 1 && counterbalance == 6) ...
                    || (stim == 2 && counterbalance == 7) || (stim == 2 && counterbalance == 8) ...
                    || (stim == 2 && counterbalance == 9) || (stim == 2 && counterbalance == 10) ...
                    || (stim == 2 && counterbalance == 11) || (stim == 2 && counterbalance == 12) ...
                    || (stim == 4 && counterbalance == 13) || (stim == 4 && counterbalance == 14) ...
                    || (stim == 4 && counterbalance == 15) || (stim == 4 && counterbalance == 16) ...
                    || (stim == 4 && counterbalance == 17) || (stim == 4 && counterbalance == 18) ...
                    || (stim == 3 && counterbalance == 19) || (stim == 3 && counterbalance == 20) ...
                    || (stim == 3 && counterbalance == 21) || (stim == 3 && counterbalance == 22) ...
                    || (stim == 3 && counterbalance == 23) || (stim == 3 && counterbalance == 24)
                speciesName = 'AfrAm';
            elseif (stim == 3 && counterbalance == 1) || (stim == 4 && counterbalance == 2) ...
                    || (stim == 2 && counterbalance == 3) || (stim == 3 && counterbalance == 4) ...
                    || (stim == 4 && counterbalance == 5) || (stim == 2 && counterbalance == 6) ...
                    || (stim == 3 && counterbalance == 7) || (stim == 4 && counterbalance == 8) ...
                    || (stim == 3 && counterbalance == 9) || (stim == 1 && counterbalance == 10) ...
                    || (stim == 1 && counterbalance == 11) || (stim == 4 && counterbalance == 12) ...
                    || (stim == 2 && counterbalance == 13) || (stim == 3 && counterbalance == 14) ...
                    || (stim == 1 && counterbalance == 15) || (stim == 2 && counterbalance == 16) ...
                    || (stim == 1 && counterbalance == 17) || (stim == 3 && counterbalance == 18) ...
                    || (stim == 2 && counterbalance == 19) || (stim == 4 && counterbalance == 20) ...
                    || (stim == 1 && counterbalance == 21) || (stim == 2 && counterbalance == 22) ...
                    || (stim == 1 && counterbalance == 23) || (stim == 4 && counterbalance == 24)
                speciesName = 'Asian';
            elseif (stim == 4 && counterbalance == 1) || (stim == 3 && counterbalance == 2) ...
                    || (stim == 3 && counterbalance == 3) || (stim == 2 && counterbalance == 4) ...
                    || (stim == 2 && counterbalance == 5) || (stim == 4 && counterbalance == 6) ...
                    || (stim == 4 && counterbalance == 7) || (stim == 3 && counterbalance == 8) ...
                    || (stim == 1 && counterbalance == 9) || (stim == 3 && counterbalance == 10) ...
                    || (stim == 4 && counterbalance == 11) || (stim == 1 && counterbalance == 12) ...
                    || (stim == 3 && counterbalance == 13) || (stim == 2 && counterbalance == 14) ...
                    || (stim == 2 && counterbalance == 15) || (stim == 1 && counterbalance == 16) ...
                    || (stim == 3 && counterbalance == 17) || (stim == 1 && counterbalance == 18) ...
                    || (stim == 4 && counterbalance == 19) || (stim == 2 && counterbalance == 20) ...
                    || (stim == 2 && counterbalance == 21) || (stim == 1 && counterbalance == 22) ...
                    || (stim == 4 && counterbalance == 23) || (stim == 1 && counterbalance == 24)
                speciesName = 'Hispanic';
            end
            for Trial=1:nTrialssVEP
                Screen(w, 'FillRect', gray);  % makes the back buffer blank
                [standon] = Screen('Flip', w); % flips the back and front buffer
                %          [buttons] = GetClicks(w); % Listens for mouseclicks
                switch speciesName %Change the event label based on species
                    case 'AfrAm'
                        label = 'b11';
                    case 'Caucasian'
                        label = 'c12';
                    case 'Asian'
                        label = 'a13';
                    case 'Hispanic'
                        label = 'h14';
                end
                
                dissoundfile = 'Audio/Distractors/s6.wav';
                InitializePsychSound;
                Channels = 1;
                %MySoundFreq = 11025;
                MySoundFreq = 32000;
                disp(dissoundfile)
                diswavdata = transpose(audioread(dissoundfile));
                MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
                FinishTime1 = length(diswavdata)/MySoundFreq;
                PsychPortAudio('FillBuffer',MySoundHandle,diswavdata,0);
                %gives chance to use distractors by looking until mouse click
                [keyIsDown] = KbCheck(); %Listens for Keypresses
                [xpos,ypos,buttons] = GetMouse();
                while ~any(buttons) % Loops while no mouse buttons are pressed
                    [keyIsDown] = KbCheck();
                    [xpos,ypos,buttons] = GetMouse();
                    if any(keyIsDown)
                        disrand = char(randi(4));
                        
                        disimage = Screen('MakeTexture',w,disimagedata2);
                        
                        Screen('DrawTexture',w,disimage);
                        Screen('Flip',w);
                        
                        PsychPortAudio('Start',MySoundHandle,1,0,1);
                        
                        WaitSecs(FinishTime1);
                        
                        Screen(w, 'FillRect', gray);
                        Screen('Flip',w);
                        WaitSecs(.01);
                        KbEventFlush;
                    end
                    
                end
                KbEventFlush
                
                %if any(buttons) % Present images on mouseclick
                
                %                 NetStation('Event',label, GetSecs, GetSecs+cputime, 'trl#',trialNum,'race',speciesName); % signals the beginning of a trial
                
                desrectTemp = destrect1;
                for Task=1:nTask
                    for Species=1:nSpecies
                        if counterbalance == 1
                            if Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                            disp(Species);
                        end
                        if counterbalance == 2
                            if Species==1
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==2
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        
                        if counterbalance == 3
                            if Species==1
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 4
                            if Species==1
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 5
                            if Species==1
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 6
                            if Species==1
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 7
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 8
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 9
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 10
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 11
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        
                        if counterbalance == 12
                            if Species==2
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 13
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        
                        if counterbalance == 14
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 15
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 16
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==3
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 17
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==2
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==3
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 18
                            if Species==4
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==2
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==3
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 19
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 20
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==1
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 21
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==2
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 22
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==4
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==2
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 23
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==2
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==1
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==4
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance == 24
                            if Species==3
                                thisSpecies = AfrAm;
                                speciesName = 'AfrAm';
                                thisTask = AfrAmList(:,Task);
                            elseif Species==2
                                thisSpecies = Caucasian;
                                speciesName = 'Caucasian';
                                thisTask = CaucasianList(:,Task);
                            elseif Species==4
                                thisSpecies = Asian;
                                speciesName = 'Asian';
                                thisTask = AsianList(:,Task);
                            elseif Species==1
                                thisSpecies = Hispanic;
                                speciesName = 'Hispanic';
                                thisTask = HispanicList(:,Task);
                            end
                        end
                        if counterbalance > 24
                            error('Enter a number from 1-24')
                        end
                        
                        
                        if Task==1 %(we only have one task)
                            standard = -1; % initially sets standard to something impossible
                            for Trial=1:nTrialssVEP
                                oddball = -1;
                                newstandard = randi(3);
                                while newstandard == standard
                                    newstandard = randi(3); % checks to make sure standard is not repeated twice in a row
                                end
                                standard = newstandard;
                                standardshow = thisTask(standard);
                                for image=1:nImagesssVEP
                                    sizepick = sizevary(randi(numel(sizevary)));
                                    s = sizepick;
                                    destrect = [x0-s*xsize/2+x,y0-s*ysize/2+y,x0+s*xsize/2+x,y0+s*ysize/2+y]; % For size variation
                                    destrect1.add(destrect);
                                    sourcerect = [x0-xsize/2+x,y0-ysize/2+y,x0+xsize/2+x,y0+ysize/2+y];
                                    if mod(image,5) ~= 0 % checks if image number is divisible by 5; if not, add images to the standard list
                                        
                                        st = char(standardshow);
                                        showstring = '';
                                        luminancevalue = randi(9); %Make the image a random luminance
                                        switch luminancevalue
                                            case 1
                                                lumstring = '+40';
                                            case 2
                                                lumstring = '+30';
                                            case 3
                                                lumstring = '+20';
                                            case 4
                                                lumstring = '+10';
                                            case 5
                                                lumstring = '';
                                            case 6
                                                lumstring = '-10';
                                            case 7
                                                lumstring = '-20';
                                            case 8
                                                lumstring = '-30';
                                            case 9
                                                lumstring = '-40';
                                        end
                                        if st(2) == '.'
                                            showstring = st(1);
                                        else
                                            showstring = st(1:3);
                                        end
                                        
                                        filename = strjoin({'Images', speciesName, strcat(showstring, lumstring, '.png')}, '/');
                                        
                                
                                       
                                        
                                        filename;
                                        presStims1.add(filename); %adds standard images of varying luminance to the list "presStims1"
                                        %             timeoftrial_stand=toc
                                    elseif mod(image,5) == 0 % if remainder is divisible by 5, add images to the oddball list
                                        newoddball = randi(3);
                                        while newoddball == oddball || newoddball == standard
                                            newoddball = randi(3);
                                        end
                                        oddball = newoddball;
                                        oddballshow = thisTask(newoddball);
                                        
                                        st = char(oddballshow);
                                        showstring = '';
                                        if st(2) == '.'
                                            showstring = st(1);
                                        else
                                            showstring = st(1:3);
                                        end
                                        luminancevalue = randi(9); %Make the image a random luminance
                                        switch luminancevalue
                                            case 1
                                                lumstring = '+40';
                                            case 2
                                                lumstring = '+30';
                                            case 3
                                                lumstring = '+20';
                                            case 4
                                                lumstring = '+10';
                                            case 5
                                                lumstring = '';
                                            case 6
                                                lumstring = '-10';
                                            case 7
                                                lumstring = '-20';
                                            case 8
                                                lumstring = '-30';
                                            case 9
                                                lumstring = '-40';
                                        end
                                        filename = strjoin({'Images', speciesName, strcat(showstring, lumstring, '.png')}, '/');
                                        
                                        filename;
                                        presStims1.add(filename); %creates the list of oddball stimuli
                                        %                            timeoftrial_odd = toc
                                    end
                                end
                                
                                
                                Screen('Close'); % Supposed to clean up old textures
                                %                     fprintf(fid,'%s\t%d\t%s\t%d\t%d\t%s\n',subject,counterbalance,bookNum,trialNum,stim,char(standardshow));
                                
                                
                            end
                            
                        end
                        fprintf(fid,'%s\t%d\t%s\t%d\t%d\t%s\n',subject,counterbalance,bookNum,trialNum,stim,char(standardshow));
                    end
                    
                end
                % end pasted junk
                screens = ArrayDeque(120);
                for image=1:nImagesssVEP
                    
                    imageCount = imageCount + 1;
                    %                    imdata = imread(char(presStims1.get(imageCount))); % REMOVAL CAUSING DELAY? USE .get(imagecount)
                    
%                     [imdata, map, imdata_alpha] = imread(char(presStims1.remove()), 'BackgroundColor', 0.5);
                    [imdata, map, imdata_alpha] = imread(char(presStims1.remove()));
                    imdata(:,:,2)=imdata_alpha; % added alpha layer to 2 because images are greyscale
             
                 %ADD 30 COLUMNS OF 255 to the left AND right, then add 60
                 %rows of 255 to the top
                    mytex = Screen('MakeTexture', w, imdata);
                    
                    screens.add(mytex);
                end
                
                imageCount = 0;
                tic
                NetStation('Event',label, GetSecs, GetSecs+cputime, 'trl#',trialNum,'race',speciesName); % signals the beginning of a trial
                for image=1:nImagesssVEP
                    
                    destrect = destrect1.remove();
                    
                    imageCount = imageCount + 1;
                    % PROBLEMS START HERE
                    
                    if mod(image,5) ~= 0 % checks if divisible by 5; if not, present standard
                        screen = screens.getFirst();
                        screen = screens.removeFirst();
                        
                        for curAlpha = 0 : nAlpha
                            
                            Screen('DrawTexture', w, screen, [], destrect, [], [], curAlpha / nAlpha);
                            [standon] = Screen('Flip', w);
                            %                       if curAlpha / nAlpha == 1
                            %                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       elseif curAlpha / nAlpha == 0
                            %                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       end
                            %                       javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                            
                        end
                        for curAlpha = 1 : nAlpha - 1
                            %                       if curAlpha / nAlpha == 1
                            %                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       elseif curAlpha / nAlpha == 0
                            %                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       end
                            Screen('DrawTexture', w, screen, [], destrect, [], [], 1 - (curAlpha / nAlpha));
                            [standon] = Screen('Flip', w);
                            %                       javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                        end
                        %
                        %                    oldTime = newSec;
                        %                    newSec = GetSecs;
                        %                    times.add(newSec - oldTime);
                        
                        
                    elseif mod(image,5) == 0      % if remainder is divisible by 5, present oddball
                        
                        for curAlpha = 0 : nAlpha
                            
                            Screen('DrawTexture', w, screen, [], destrect, [], [], curAlpha / nAlpha);
                            [standon] = Screen('Flip', w);
                            %                       if curAlpha / nAlpha == 1
                            %                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       elseif curAlpha / nAlpha == 0
                            %                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       end
                            
                            %                       javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                        end
                        
                        for curAlpha = 1 : nAlpha - 1
                            
                            Screen('DrawTexture', w, screen, [], destrect, [], [], 1 - (curAlpha / nAlpha));
                            [standon] = Screen('Flip', w);
                            %                       if curAlpha / nAlpha == 1
                            %                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       elseif curAlpha / nAlpha == 0
                            %                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
                            %                       end
                            
                            %                       javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                        end
                        
                        %                    oldTime = newSec;
                        %                    newSec = GetSecs;
                        %                    times.add(newSec - oldTime);
                        
                        
                        % PERF PROBLEMS END HERE
                    end
                end
                timeoftrial_total = toc
                
                
                %end
                Screen('Close'); % Supposed to clean up old textures
            end
            
            
            %         fprintf(fid,'%s\t%d\t%s\t%d\t%s\n',subject,counterbalance,bookNum,trialNum,char(standardshow));
            
        end
        
        while(~times.isEmpty())
            %         disp(times.pop());
            times.pop();
        end
        
        % display some data for now ... DELETE LATER
        %    finalTime = GetSecs;
        %    disp('Final Time: ');
        %    disp(finalTime - initialTime);
        %    disp('Average Time: ');
        %    disp((finalTime - initialTime) / imageCount);
        KbQueueCreate(  );
        
        %
        while(~times.isEmpty())
            %         disp(times.pop());
            times.pop();
        end
        
    end
    WaitSecs(60);
    NetStation('Synchronize');
    NetStation('StopRecording');
    NetStation('Disconnect', '10.10.10.42');
    
    % End screen
    ThankYou = imread(char('d2.bmp'));
    disThankYou = Screen('MakeTexture',w,ThankYou);
    Screen('DrawTexture',w,disThankYou);
    Screen('Flip',w);
    
    %Listens for Keypresses
    [xpos,ypos,buttons] = GetMouse();
    while ~any(buttons) % Loops while no mouse buttons are pressed
        [keyIsDown] = KbCheck();
        [xpos,ypos,buttons] = GetMouse();
        if any(keyIsDown)
            Screen('CloseAll');
        end
    end
    
    %PsychPortAudio('Stop',MySoundHandle);
    %PsychPortAudio('Close',MySoundHandle);
    
    Priority(1);  %reset the priority
    
    % clc;    % clear the screen
    clear;  % clear the workspace
    
    disp('Process complete.');
    
    
catch
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    
    psychrethrow(psychlasterror);
end
end