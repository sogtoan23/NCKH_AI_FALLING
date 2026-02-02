clc;
clear;

%% ================== CẤU HÌNH ==================
ROOT_DIR = 'F:\Train AI\data';
OUTPUT_DIR = 'F:\Train AI\csv_output';

FS = 100;  % sampling rate (Hz)

if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

%% ================== LẤY DANH SÁCH SUBJECT ==================
subjects = dir(fullfile(ROOT_DIR, 'subject_*'));
subjects = subjects([subjects.isdir]);

fprintf('Found %d subjects\n', length(subjects));

%% ================== DUYỆT TỪNG SUBJECT ==================
for s = 1:length(subjects)

    subject_name = subjects(s).name;
    subject_path = fullfile(ROOT_DIR, subject_name);

    fprintf('\nProcessing %s\n', subject_name);

    %% ---------- FALL ----------
    process_folder(subject_path, 'fall', 1, subject_name, OUTPUT_DIR);

    %% ---------- NON-FALL ----------
    process_folder(subject_path, 'non-fall', 0, subject_name, OUTPUT_DIR);
end

disp('✅ DONE exporting all CSV files');

%% ==========================================================
function process_folder(subject_path, folder_name, label, subject_name, OUTPUT_DIR)

    data_path = fullfile(subject_path, folder_name);
    if ~exist(data_path, 'dir')
        return;
    end

    files = dir(fullfile(data_path, '*.mat'));

    for f = 1:length(files)

        file_path = fullfile(data_path, files(f).name);
        activity = erase(files(f).name, '.mat');

        fprintf('  %s | %s\n', folder_name, files(f).name);

        try
            export_one_file(file_path, label, activity, subject_name, OUTPUT_DIR);
        catch
            warning('  ⚠️ Failed: %s', file_path);
        end
    end
end

%% ==========================================================
function export_one_file(mat_file, label, activity, subject_name, OUTPUT_DIR)

    data = load(mat_file);

    % --------- KIỂM TRA BIẾN ----------
    if ~isfield(data, 'ax') || ~isfield(data, 'ay') || ~isfield(data, 'az')
        warning('Missing accelerometer');
        return;
    end

    % --------- ACC ----------
    ax = data.ax(:);
    ay = data.ay(:);
    az = data.az(:);

    % --------- GYRO ----------
    if isfield(data, 'x') && isfield(data, 'y') && isfield(data, 'z')
        gx = data.x(:);
        gy = data.y(:);
        gz = data.z(:);
    elseif isfield(data, 'gx')
        gx = data.gx(:);
        gy = data.gy(:);
        gz = data.gz(:);
    else
        warning('Missing gyroscope');
        return;
    end

    % --------- TIMESTAMP ----------
    N = length(ax);
    timestamp = (0:N-1)' / 100;  % 100 Hz → giây

    % --------- LABEL ----------
    label_col    = label * ones(N,1);
    activity_col = repmat({activity}, N, 1);
    subject_col  = repmat({subject_name}, N, 1);

    % --------- TẠO TABLE ----------
    T = table( ...
        timestamp, ax, ay, az, gx, gy, gz, ...
        label_col, activity_col, subject_col, ...
        'VariableNames', { ...
            'timestamp','ax','ay','az','gx','gy','gz', ...
            'label','activity','subject' ...
        });

    % --------- LƯU CSV ----------
    out_name = sprintf('%s_%s.csv', subject_name, activity);
    out_path = fullfile(OUTPUT_DIR, out_name);

    writetable(T, out_path);
end
