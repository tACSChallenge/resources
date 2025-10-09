%% Matlab script to BIDSify our data
%
% use this script to organize your data so that it matches naming
% conventions as specified by the tACS Challenge
% use file_naming_check.m to check you have done it correctly
%
% This script has been written by Yifan Shen from the Glasgow team (yifan.shen@strath.ac.uk)
% with minor modifications by Simon Hanslmayr (simon.hanslmayr@glasgow.ac.uk)


function BIDSify(input_path, bids_path, labnum)

% input:
% input_path= path with data; data should be organised such that each
% subject has its own folder and all data is stored in that subject's
% folder
%
% bids_path = path where data will copied to in BIDS format
% labnum = lab number, i.e. 18 for Hanslmayr lab

% Determine OS for folder symbol
if ispc
    fldrsym='\';
elseif isunix
    fldrsym='/';
elseif ismac
    fldrsym='/';
end     


prefix=strcat('L', num2str(labnum), '_');
subdirs=dir(strcat(input_path, fldrsym, prefix, '*'));

% prepare the EEG file types for later use
EEG_file = {'*.vhdr','*.eeg','*.vmrk'};

for n=1:length(subdirs)
    tmpdir=strcat(subdirs(n,1).folder, fldrsym, subdirs(n,1).name);
    cd(tmpdir);
    % make subject directory
    sub_dir=strcat(bids_path, fldrsym, 'sub-', prefix, 'S', tmpdir(end-1:end));
    if ~exist(sub_dir, 'dir')
    mkdir(sub_dir);
    end
    % make beh, eeg, and metadata directories
     beh_path = fullfile(sub_dir,'beh');
    if ~exist(beh_path, 'dir')
     mkdir(beh_path);
    end

     eeg_path = fullfile(sub_dir,'eeg');
     if ~exist(eeg_path, 'dir')
     mkdir(eeg_path);
     end

     metadata_path = fullfile(sub_dir,'metadata');
    if ~exist(metadata_path, 'dir')
     mkdir(metadata_path);
    end
    
    % identify all beh files 
    filt_beh=strcat(prefix, '*_B*.tsv');
    beh_fls=dir(filt_beh);
    if numel(beh_fls)== 13 
        for b=1:13
            srcfile=beh_fls(b,1).name;
            destfile=strcat('sub-', srcfile);
            copyfile(srcfile,fullfile(beh_path,destfile));

        end
    else
        disp('Number of beh files does not match expected number. Check data for consistency.');
    end

    % add the staircase files into the beh folder
      filt_staircase=strcat(prefix, '*_Staircase*.tsv');
      staircase_fls=dir(filt_staircase);

          if numel(staircase_fls)== 1
             srcfile=staircase_fls(1).name;
             destfile=strcat('sub-', srcfile);
             copyfile(srcfile,fullfile(beh_path,destfile));
          else
            disp('More than one staircase files. Check data for consistency.');
          end


   % identify all eeg files
    for e=1:3
          filt_eeg=strcat(prefix, EEG_file{e});
          eeg_fls=dir(filt_eeg);
         
          if numel(eeg_fls)== 4
             for ee=1:4
             srcfile=eeg_fls(ee).name;
             destfile=strcat('sub-', srcfile);
             copyfile(srcfile,fullfile(eeg_path,destfile));
 

         %% an important step, we need to add sub- on the vhdr headers, so it can point to the corret .eeg and .vmrk file
         %% mostly written by chatgpt but it works
          if e==1  %i.e., the vhdr files
           vhdr_file = fullfile(eeg_path,destfile);
           fid = fopen(vhdr_file,'r','n','UTF-8');
           lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', ''); % read the original one
           fclose(fid);
           lines = lines{1}; 

            for i = 1:length(lines)                                         
              if startsWith(strtrim(lines{i}), 'DataFile', 'IgnoreCase', true) % change the line pointing to eeg
                parts = regexp(lines{i}, '=', 'split', 'once');    
                fname = strtrim(parts{2});
                [~, name_vhdr, ext] = fileparts(fname);
                new_name = ['sub-', name_vhdr, ext];
                lines{i} = [parts{1}, '=', new_name];
              elseif startsWith(strtrim(lines{i}), 'MarkerFile', 'IgnoreCase', true) % change the line pointing to vmrk
               parts = regexp(lines{i}, '=', 'split', 'once');
               fname = strtrim(parts{2});
               [~, name_vhdr, ext] = fileparts(fname);
               new_name = ['sub-', name_vhdr, ext];
               lines{i} = [parts{1}, '=', new_name];
              end
            end
      
            fid = fopen(vhdr_file,'w','n','UTF-8');   % write the modified lines back
            if fid == -1
               error('Cannot write to %s', vhdr_file);
            end
            for i = 1:length(lines)
              fprintf(fid, '%s\n', lines{i});
            end
            fclose(fid);
           end

            end
          else
             disp('Number of eeg files does not match expected number. Check data for consistency.');
          end


%% Write back to the same file (overwrite)
fid = fopen(vhdr_file,'w','n','UTF-8');
if fid == -1
    error('Cannot write to %s', vhdr_file);
end
for i = 1:length(lines)
    fprintf(fid, '%s\n', lines{i});
end
fclose(fid);

    end

     % identify the metadata.tsv file
    
    filt_meta = '*Meta*.tsv';
    meta_fls = dir(filt_meta);

    if numel(meta_fls)== 1
     srcfile=meta_fls(1).name;
     destfile=strcat('sub-', srcfile);
     copyfile(srcfile,fullfile(metadata_path,destfile));
    else
     disp('More than one metadata files. Check data for consistency.');
    end

end