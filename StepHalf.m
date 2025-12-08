%% MATLAB Script: Full vs Half Step (Show Range <= 600 RPM)
clear; clc; close all;

%% 1. Config: ตั้งค่า
filename = 'Ana1_4Step.mat';
targetKeywords = {'Moving', 'Average'}; 
baseYLabel = 'Speed (RPM)';

% กำหนดค่าเพดานความเร็ว (แสดงเฉพาะช่วงที่ Full Step ต่ำกว่าหรือเท่ากับค่านี้)
limit_rpm = 660; 

%% 2. Load & Auto-Detect: โหลดข้อมูล
if ~isfile(filename), error('ไม่พบไฟล์ %s', filename); end
fprintf('Loading %s ...\n', filename);
loadedData = load(filename);
varNames = fieldnames(loadedData);

found = false;
time = [];
data_raw = [];
foundName = '';

for i = 1:length(varNames)
    obj = loadedData.(varNames{i});
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
            else, time = (0:length(data_raw)-1)' * 0.01; end
            found = true; break;
        end
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

%% 3. Cutoff Logic: ตัดกราฟเมื่อความเร็วเกิน Limit
if found
    fprintf('>> พบสัญญาณ: "%s"\n', foundName);
    
    % คำนวณค่า Full Step เพื่อใช้เช็คเงื่อนไข
    full_step_check = data_raw * 2;
    
    % ค้นหาจุดแรกที่ความเร็ว *เกิน* 600 RPM
    exceedIndices = find(full_step_check > limit_rpm, 1, 'first');
    
    if ~isempty(exceedIndices)
        % ตัดข้อมูลทิ้งตั้งแต่จุดที่เกินเป็นต้นไป
        cutIdx = exceedIndices - 1;
        
        % กันพลาดกรณีข้อมูลเริ่มมาก็เกินเลย
        if cutIdx < 1, cutIdx = 1; end
        
        fprintf('>> เงื่อนไข: แสดงเฉพาะช่วง Full Step <= %d RPM\n', limit_rpm);
        fprintf('>> ตัดกราฟที่เวลา t = %.2f s (Stop plotting as speed exceeds limit)\n', time(cutIdx));
        
        time = time(1:cutIdx);
        data_raw = data_raw(1:cutIdx);
    else
        fprintf('>> ข้อมูลทั้งหมดมีค่าไม่เกิน %d RPM (แสดงครบทุกจุด)\n', limit_rpm);
    end

    %% 4. Calculate & Plot Comparison
    half_step_data = data_raw;      % Half = Original
    full_step_data = data_raw * 2;  % Full = Original * 2
    
    figure('Color', 'black', 'Name', 'Step Comparison (Range <= 600 RPM)');
    hold on;
    
    % Plot Full Step (Blue)
    plot(time, full_step_data, 'b-', 'LineWidth', 2.0);
    
    % Plot Half Step (Red Dashed)
    plot(time, half_step_data, 'r-', 'LineWidth', 2.0);
    
    % เส้นขีดบอกระดับ Limit
    yline(limit_rpm, 'k:', sprintf('Limit @ %d RPM', limit_rpm), ...
        'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');

    grid on;
    xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel(baseYLabel, 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Comparison: Full Step vs Half Step', limit_rpm), 'FontSize', 14);
    
    % ปรับแกน
    xlim([min(time) max(time)]);
    ylim([0 limit_rpm * 1.1]); % ปรับแกน Y ให้พอดีกับ Limit
    
    legend({'Full Step', 'Half Step'}, ...
           'Location', 'best', 'FontSize', 12);
    
    % Label ค่าสุดท้ายที่พล็อต (ซึ่งควรจะใกล้เคียง 600)
    %text(time(end), full_step_data(end), sprintf(' End: %.0f RPM', full_step_data(end)), ...
       % 'Color', 'b', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
    
    hold off;
    fprintf('Plotting Complete.\n');
    
else
    error('ไม่พบข้อมูลที่มีคำว่า Moving Average ในไฟล์นี้');
end