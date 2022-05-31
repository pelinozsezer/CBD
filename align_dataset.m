function [signals, sleep_states, signals_indexes, bins_num] = align_dataset(signals_dirpath, states_dirpath)
% Align Dataset to get aligned data matrix and bin indexes
%   Detailed explanation goes here

%signals_dirpath = "D:\Dev\MATLAB\GenzelLab\data\hpcbel";
%states_dirpath = "D:\Dev\MATLAB\GenzelLab\data\sleepstates";

fn = 600;
ALIGNtot = [26 19 26 10 277 206 247 54 10 11 10 3 16 9 6 6 5 1 0];     
remove_at_start = 15 * 60 * fn;
bin_size = 45*60*fn;

% We get all signal file names and order them (files should be named by a
% number (Rat ID), this allows to be sure of which row represent wich rat
signals_dirpath_contents = dir(signals_dirpath);
are_files = ~cell2mat({signals_dirpath_contents.isdir});
signals_files = {signals_dirpath_contents(are_files).name};
ordered_files = zeros(1,length(signals_files));
for i = 1:length(signals_files)
    file_i = signals_files{i};
    [~, name, ~] = fileparts(file_i);
    ordered_files(i) = str2double(name);
end
ordered_files = sort(ordered_files);
rats_num = length(ordered_files);

% Now array with indices of start and end for every signal is initialized
signals_indexes = zeros(rats_num, 2);

% We will align all signals and sleep states in cell arrays. Here 15
% minutes of data are cutted out, signals are trimed to the length of the
% sleep states and both states and signals are aligned with respect to ALIGNtot
sigs = cell(1, length(rats_num));
states = cell(1, length(rats_num));
for i = 1:rats_num
    name = [num2str(ordered_files(i)) '.mat'];
    % We form Sleep State complete vector from 10 second segments
    states_path = fullfile(states_dirpath, name);
    state_segments = importdata(states_path);
    sleep_scoring = zeros(1, length(state_segments)*fn*10);
    for j = 1:length(state_segments)
        state = repmat(state_segments(j),1,fn*10);
        pos = fn*10*j-5999;
        sleep_scoring(pos:pos+5999) = state;
    end
    % We load signal
    signal_path = fullfile(signals_dirpath, name);
    sig = importdata(signal_path);
    % First 15 minutes of data get cutted out
    sleep_scoring = sleep_scoring(remove_at_start:end);
    sig = sig(remove_at_start:end);
    % Signal is trimmed to the length of built sleep states vector
    L = length(sleep_scoring);
    sig = sig(1:L);
    % Both signal and states are aligned
    align_size = ALIGNtot(i) * 60 * fn;
    alignment = NaN(align_size, 1);
    aligned_states = [alignment; sleep_scoring'];
    aligned_sig = [alignment; sig];
    % Processed signal and states are saved in cell array
    states{i} = aligned_states;
    sigs{i} = aligned_sig;
    % Indexes of the signal in aligned matrix are first saved here
    signals_indexes(i,1) = align_size + 1;
    signals_indexes(i,2) = length(aligned_sig);
end

% Now we build the aligned matrix from the cell arrays just with a NaN
% matrix using the signal with maximum length as reference
max_len = max(cellfun(@length, sigs));
signals = NaN(rats_num, max_len);
sleep_states = NaN(rats_num, max_len);
for i = 1:rats_num
    signals(i, 1:length(sigs{i})) = sigs{i};
    sleep_states(i, 1:length(states{i})) = states{i};
end 

% Now the total number of bins (with the bin_size defined duration) is
% calculated and matrices are trimmed to the number of samples needed for
% those bins
bins_num = floor(length(signals)/bin_size);
signals = signals(:, 1:bins_num*bin_size);
sleep_states = sleep_states(:, 1:bins_num*bin_size);
% As we just trimmed the matrix, we make sure that any signal top index
% that was trimmed is updated
for i = 1:rats_num
    if signals_indexes(i,2) >= bins_num*bin_size
        signals_indexes(i,2) = bins_num*bin_size;
    end
end

end

