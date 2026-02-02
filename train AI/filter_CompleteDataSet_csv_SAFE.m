clc; clear;

%% ================= PATH =================
INPUT_FILE  = 'F:\Train AI\data\CompleteDataSet.csv';
OUTPUT_FILE = 'F:\Train AI\csv_output\complete_wrist_ai.csv';

%% ================= READ CSV =================
T = readtable(INPUT_FILE);

fprintf('So cot trong file: %d\n', width(T));

%% ================= MAP THEO MÔ TẢ DATASET =================
% Column 1  : Timestamp
% Column 24-26 : Wrist Accelerometer X Y Z
% Column 27-29 : Wrist Gyroscope X Y Z
% Cuoi file : Subject, Activity, Trial, Tag

timestamp = T{:,1};

ax = T{:,24};
ay = T{:,25};
az = T{:,26};

gx = T{:,27};
gy = T{:,28};
gz = T{:,29};

subject  = string(T{:, end-3});
activity = string(T{:, end-2});
tag      = T{:, end};

%% ================= LABEL =================
label = double(tag == 7);   % tag = 7 → fall

%% ================= OUTPUT TABLE =================
T_out = table( ...
    timestamp, ax, ay, az, gx, gy, gz, ...
    label, activity, subject, ...
    'VariableNames', { ...
        'timestamp','ax','ay','az','gx','gy','gz', ...
        'label','activity','subject' ...
    });

%% ================= CLEAN =================
T_out = rmmissing(T_out);

%% ================= KIỂM TRA NHANH =================
disp('5 dong dau (timestamp, ax, ay, az):');
disp(T_out(1:5,1:4));

disp('Thong ke label:');
disp(groupcounts(T_out.label));

disp('So subject:');
disp(numel(unique(T_out.subject)));

%% ================= WRITE CSV =================
writetable(T_out, OUTPUT_FILE);

fprintf('✅ DA XUAT CSV WRIST THANH CONG:\n%s\n', OUTPUT_FILE);
