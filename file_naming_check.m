%% This script checks that your data follows the correct naming convention and that all files are present
%
% 1. Run this script BEFORE you upload your data on OSF to avoid uploading data that is incompatible with the tACS Challenge 
% 2. To run this script, copy the script into the folder that contains your
% lab's data; for instance you can create a folder '.../Upload2OSF/L18' and then copy the script into '/Upload2OSF/'
% 3. Run the script.
% 4. Check the output; if all is ok you should see a message 'All checks
% passed'; if there are errors you will see a message for each error with
% hints on how to fix the error; 
% For instance: Lab "L18" / sub-L18_S05: block file count 10 != 13; which
% means that the files from 3 blocks are missing;
% 5. Don't upload your data on OSF until you see the 'All checks passed' msg
% 6. Thank you for supporting the tACS Challenge
%
% This script has been written by Yifan Shen from the Glasgow team (yifan.shen@strath.ac.uk)
% with minor modifications by Simon Hanslmayr (simon.hanslmayr@glasgow.ac.uk)


%% Report structure
res1 = struct();
res1.non_Ln_names = {};
res1.nums_over_44 = {};
res1.message = '';

% Global report variable
res = struct();
res.all_ok = true;
res.message = '';

%% List top-level subdirectories
root = pwd;
items = dir(root);

% Keep only real directories, exclude '.' and '..'
isdir_mask = [items.isdir];
dir_items = items(isdir_mask);
names = {dir_items.name};
lab_folder_names = setdiff(names, {'.','..'});

%% Verify top-level names follow "sub-L<number>" and number <= 44
pattern = '^L(\d+)$';
non_Ln = {};
nums_over_44 = {};
for i = 1:numel(lab_folder_names)
    nm = lab_folder_names{i};
    tok = regexp(nm, pattern, 'tokens', 'once', 'ignorecase');
    if isempty(tok)
        non_Ln{end+1} = nm;
    else
        val = str2double(tok{1});
        if isnan(val) || val > 44
            nums_over_44{end+1} = nm;
        end
    end
end
res1.non_Ln_names = non_Ln;
res1.nums_over_44 = nums_over_44;

%% Compose result message for top-level check
if isempty(res1.non_Ln_names) && isempty(res1.nums_over_44)
    res.all_ok = true;
else
    res.all_ok = false;
    parts = {};

    % Folders not following L+number
    if ~isempty(res1.non_Ln_names)
        parts{end+1} = sprintf('Invalid folder names (%d): %s', ...
            numel(res1.non_Ln_names), strjoin(res1.non_Ln_names, ', '));
    end

    % Folders with number > 44
    if ~isempty(res1.nums_over_44)
        parts{end+1} = sprintf('Folder numbers > 44 (%d): %s', ...
            numel(res1.nums_over_44), strjoin(res1.nums_over_44, ', '));
    end

    % Combine into message
    res1.message = strjoin(parts, '; ');
end

if ~res.all_ok
    fprintf('%s\n', res1.message);
    else
    %fprintf('%s\n', 'Lab folder check passed');
end

%% Per-lab subject folder name checks
res2 = struct();  % array of structs per lab
res2(1).message = '';

if res.all_ok == 1
    agg_msgs = {};  % collect messages across labs

    % Subject folder pattern (case-sensitive)
    subj_pattern = '^sub-L(\d+)_S(\d{2})$';
    expected_n = 20;

    for i = 1:numel(lab_folder_names)
        lab_name = lab_folder_names{i};
        root_subj = fullfile(pwd, lab_name);

        % Select only directories
        items = dir(root_subj);
        isdir_mask = [items.isdir];
        dir_items = items(isdir_mask);
        names = {dir_items.name};

        % Exclude '.' and '..' and names made only of dots
        mask_keep = ~ismember(names, {'.','..'}) & cellfun(@(s) isempty(regexp(s,'^\.+$','once')), names);
        subj_folder_names = names(mask_keep);

        % Initialize per-lab report
        res2(i).labname = lab_name;
        res2(i).subj_folder_names = subj_folder_names;
        res2(i).actual_count = numel(subj_folder_names);
        res2(i).expected_count = expected_n;
        res2(i).count_ok = (res2(i).actual_count == res2(i).expected_count);
        res2(i).invalid_names = {};
        res2(i).passed_names = {};

        % Extract expected L number from lab name
        labTok = regexp(lab_name, 'L(\d+)', 'tokens', 'once');
        expected_Lnum = str2double(labTok{1});

        % Check each subject folder name
        for j = 1:numel(subj_folder_names)
            sname = subj_folder_names{j};
            tok = regexp(sname, subj_pattern, 'tokens', 'once');
            if isempty(tok)
                res2(i).invalid_names{end+1} = sname; %#ok<AGROW>
            else
                % Extract L and S from subject name
                Lnum = str2double(tok{1});
                Snum = str2double(tok{2});

                % Check L matches lab L
                if Lnum ~= expected_Lnum
                    res2(i).invalid_names{end+1} = sprintf('%s (L=%d but lab is L%d)', sname, Lnum, expected_Lnum); %#ok<AGROW>
                elseif isnan(Lnum) || Lnum < 1 || Lnum > 44
                    res2(i).invalid_names{end+1} = sprintf('%s (L=%s out of 1..44)', sname, tok{1}); %#ok<AGROW>
                else
                    res2(i).passed_names{end+1} = sname; %#ok<AGROW>
                end
            end
        end

        % Flag if any name problems
        res2(i).names_ok = isempty(res2(i).invalid_names);

        % Build per-lab message
        lab_msgs = {};
        if ~res2(i).count_ok
            lab_msgs{end+1} = sprintf('Lab "%s": subject folder count = %d (expected %d)', ...
                                      lab_name, res2(i).actual_count, res2(i).expected_count);
        end
        if ~res2(i).names_ok
            lab_msgs{end+1} = sprintf('Lab "%s": invalid subject folder names (%d): %s', ...
                                      lab_name, numel(res2(i).invalid_names), strjoin(res2(i).invalid_names, ', '));
        end

        if ~isempty(lab_msgs)
            agg_msgs{end+1} = strjoin(lab_msgs, '; ');
        end
    end

    % Combine and set overall flag
    if isempty(agg_msgs)
        res.all_ok = true;
    else
        % subjects_all_ok follows name-only criterion (ignore count)
        any_name_problem = false;
        for k = 1:numel(res2)
            if isfield(res2(k),'invalid_names') && ~isempty(res2(k).invalid_names)
                any_name_problem = true;
                break;
            end
        end

        res.all_ok = ~any_name_problem;
        res2(1).message = strjoin(agg_msgs, '\n');
        fprintf('%s\n', strrep(res2(1).message, '\n', sprintf('\n')));
    end
end

%% Check each subject folder contains exactly these three subfolders
expected_types = {'beh','eeg','metadata'};

% Initialize
res3 = struct();
res3.message = '';
agg_msgs = {};
if res.all_ok == true
    for i = 1:numel(lab_folder_names)
        lab_name = lab_folder_names{i};
        res3(i).labname = lab_name;
        % Ensure subj list exists
        if ~exist('res2','var') || numel(res2) < i || ~isfield(res2(i),'subj_folder_names')
            res3(i).message = sprintf('No subj_folder_names found for lab "%s".', lab_name);
            agg_msgs{end+1} = res3(i).message;
            res3(i).subjects = struct([]);
            res.all_ok = false;
            continue
        end

        subj_list = res2(i).subj_folder_names;
        res3(i).subj_folder_names = subj_list;
        res3(i).subjects = struct([]);

        for j = 1:numel(subj_list)
            sname = subj_list{j};
            subj_path = fullfile(pwd, lab_name, sname);

            % Prepare default subject report
            subj_report = struct('name', sname, 'path', subj_path, ...
                                 'data_types', {{}}, 'missing', {{}}, 'extra', {{}}, ...
                                 'ok', false, 'message', '');

            % If subject folder missing, record and continue
            if ~isfolder(subj_path)
                subj_report.message = sprintf('Subject folder not found: %s', subj_path);
                res3(i).subjects(j) = subj_report;
                agg_msgs{end+1} = sprintf('Lab "%s" / %s: %s', lab_name, sname, subj_report.message);
                res.all_ok = false;
                continue
            end

            % List immediate subdirectories
            items = dir(subj_path);
            isdir_mask = [items.isdir];
            dir_items = items(isdir_mask);
            names = {dir_items.name};
            % Exclude '.' '..' and names made only of dots
            keep_mask = ~ismember(names, {'.','..'}) & cellfun(@(s) isempty(regexp(s,'^\.+$','once')), names);
            data_type_folder_names = names(keep_mask);

            % Compute missing and unexpected
            missing = setdiff(expected_types, data_type_folder_names, 'stable');
            extra   = setdiff(data_type_folder_names, expected_types, 'stable');

            % Fill subject report
            subj_report.data_types = data_type_folder_names;
            subj_report.missing = missing;
            subj_report.extra = extra;
            subj_report.ok = isempty(missing) && isempty(extra);

            if subj_report.ok
                subj_report.message = 'OK';
            else
                parts = {};
                if ~isempty(missing)
                    parts{end+1} = ['missing: ' strjoin(missing, ', ')];
                end
                if ~isempty(extra)
                    parts{end+1} = ['unexpected: ' strjoin(extra, ', ')];
                end
                subj_report.message = strjoin(parts, '; ');
                agg_msgs{end+1} = sprintf('Lab "%s" / %s: %s', lab_name, sname, subj_report.message);
            end

        end
    end

    % Finalize res3.message
    if ~isempty(agg_msgs)
        res.all_ok = false;
        res3.message = strjoin(agg_msgs, '\n');
        fprintf('%s\n', strrep(res3.message , '\n', sprintf('\n')));
    end
end

%% Check beh folders in detail
% Requirements:
% - filenames must follow sub-L<digits>_S<2digits>_B<1..13>_<A|B|C|Sh>.tsv
% - there must be 13 block files (A/B/C/Sh combined) and 1 Staircase .tsv
% - types A, B, C must have 3 occurrences each; sequences must match S1/S2/S3
% - Staircase has no B number
% - Extra files are flagged

if res.all_ok == true
    expected_p1 = 13;    % expected number of block files per subject
    expected_p2 = 1;     % expected number of staircase files per subject
    expected_types = {'A','B','C','Sh'};

    % Sequences
    S1 = {'Sh','A','C','B','Sh','C','B','A','Sh','B','A','C','Sh'};
    S2 = {'Sh','B','A','C','Sh','A','C','B','Sh','C','B','A','Sh'};
    S3 = {'Sh','C','B','A','Sh','B','A','C','Sh','A','C','B','Sh'};

    % File patterns
    patt1 = '^sub-L(\d+)_S(\d{2})_B(\d+)_((?:A|B|C|Sh))(?:(?:_.*)?)\.tsv$';
    patt2 = '^sub-L(\d+)_S(\d{2})_Staircase(?:(?:_.*)?)\.tsv$';

    res_beh = struct();
    agg_msgs = {};
    res.all_ok = true;

    for i = 1:numel(lab_folder_names)
        lab_name = lab_folder_names{i};
        res_beh(i).labname = lab_name;

        % Ensure the sequence distribution is correct across subjects
        s1_count = 0;
        s2_count = 0;
        s3_count = 0;

        % Extract expected L number from lab name
        labTok = regexp(lab_name, 'L(\d+)', 'tokens', 'once');
        if isempty(labTok)
            expected_Lnum = NaN;
        else
            expected_Lnum = str2double(labTok{1});
        end

        % Get subject list
        subj_list = res2(i).subj_folder_names;
        res_beh(i).subj_folder_names = subj_list;
        res_beh(i).subjects = struct([]);


        for j = 1:numel(subj_list)
            sname = subj_list{j};
            parts = {};
            subj_path = fullfile(pwd, lab_name, sname);

            subj_beh_report = struct('name', sname, 'path', subj_path, ...
                'p1_files', {{}}, 'p2_files', {{}}, 'unmatched_files', {{}}, ...
                'prefixes', {{}}, 'p1_count', 0, 'p2_count', 0, ...
                'B_nums', [], 'B_missing', [], 'B_dup', [], ...
                'type_counts', struct(), 'type_order_by_B', {{}}, ...
                'sequence_match', '', 'ok', true, 'message', '');

            % Extract L and S from subject folder name
            subjTok = regexp(sname, '^sub-L(\d+)_S(\d{2})$', 'tokens', 'once');
            if isempty(subjTok)
                subj_Lnum = NaN;
                subj_Snum = NaN;
            else
                subj_Lnum = str2double(subjTok{1});
                subj_Snum = str2double(subjTok{2});
            end

            %% beh files
            beh_path = fullfile(subj_path, 'beh');
            files = dir(fullfile(beh_path, '*.tsv'));
            fnames = {files.name};

            prefixes = {}; p1_files = {}; p2_files = {}; unmatched = {};
            Bnums = []; types = {};
            for k = 1:numel(fnames)
                fname = fnames{k};
                t1 = regexp(fname, patt1, 'tokens', 'once');
                t2 = regexp(fname, patt2, 'tokens', 'once');
                if ~isempty(t1)
                    p1_files{end+1} = fname; %#ok<AGROW>
                    prefixes{end+1} = sprintf('sub-L%s_S%s_B%s_%s', t1{1}, t1{2}, t1{3}, t1{4}); %#ok<AGROW>
                    Bnums(end+1) = str2double(t1{3}); %#ok<AGROW>
                    types{end+1} = t1{4}; %#ok<AGROW>
                elseif ~isempty(t2)
                    p2_files{end+1} = fname; %#ok<AGROW>
                    prefixes{end+1} = sprintf('sub-L%s_S%s_Staircase', t2{1}, t2{2}); %#ok<AGROW>
                else
                    unmatched{end+1} = fname; %#ok<AGROW>
                end
            end

            subj_beh_report.p1_files = p1_files;
            subj_beh_report.p2_files = p2_files;
            subj_beh_report.unmatched_files = unmatched;
            subj_beh_report.prefixes = prefixes;
            subj_beh_report.p1_count = numel(p1_files);
            subj_beh_report.p2_count = numel(p2_files);
            subj_beh_report.B_nums = Bnums;

            % Duplicate prefix check
            if ~isempty(prefixes)
                [u, ~, ic] = unique(prefixes);
                counts = histcounts(ic, 1:(numel(u)+1));
                dup_prefixes = u(counts>1);
            else
                dup_prefixes = {};
            end
            subj_beh_report.duplicate_prefixes = dup_prefixes;
            if ~isempty(dup_prefixes)
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message, sprintf(' Duplicate prefixes: %s.', strjoin(dup_prefixes, ', '))];
            end

            % Count checks
            if subj_beh_report.p1_count ~= expected_p1
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message, sprintf(' block count mismatch (found %d, expected %d).', subj_beh_report.p1_count, expected_p1)];
            end
            if subj_beh_report.p2_count ~= expected_p2
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message, sprintf(' staircase count mismatch (found %d, expected %d).', subj_beh_report.p2_count, expected_p2)];
            end

            % L and S consistency from parsed filenames
            all_parsed_L = [];
            all_parsed_S = [];
            for k = 1:numel(p1_files)
                t = regexp(p1_files{k}, patt1, 'tokens', 'once');
                all_parsed_L(end+1) = str2double(t{1}); %#ok<AGROW>
                all_parsed_S(end+1) = str2double(t{2}); %#ok<AGROW>
            end
            for k = 1:numel(p2_files)
                t = regexp(p2_files{k}, patt2, 'tokens', 'once');
                all_parsed_L(end+1) = str2double(t{1}); %#ok<AGROW>
                all_parsed_S(end+1) = str2double(t{2}); %#ok<AGROW>
            end
            if ~isempty(all_parsed_L)
                if ~isnan(expected_Lnum) && any(all_parsed_L ~= expected_Lnum)
                    subj_beh_report.ok = false;
                    subj_beh_report.message = [subj_beh_report.message, sprintf(' L-number mismatch between filenames and lab (found L=%s, lab L=%d).', mat2str(unique(all_parsed_L)), expected_Lnum)];
                end
            end
            if ~isempty(all_parsed_S)
                if ~isnan(subj_Snum) && any(all_parsed_S ~= subj_Snum)
                    subj_beh_report.ok = false;
                    subj_beh_report.message = [subj_beh_report.message, sprintf(' S-number mismatch between filenames and subject folder (found S=%s, subj S=%d).', mat2str(unique(all_parsed_S)), subj_Snum)];
                end
            end

            % Build type order by B
            subj_beh_report.type_order_by_B = {};
            if ~isempty(p1_files)
                tmp_types = cell(1,numel(p1_files));
                tmp_B = zeros(1,numel(p1_files));
                for k = 1:numel(p1_files)
                    t = regexp(p1_files{k}, patt1, 'tokens', 'once');
                    tmp_B(k) = str2double(t{3});
                    tmp_types{k} = t{4};
                end
                [B_sorted_vals, idx_sort] = sort(tmp_B);
                subj_beh_report.type_order_by_B = tmp_types(idx_sort);
                subj_beh_report.B_nums_sorted = B_sorted_vals;
            end

            % Sequence match check
            seq = subj_beh_report.type_order_by_B;
            if isequal(seq, S1)
                subj_beh_report.sequence_match = 'S1';
                s1_count = s1_count + 1;
            elseif isequal(seq, S2)
                subj_beh_report.sequence_match = 'S2';
                s2_count = s2_count + 1;
            elseif isequal(seq, S3)
                subj_beh_report.sequence_match = 'S3';
                s3_count = s3_count + 1;
            else
                subj_beh_report.sequence_match = 'NONE';
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message ' Sequence does not match any of S1/S2/S3.'];
            end

            % Finalize subject message if empty
            if isempty(subj_beh_report.message)
                subj_beh_report.message = 'OK';
            end

            % Aggregate readable messages for summary (only include key problems)
            if ~subj_beh_report.ok
                if isfield(subj_beh_report,'duplicate_prefixes') && ~isempty(subj_beh_report.duplicate_prefixes)
                    parts{end+1} = sprintf('duplicate prefixes: %s', strjoin(subj_beh_report.duplicate_prefixes, ', '));
                end
                if isfield(subj_beh_report,'p1_count') && subj_beh_report.p1_count ~= expected_p1
                    parts{end+1} = sprintf('block file count %d != %d', subj_beh_report.p1_count, expected_p1);
                end
                if isfield(subj_beh_report,'p2_count') && subj_beh_report.p2_count ~= expected_p2
                    parts{end+1} = sprintf('staircase file count %d != %d', subj_beh_report.p2_count, expected_p2);
                end
                if isfield(subj_beh_report,'unmatched_files') && ~isempty(subj_beh_report.unmatched_files)
                    parts{end+1} = sprintf('unmatched files: %s', strjoin(subj_beh_report.unmatched_files, ', '));
                end
                if strcmp(subj_beh_report.sequence_match, 'NONE')
                    parts{end+1} = 'Sequence does not match any of S1/S2/S3.';
                end
            end

            %% EEG checks
            combos = {'Post_EC','Post_EO','Pre_EC','Pre_EO'};
            patt_eeg = '^sub-L(\d+)_S(\d{2})_(Pre|Post)_(EC|EO)(?:_.*)?\.(.+)$';

            eeg_path = fullfile(subj_path, 'eeg');
            subj_beh_report.eeg = struct();
            subj_beh_report.eeg.missing = {};
            subj_beh_report.eeg.unexpected = {};
            subj_beh_report.eeg.detail = struct();
            subj_beh_report.eeg.name_mismatch = {};

            eeg_files = {};
            if isfolder(eeg_path)
                f = dir(eeg_path);
                nm = {f.name};
                nm = nm(~ismember(nm,{'.','..'}));
                eeg_files = nm;
            else
                subj_beh_report.eeg.missing = {'eeg folder missing'};
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message, ' Missing eeg folder.'];
            end

            for c = 1:numel(combos)
                subj_beh_report.eeg.detail.(combos{c}) = struct('json', {{}} , 'channels', {{}} , 'data', {{}} , 'ok', true);
            end

            for k = 1:numel(eeg_files)
                fname = eeg_files{k};
                t = regexp(fname, patt_eeg, 'tokens', 'once');
                if isempty(t)
                    subj_beh_report.eeg.unexpected{end+1} = fname; %#ok<AGROW>
                else
                    Lf = str2double(t{1}); Sf = str2double(t{2});
                    when = t{3}; env = t{4};
                    ext = t{5};
                    combo = sprintf('%s_%s', when, env);
                    if ~isnan(subj_Lnum) && Lf ~= subj_Lnum
                        subj_beh_report.eeg.name_mismatch{end+1} = sprintf('%s (L=%d)', fname, Lf); %#ok<AGROW>
                    end
                    if ~isnan(subj_Snum) && Sf ~= subj_Snum
                        subj_beh_report.eeg.name_mismatch{end+1} = sprintf('%s (S=%d)', fname, Sf); %#ok<AGROW>
                    end
                    rec = subj_beh_report.eeg.detail.(combo);
                    if strcmpi(ext, 'json')
                        if isempty(rec) || ~isfield(rec,'json'), rec.json = {}; end
                        rec.json{end+1} = fname; %#ok<AGROW>
                    elseif endsWith(fname, '_channels.tsv')
                        if isempty(rec) || ~isfield(rec,'channels'), rec.channels = {}; end
                        rec.channels{end+1} = fname; %#ok<AGROW>
                    else
                        if isempty(rec) || ~isfield(rec,'data')
                            rec.data = {};
                        end
                        rec.data{end+1} = fname; %#ok<AGROW>
                    end
                    subj_beh_report.eeg.detail.(combo) = rec;
                end
            end

            % Evaluate per-combo presence
            for c = 1:numel(combos)
                combo = combos{c};
                rec = subj_beh_report.eeg.detail.(combo);
                missing_parts = {};
                if ~isfield(rec,'json') || isempty(rec.json)
                    missing_parts{end+1} = 'json';
                end
                if ~isfield(rec,'channels') || isempty(rec.channels)
                    missing_parts{end+1} = 'channels.tsv';
                end
                if ~isfield(rec,'data') || isempty(rec.data)
                    missing_parts{end+1} = 'data file';
                end
                if ~isempty(missing_parts)
                    subj_beh_report.eeg.detail.(combo).ok = false;
                    subj_beh_report.eeg.detail.(combo).missing = missing_parts;
                    subj_beh_report.eeg.missing{end+1} = sprintf('%s: missing %s', combo, strjoin(missing_parts, ', ')); %#ok<AGROW>
                    subj_beh_report.ok = false;
                else
                    subj_beh_report.eeg.detail.(combo).ok = true;
                end
            end

            if ~isempty(subj_beh_report.eeg.name_mismatch)
                subj_beh_report.ok = false;
                subj_beh_report.eeg.name_mismatch = unique(subj_beh_report.eeg.name_mismatch);
            end
            if ~isempty(subj_beh_report.eeg.unexpected)
                subj_beh_report.ok = false;
            end

            % Add EEG summary to subject message (avoid excessive duplication)
            parts_eeg = {};
            if ~isempty(subj_beh_report.eeg.missing)
                parts_eeg{end+1} = sprintf('EEG missing: %s', strjoin(subj_beh_report.eeg.missing, '; '));
            end
            if ~isempty(subj_beh_report.eeg.unexpected)
                parts_eeg{end+1} = sprintf('EEG unexpected files: %s', strjoin(unique(subj_beh_report.eeg.unexpected), ', '));
            end
            if ~isempty(subj_beh_report.eeg.name_mismatch)
                parts_eeg{end+1} = sprintf('EEG name mismatches: %s', strjoin(subj_beh_report.eeg.name_mismatch, ', '));
            end
            if ~isempty(parts_eeg)
                subj_beh_report.message = strtrim(sprintf('%s %s', subj_beh_report.message, strjoin(parts_eeg, '; ')));
            end

            if isfield(subj_beh_report,'eeg')
                if isfield(subj_beh_report.eeg,'missing') && ~isempty(subj_beh_report.eeg.missing)
                    parts{end+1} = sprintf('EEG missing: %s', strjoin(subj_beh_report.eeg.missing, '; '));
                end
                if isfield(subj_beh_report.eeg,'unexpected') && ~isempty(subj_beh_report.eeg.unexpected)
                    parts{end+1} = sprintf('EEG unexpected files: %s', strjoin(unique(subj_beh_report.eeg.unexpected), ', '));
                end
                if isfield(subj_beh_report.eeg,'name_mismatch') && ~isempty(subj_beh_report.eeg.name_mismatch)
                    parts{end+1} = sprintf('EEG name mismatches: %s', strjoin(unique(subj_beh_report.eeg.name_mismatch), ', '));
                end
                if isfield(subj_beh_report.eeg,'detail')
                    combos = fieldnames(subj_beh_report.eeg.detail);
                    for cc = 1:numel(combos)
                        d = subj_beh_report.eeg.detail.(combos{cc});
                        if isfield(d,'missing') && ~isempty(d.missing)
                            parts{end+1} = sprintf('EEG %s missing: %s', combos{cc}, strjoin(d.missing, ', '));
                        end
                    end
                end
            end

            %% metadata checks
            meta_path = fullfile(subj_path, 'metadata');
            subj_beh_report.metadata = struct('found', {{}}, 'missing', false, 'extra', {{}}, 'name_mismatch', {{}}); 
            meta_pattern = '^sub-L(\d+)_S(\d{2})_Meta_Data(?:_.*)?\.tsv$';

            meta_files = {};
            if isfolder(meta_path)
                mf = dir(fullfile(meta_path,'*.tsv'));
                meta_files = {mf.name};
            else
                subj_beh_report.metadata.missing = true;
                subj_beh_report.ok = false;
                subj_beh_report.message = [subj_beh_report.message ' Missing metadata folder.'];
            end

            matched_meta = {};
            unmatched_meta = {};
            for m = 1:numel(meta_files)
                name = meta_files{m};
                t = regexp(name, meta_pattern, 'tokens', 'once');
                if isempty(t)
                    unmatched_meta{end+1} = name; %#ok<AGROW>
                else
                    matched_meta{end+1} = name; %#ok<AGROW>
                    Lm = str2double(t{1}); Sm = str2double(t{2});
                    if ~isnan(subj_Lnum) && Lm ~= subj_Lnum
                        subj_beh_report.metadata.name_mismatch{end+1} = sprintf('%s (L=%d)', name, Lm); %#ok<AGROW>
                        subj_beh_report.ok = false;
                    end
                    if ~isnan(subj_Snum) && Sm ~= subj_Snum
                        subj_beh_report.metadata.name_mismatch{end+1} = sprintf('%s (S=%d)', name, Sm); %#ok<AGROW>
                        subj_beh_report.ok = false;
                    end
                end
            end

            subj_beh_report.metadata.found = matched_meta;
            if isempty(matched_meta)
                subj_beh_report.metadata.missing = true;
                subj_beh_report.ok = false;
            end
            if ~isempty(unmatched_meta)
                subj_beh_report.metadata.extra = unmatched_meta;
                subj_beh_report.ok = false;
            end

            parts_meta = {};
            if subj_beh_report.metadata.missing
                parts_meta{end+1} = 'metadata file missing';
            end
            if ~isempty(subj_beh_report.metadata.extra)
                parts_meta{end+1} = sprintf('metadata unexpected: %s', strjoin(subj_beh_report.metadata.extra, ', '));
            end
            if ~isempty(subj_beh_report.metadata.name_mismatch)
                parts_meta{end+1} = sprintf('metadata name mismatches: %s', strjoin(unique(subj_beh_report.metadata.name_mismatch), ', '));
            end
            if ~isempty(parts_meta)
                subj_beh_report.message = strtrim(sprintf('%s %s', subj_beh_report.message, strjoin(parts_meta, '; ')));
            end

            if isfield(subj_beh_report,'metadata')
                if isfield(subj_beh_report.metadata,'missing') && subj_beh_report.metadata.missing
                    parts{end+1} = 'metadata file missing';
                end
                if isfield(subj_beh_report.metadata,'extra') && ~isempty(subj_beh_report.metadata.extra)
                    parts{end+1} = sprintf('metadata unexpected: %s', strjoin(subj_beh_report.metadata.extra, ', '));
                end
                if isfield(subj_beh_report.metadata,'name_mismatch') && ~isempty(subj_beh_report.metadata.name_mismatch)
                    parts{end+1} = sprintf('metadata name mismatches: %s', strjoin(unique(subj_beh_report.metadata.name_mismatch), ', '));
                end
            end

            % If any problems for this subject, add one aggregated message line
            if ~isempty(parts)
                subj_msg = sprintf('Lab "%s" / %s: %s', lab_name, sname, strjoin(parts, '; '));
                agg_msgs{end+1} = subj_msg;
                subj_beh_report.ok = false;
            else
                subj_msg = sprintf('Lab "%s" / %s: OK', lab_name, sname);
            end

        end % end subj loop

        % Per-lab sequence distribution check

        % !!! This variable records how many s1, s2 and s3 sequences we have in each lab
        res_beh(i).sequence_counts = struct('S1',s1_count,'S2',s2_count,'S3',s3_count);
        counts_sorted = sort([s1_count,s2_count,s3_count]);
        if ~isequal(counts_sorted, [6,7,7])
            agg_msgs{end+1} = sprintf('Lab "%s": sequence distribution not matching required [7,7,6]. Found [S1=%d, S2=%d, S3=%d].', ...
                res_beh(i).labname, s1_count, s2_count, s3_count);
            res_beh(i).sequence_distribution_ok = false;
            res_beh(i).sequence_counts_detail = [s1_count,s2_count,s3_count];
            res.all_ok = false;
        else
            res_beh(i).sequence_distribution_ok = true;
        end

    end % end lab loop

    % Finalize messages
    if ~res.all_ok
        res_file.message = strjoin(agg_msgs, '\n');
        fprintf('%s\n', strrep(res_file.message, '\n', sprintf('\n')));
    else
        fprintf('All  checks passed.\n');
    end

end