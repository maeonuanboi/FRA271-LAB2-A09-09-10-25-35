% --- Script: Load Data & Plot Custom Graphs ---
clear; clc;

% 1. โหลดไฟล์
filename = 'matlab.mat';
if exist(filename, 'file')
    loadedData = load(filename);
    varNames = fieldnames(loadedData);
    datasetData = loadedData.(varNames{1}); % ดึง Dataset ออกมา
else
    error('ไม่พบไฟล์ %s กรุณาตรวจสอบว่าไฟล์อยู่ใน Folder เดียวกัน', filename);
end

try
    % --- ส่วนที่ 1: ดึงค่า RPM และคำนวณ Moving Average ---
    % ค้นหาสัญญาณชื่อ 'Output Angular speed' (หรือ 'RPM' ถ้าคุณเปลี่ยนชื่อแล้ว)
    sig_rpm = datasetData.get('Output Angular speed'); 
    
    t = sig_rpm.Values.Time;
    rpm_raw = sig_rpm.Values.Data;
    
    % คำนวณ Moving Average (จำลอง AVG2.1)
    % หมายเหตุ: ปรับค่า windowSize ตามความเหมาะสมของข้อมูล
    windowSize = 20; 
    rpm_mov_avg = movmean(rpm_raw, windowSize);

    % --- ส่วนที่ 2: ดึงค่า Step Frequency ---
    % พยายามดึงสัญญาณชื่อ 'Step Frequency'
    % (ถ้าใน Simulink ไม่ได้ตั้งชื่อนี้เป๊ะๆ ให้แก้ชื่อในวงเล็บครับ)
    try
        sig_step = datasetData.get('Step Frequency');
        step_data = sig_step.Values.Data;
    catch
        % กรณีหาไม่เจอ ให้ลองคำนวณคร่าวๆ หรือสร้างกราฟว่าง
        warning('ไม่พบสัญญาณชื่อ "Step Frequency" ในไฟล์ .mat');
        fprintf('กำลังสร้างข้อมูลจำลองสำหรับ Step Frequency (เพื่อทดสอบกราฟ)...\n');
        % สูตรสมมติ: Freq = RPM * PolePairs / 60 (สำหรับมอเตอร์ 4-pole)
        step_data = abs(rpm_raw) * 2 / 60; 
    end

    % --- ส่วนที่ 3: พล็อตกราฟ ---
    plot_dual_graph_dark(t, step_data, rpm_raw, rpm_mov_avg);

catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('รายชื่อสัญญาณที่มีใน Dataset:\n');
    disp(datasetData.getElementNames);
end