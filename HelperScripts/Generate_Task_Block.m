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
% 3. Exports 13 fully formatted text files ready for the device GUI.
%
% *** CRITICAL PREREQUISITE ***
% This script assumes you have ALREADY RUN the Staircase Titration script!
% The generated text files rely on the visual threshold variables ('a' 
% and 'b') that the staircase saved to the device's memory. DO NOT unplug 
% or restart the device between the staircase and this main experiment.
%
% HOW TO USE:
% 1. Click "Run" (or press F5) on this MATLAB script.
% 2. Enter the Lab, Subject, Sequence, and BNC info in the pop-up box.
% 3. Click OK. 13 new text files will appear in your current MATLAB folder.
% 4. In your TACSChallenge.jar program: click "Load Cmds" and select the file for the current block.
% 5. Click "Send Cmds" to begin. Repeat steps 4-5 for each block.
% =========================================================================

%% USER INPUT VIA DIALOG BOX ==========================
prompt = {'Lab Number:', ...
          'Subject Number:', ...
          'Sequence (S1, S2, or S3):', ...
          'Use BNC Trigger for Stimulator? (1 = Yes, 0 = No) (Will automatically be turned off for Sh blocks)'};
dlgtitle = 'Experiment Setup (Batch Generation)';
dims = [1 60]; 

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

%% BATCH GENERATION LOOP =====================================
fprintf('==========================================================\n');
fprintf('Generating 13 blocks for Subject %s (Lab %s) - Sequence %s\n', Subject, Lab, Sequence_Choice);
if BNC_Trigger == 1
    fprintf('BNC Trigger: ENABLED (Will dynamically turn off for Sh blocks)\n');
else
    fprintf('BNC Trigger: DISABLED\n');
end
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
    
    % Generate Filename
    Filename = sprintf('sub-L%s_S%s_B%s_%s', Lab, Subject, Block, Condition);
    
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
    
    % open text file to store experiment
    fId=fopen([Filename '_stim_seq.txt'],'w');
    
    % Write Header
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
    fwrite(fId, ['log,open,' Filename]);
    fwrite(fId, newline);
    
    % write trials
    for trl = 1:numTrials
        fwrite(fId, ['%Trial ' num2str(trl)]);
        fwrite(fId, newline);
        fwrite(fId,[LED0{1}, num2str(ISI(trl))]);
        fwrite(fId, newline);
        fwrite(fId,[LED{trialSeq(trl)} num2str(target_dur)]);
        fwrite(fId, newline);
    end
    
    % Write BNC trigger command if applicable
    if writeBNC
        fwrite(fId, newline);
        fwrite(fId, '% send BNC Trigger to start stimulation');
        fwrite(fId, newline);
        fwrite(fId, '*trig,5.0,100'); 
        fwrite(fId, newline);
        fwrite(fId, newline);
    end
    
    % Execute and close
    fwrite(fId,'start_stim');
    fwrite(fId, newline);
    fwrite(fId,'log,close');
    fwrite(fId, newline);
    fclose(fId);
    
    % Output to console
    fprintf('Created: %s_stim_seq.txt\n', Filename);
end

fprintf('==========================================================\n\n');