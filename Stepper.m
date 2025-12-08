%% MATLAB Script: Micro Stepping Analysis (Auto-Cutoff Tail)
clear; clc; close all;

%% 1. Config: ตั้งค่า
filename = 'Ana1_4Step.mat';
targetKeywords = {'Moving', 'Average'}; 
baseYLabel = 'Speed (RPM)';

% ค่า % การตัดกราฟ (เช่น 0.95 คือถ้าค่าลดลงต่ำกว่า 95% ของค่าสูงสุด ให้ตัดทิ้ง)
cutoff_threshold = 0.95; 

%% 2. Load & Auto-Detect: โหลดและค้นหาข้อมูล
if ~isfile(filename), error('ไม่พบไฟล์ %s', filename); end
fprintf('Loading %s ...\n', filename);
loadedData = load(filename);
varNames = fieldnames(loadedData);

found = false;
time = [];
data_raw = [];
foundName = '';

% วนลูปค้นหาตัวแปร
for i = 1:length(varNames)
    obj = loadedData.(varNames{i});
    
    % กรณี Table/Timetable
    if istable(obj) || istimetable(obj)
        colNames = obj.Properties.VariableNames;
        matchIdx = [];
        for k = 1:length(colNames)
            if all(contains(colNames{k}, targetKeywords, 'IgnoreCase', true))
                matchIdx = k; break;
            end
        end
        
        if ~isempty(matchIdx)
            foundName = colNames{matchIdx};
            data_raw = obj.(foundName);
            if istimetable(obj), time = seconds(obj.Time);
            else
                timeIdx = find(contains(colNames, 'Time', 'IgnoreCase', true), 1);
                if ~isempty(timeIdx), time = obj.(colNames{timeIdx});
                else, time = (0:length(data_raw)-1)' * 0.01; end
            end
            found = true; break;
        end
        
    % กรณี Simulink Dataset
    elseif isa(obj, 'Simulink.SimulationData.Dataset')
        try
            for k = 1:obj.numElements
                if all(contains(obj.getElement(k).Name, targetKeywords, 'IgnoreCase', true))
                    elem = obj.getElement(k);
                    time = elem.Values.Time;
                    data_raw = elem.Values.Data;
                    foundName = elem.Name;
                    found = true; break;
                end
            end
            if found, break; end
        catch
        end
    end
end

%% 3. Auto-Cutoff Logic: ตัดช่วงท้ายที่กราฟตก
if found
    fprintf('>> พบสัญญาณ: "%s"\n', foundName);
    
    % หาจุดสูงสุดและตำแหน่ง
    [maxVal, maxIdx] = max(data_raw);
    
    % ค้นหาจุดที่กราฟเริ่มตกลง (หลังจากจุดสูงสุด)
    % หาจุดแรกที่ค่าลดลงต่ำกว่า Threshold * MaxValue
    dropCondition = data_raw(maxIdx:end) < (maxVal * cutoff_threshold);
    relativeDropIdx = find(dropCondition, 1, 'first');
    
    if ~isempty(relativeDropIdx)
        cutIdx = maxIdx + relativeDropIdx - 1;
        fprintf('>> ตัดกราฟที่เวลา t = %.2f วินาที (จุดที่ค่าเริ่มลดลง)\n', time(cutIdx));
        
        % ตัดข้อมูล
        time = time(1:cutIdx);
        data_raw = data_raw(1:cutIdx);
    else
        fprintf('>> ไม่พบจุดที่กราฟตกลงอย่างมีนัยสำคัญ (แสดงข้อมูลทั้งหมด)\n');
    end

    %% 4. Plot Multiple Lines: พล็อตกราฟรวม
    figure('Color', 'black', 'Name', 'Micro Stepping Comparison (Cutoff)');
    hold on;
    
    divisors = [1, 2, 4, 8];
    legendNames = {
        'Micro Step 1/4',  ... 
        'Micro Step 1/8',  ... 
        'Micro Step 1/16', ... 
        'Micro Step 1/32'      
    };
    lineColors = {'b', 'r', 'g', 'm'}; 
    
    for i = 1:4
        % คำนวณค่า
        current_data = data_raw / divisors(i);
        
        % พล็อต
        plot(time, current_data, 'Color', lineColors{i}, 'LineWidth', 1.5);
    end
    
    grid on;
    xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(baseYLabel, 'FontSize', 12, 'FontWeight', 'bold');
    title('Comparison of Micro Stepping Modes', 'FontSize', 14);
    
    % ปรับแกน X ให้พอดีกับข้อมูลที่ตัดแล้ว
    xlim([min(time) max(time)]);
    
    legend(legendNames, 'Location', 'best', 'FontSize', 10);
    hold off;
    fprintf('Plotting Complete.\n');
    
else
    error('ไม่พบข้อมูลที่มีคำว่า Moving Average ในไฟล์นี้');
end