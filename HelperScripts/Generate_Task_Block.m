%% ========================================================================
% CREATE STIMULUS SEQUENCE (Main Experiment Generator - 13 Block Auto-Gen)
% =========================================================================
% WHAT THIS IS:
% This MATLAB script generates the script files needed to run the main 
% behavioral task on the tACS Challenge Device. 
%
% WHAT IT DOES:
% 1. Opens a dialog box to input Lab, Subject, Sequence (S1/S2/S3) and BNC.
% 2. Automatically maps the 13 blocks to the correct conditions (A/B/C/Sh).
% 3. Prints a safety warning in the Command Window regarding BNC voltages.
% 4. Creates a timestamped folder for the subject session.
% 5. Exports 13 fully formatted text files into that folder, ready for the GUI.
%
% *** CRITICAL PREREQUISITE ***
% This script assumes you have ALREADY RUN the Staircase Titration script!
% The generated text files rely on the visual threshold variables ('a' 
% and 'b') that the staircase saved to the device's memory. DO NOT unplug 
% or restart the device between the staircase and this main experiment.
%
% HOW TO USE:
% 1. Edit the BNC parameters below (if needed).
% 2. Click "Run" (or press F5) on this MATLAB script.
% 3. Enter the Lab, Subject, Sequence, and BNC info in the pop-up box.
% 4. Check the Command Window if BNC is enabled to verify trigger settings.
% 5. In your TACSChallenge.jar program: click "Load Cmds" and select the file.
% 6. Click "Send Cmds" to begin. Repeat steps 5-6 for each block.
% =========================================================================

%% EXPERIMENT PARAMETERS (USER EDITABLE) =====================
% Define your BNC Trigger parameters here:
bnc_voltage = 5.0;  % Trigger voltage (e.g., 5.0 Volts)
bnc_duration = 100; % Trigger duration (e.g., 100 milliseconds)

%% USER INPUT VIA DIALOG BOX ==========================
prompt = {'Lab Number:', ...
          'Subject Number:', ...
          'Sequence (S1, S2, or S3):', ...
          'Use BNC Trigger for Stimulator? (1 = Yes, 0 = No) (Will automatically be turned off for Sh blocks)'};
dlgtitle = 'Experiment Setup (Batch Generation)';
dims = [1 70]; 
answer = inputdlg(prompt, dlgtitle, dims);

if isempty(answer)
    error('Experiment setup was cancelled by the user.');
end

% Extract and format inputs
Lab = sprintf('%02d', str2double(answer{1}));     
Subject = sprintf('%02d', str2double(answer{2})); 
Sequence_Choice = upper(strtrim(string(answer{3}))); % Forces uppercase S1, S2, or S3
BNC_Trigger = str2double(answer{4}); 

%% DEFINE SEQUENCES & VALIDATE ===============================
S1 = {'Sh','A','C','B','Sh','C','B','A','Sh','B','A','C','Sh'};
S2 = {'Sh','B','A','C','Sh','A','C','B','Sh','C','B','A','Sh'};
S3 = {'Sh','C','B','A','Sh','B','A','C','Sh','A','C','B','Sh'};

if strcmp(Sequence_Choice, 'S1')
    active_seq = S1;
elseif strcmp(Sequence_Choice, 'S2')
    active_seq = S2;
elseif strcmp(Sequence_Choice, 'S3')
    active_seq = S3;
else
    error('Invalid Sequence entered. Please run the script again and type exactly: S1, S2, or S3.');
end

%% GENERATE FOLDER DIRECTORY =================================
% Get current date and time in a file-safe format
timeString = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss'));

% Create the folder name
FolderName = sprintf('sub-L%s_S%s_%s', Lab, Subject, timeString);

% Check if folder exists; if not, create it
if ~exist(FolderName, 'dir')
    mkdir(FolderName);
end

%% BATCH GENERATION LOOP =====================================
fprintf('==========================================================\n');
fprintf('Generating 13 blocks for Subject %s (Lab %s) - Sequence %s\n', Subject, Lab, Sequence_Choice);
if BNC_Trigger == 1
    fprintf('BNC Trigger: ENABLED (Will dynamically turn off for Sh blocks)\n');
else
    fprintf('BNC Trigger: DISABLED\n');
end
fprintf('Saving to folder: %s\n', FolderName);
fprintf('----------------------------------------------------------\n');

for b = 1:13
    Condition = active_seq{b};
    Block = sprintf('%d', b); % No leading zero for block number
    
    % Set trials based on condition
    if strcmp(Condition, 'Sh')
        numTrials = 50;
    else
        numTrials = 150;
    end
    
    % BNC Logic for this specific block
    writeBNC = (BNC_Trigger == 1) && ~strcmp(Condition, 'Sh');
    
    % Generate Filename and Path
    Filename = sprintf('sub-L%s_S%s_B%s_%s', Lab, Subject, Block, Condition);
    FilePath = fullfile(pwd, FolderName, [Filename '_stim_seq.txt']);
    
    % define basic LED array states
    LED0 = {'*stim,a,a,a,a,a,a,'};
    LED{1} = '*stim,a,b,a,a,a,a,';
    LED{2} = '*stim,a,a,b,a,a,a,';
    LED{3} = '*stim,a,a,a,b,a,a,';
    LED{4} = '*stim,a,a,a,a,b,a,';
    LED{5} = '*stim,a,a,a,a,a,b,';
    
    % create random sequence of target types (freshly randomized per block)
    trialSeq=repmat(1:5,1,numTrials/5)'; 
    trialSeq=trialSeq(randperm(length(trialSeq))); 
    
    target_dur = 10;
    
    % Randomly Generate The ISI Duration (freshly randomized per block)
    R = zeros(numTrials,1);
    sigma = sqrt( log( 700^2 / (2800^2) + 1) );
    mu = log( 2800/exp(0.5*sigma^2) );
    while min(R) < 1500
        R = lognrnd(mu,sigma,numTrials,1);
    end
    ISI = round(R);
    
    % open text file to store experiment inside the new folder
    fId=fopen(FilePath,'w');
    
    % Write Header
    fwrite(fId,'% clear command buffer'); 
    fwrite(fId, newline);
    fwrite(fId,'clear_stim'); 
    fwrite(fId, newline);
    fwrite(fId, newline);
    
    % Open BNC Port if applicable
    if writeBNC
        fwrite(fId, '% Open BNC Port');
        fwrite(fId, newline);
        fwrite(fId, 'wbncmode,1'); 
        fwrite(fId, newline);
        fwrite(fId, newline);
    end
    
    % open logfile
    fwrite(fId, '% Open logfile');
    fwrite(fId, newline);
    fwrite(fId, ['log,open,' Filename]);
    fwrite(fId, newline);
    fwrite(fId, newline);
    
    % Write BNC trigger command if applicable
    if writeBNC
        fwrite(fId, '% send BNC Trigger to start stimulation');
        fwrite(fId, newline);
        fwrite(fId, sprintf('*trig,%.1f,%d', bnc_voltage, bnc_duration)); 
        fwrite(fId, newline);
        fwrite(fId, newline);
    end

    % write trials
    for trl = 1:numTrials
        fwrite(fId, ['%Trial ' num2str(trl)]);
        fwrite(fId, newline);
        fwrite(fId,[LED0{1}, num2str(ISI(trl))]);
        fwrite(fId, newline);
        fwrite(fId,[LED{trialSeq(trl)} num2str(target_dur)]);
        fwrite(fId, newline);
    end
     
    % Execute and close
    fwrite(fId, newline);
    fwrite(fId,'% Run the Block');
    fwrite(fId, newline);
    fwrite(fId,'start_stim');
    fwrite(fId, newline);
    fwrite(fId, newline);
    fwrite(fId, '% Close the logfile');
    fwrite(fId, newline);
    fwrite(fId,'log,close');
    fwrite(fId, newline);
    fclose(fId);
    
    % Output to console
    fprintf('Created: %s_stim_seq.txt\n', Filename);
end

fprintf('==========================================================\n\n');
fprintf('All files successfully saved to:\n%s\n\n', fullfile(pwd, FolderName));

%% BNC SAFETY WARNING ========================================
if BNC_Trigger == 1
    fprintf('**************************************************\n');
    fprintf('BNC Trigger is ENABLED.\n');
    fprintf('Please ensure your connected stimulation device safely accepts:\n');
    fprintf('--> Voltage: %.1f Volts\n', bnc_voltage);
    fprintf('--> Duration: %d milliseconds\n', bnc_duration);
end