%% FFT Analysis: Auto-Detect Variable Version
clear; clc; close all;

%% ======= 1. CONFIG: ตั้งค่า =======
filename    = 'VEC.mat'; % ตรวจสอบชื่อไฟล์ให้ตรง
t_start     = 0;
t_end       = inf;
f_max_plot  = 200;
use_filter  = false;
fc_lp       = 50;

%% ======= 2. LOAD & AUTO-DETECT: โหลดและค้นหาข้อมูลอัตโนมัติ =======
if ~isfile(filename)
    error('หาไฟล์ %s ไม่เจอ! กรุณาเช็คชื่อไฟล์หรือ Folder', filename);
end
fprintf('กำลังโหลดไฟล์: %s ...\n', filename);
FileData = load(filename);

% ตัวแปรสำหรับเก็บผลลัพธ์
ts_obj = [];
var_found_name = '';

% รายชื่อตัวแปรทั้งหมดในไฟล์
all_vars = fieldnames(FileData);

% --- ขั้นตอนการค้นหา (Logic) ---
% 1. ลองหาตัวแปรที่มีคำว่า "Velocity" หรือ "Speed" ก่อน
for i = 1:length(all_vars)
    name = all_vars{i};
    val = FileData.(name);
    
    % ถ้าเจอชื่อที่น่าใช่ และเป็น Object ข้อมูล
    if contains(name, {'Velocity', 'Speed', 'Raw'}, 'IgnoreCase', true) && ...
       (isa(val, 'timeseries') || isa(val, 'Simulink.SimulationData.Dataset') || isstruct(val))
        ts_obj = val;
        var_found_name = name;
        break;
    end
end

% 2. ถ้ายังไม่เจอ ให้ลองเจาะเข้าไปดูใน struct ชื่อ 'S' หรือ 'data' (ถ้ามี)
if isempty(ts_obj)
    special_structs = {'S', 'data', 'out'};
    for i = 1:length(special_structs)
        s_name = special_structs{i};
        if isfield(FileData, s_name) && isstruct(FileData.(s_name))
            % เจาะเข้าไปดูข้างใน
            inner_struct = FileData.(s_name);
            inner_fields = fieldnames(inner_struct);
            % เอาตัวแปรแรกใน struct นั้นมาเลย
            if ~isempty(inner_fields)
                ts_obj = inner_struct.(inner_fields{1});
                var_found_name = sprintf('%s.%s', s_name, inner_fields{1});
                break;
            end
        end
    end
end

% 3. ถ้ายังไม่เจออีก เอาตัวแปรแรกที่ไม่ใช่ Config มาเลย (ไม้ตาย)
if isempty(ts_obj)
    ignore_list = {'filename','t_start','t_end','f_max_plot','fc_lp','use_filter','target_var_name','vars','S'};
    candidates = setdiff(all_vars, ignore_list);
    if ~isempty(candidates)
        ts_obj = FileData.(candidates{1});
        var_found_name = candidates{1};
    end
end

if isempty(ts_obj)
    error('ไม่พบข้อมูลที่นำมาพล็อตได้เลย กรุณาตรวจสอบไฟล์ .mat');
end

fprintf('>> เจอข้อมูลที่ตัวแปร: "%s"\n', var_found_name);

%% ======= 3. EXTRACT: ดึงค่า Time และ Data =======
t = [];
w = [];

try
    % กรณี 1: Simulink Dataset
    if isa(ts_obj, 'Simulink.SimulationData.Dataset')
        fprintf('Format: Dataset\n');
        elem = ts_obj.getElement(1); % ดึงสัญญาณแรก
        t = elem.Values.Time;
        w = elem.Values.Data;
        
    % กรณี 2: Timeseries
    elseif isa(ts_obj, 'timeseries')
        fprintf('Format: Timeseries\n');
        t = ts_obj.Time;
        w = ts_obj.Data;
        
    % กรณี 3: Struct (ที่มี time, values)
    elseif isstruct(ts_obj)
        fprintf('Format: Struct\n');
        if isfield(ts_obj, 'time'), t = ts_obj.time; end
        if isfield(ts_obj, 'values'), w = ts_obj.values; 
        elseif isfield(ts_obj, 'signals'), w = ts_obj.signals(1).values; end
        
    % กรณี 4: Matrix ธรรมดา
    elseif isnumeric(ts_obj)
        fprintf('Format: Numeric Matrix\n');
        if size(ts_obj, 2) >= 2
            t = ts_obj(:,1);
            w = ts_obj(:,2);
        else
            w = ts_obj;
            t = (0:length(w)-1)' * 0.01; % สร้างเวลาเทียม
        end
    end
    
    % จัดการขนาดข้อมูล
    t = double(t(:));
    w = double(squeeze(w(:)));
    
    if isempty(t) || isempty(w)
        error('ข้อมูลว่างเปล่า (Empty Data)'); 
    end
    
catch ME
    error('ดึงข้อมูลไม่สำเร็จ: %s', ME.message);
end

%% ======= 4. PROCESS & FFT =======
% เลือกช่วงเวลา
idx = (t >= t_start) & (t <= t_end);
t = t(idx);
w = w(idx);

% ลบ DC Offset
w_no_dc = w - mean(w);

% Sampling Parameters
dt = mean(diff(t));
if isnan(dt) || dt == 0, dt = 0.001; end
Fs = 1/dt;
fprintf('Sampling Fs: %.2f Hz\n', Fs);

% FFT Calculation
N = length(w_no_dc);
X = fft(w_no_dc);
f = (0:N-1)*(Fs/N);
mag = abs(X)/N;

% จัดเรียงกราฟ FFT (ครึ่งแรก)
half_N = floor(N/2);
f_plot = f(1:half_N);
mag_plot = mag(1:half_N) * 2; % คูณ 2 เพื่อชดเชยฝั่งลบ

%% ======= 5. PLOT =======
figure('Color','black', 'Name', 'FFT Result');

subplot(2,1,1);
plot(t, w, 'b'); grid on;
title(['Time Domain: ' var_found_name], 'Interpreter', 'none');
xlabel('Time (s)'); ylabel('Amplitude');
xlim([min(t) max(t)]);

subplot(2,1,2);
plot(f_plot, mag_plot, 'r', 'LineWidth', 1.2); grid on;
title('Frequency Domain (FFT)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
xlim([0 f_max_plot]);

% Peak Label
[max_val, loc] = max(mag_plot);
peak_freq = f_plot(loc);
text(peak_freq, max_val, sprintf(' Peak: %.1f Hz', peak_freq), ...
    'VerticalAlignment','bottom', 'FontWeight','bold');

fprintf('Analysis Done.\n');