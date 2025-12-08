function plot_dual_graph_dark(time, step_freq, rpm_raw, rpm_mov_avg)
% PLOT_DUAL_GRAPH_DARK สร้างกราฟ 2 แถว (Step Freq, RPM) พื้นหลังดำ
%
% inputs:
%   time        - เวกเตอร์เวลา
%   step_freq   - ข้อมูล Step Frequency
%   rpm_raw     - ข้อมูล RPM ดิบ (เส้นจาง)
%   rpm_mov_avg - ข้อมูล RPM ที่ผ่าน Moving Average แล้ว (เส้นหลัก)

    % สร้างหน้าต่าง Figure สีดำ
    figure('Name', 'Step Frequency & RPM Analysis', 'Color', 'k', 'NumberTitle', 'off');

    % --- กราฟที่ 1: Step Frequency ---
    ax1 = subplot(2, 1, 1);
    plot(time, step_freq, 'Color', [0, 1, 0], 'LineWidth', 1.5); % สีเขียว (Green)
    title('Step Frequency', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Frequency [Hz]', 'Color', 'w');
    grid on;
    % ปรับ Theme แกน
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.3);
    xlim([min(time) max(time)]);

    % --- กราฟที่ 2: RPM (Moving AVG2.1) ---
    ax2 = subplot(2, 1, 2);
    hold on;
    % พล็อตเส้น RPM ดิบเป็นพื้นหลัง (สีเทาจางๆ) เพื่อให้เห็นการเปลี่ยนแปลง
    plot(time, rpm_raw, 'Color', [0.3, 0.3, 0.3], 'LineWidth', 0.5, 'DisplayName', 'Raw RPM');
    % พล็อตเส้น Moving Average (สีฟ้า)
    plot(time, rpm_mov_avg, 'Color', [0, 1, 1], 'LineWidth', 1.5, 'DisplayName', 'Moving AVG');
    
    title('RPM (Moving AVG2.1)', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Speed [RPM]', 'Color', 'w');
    xlabel('Time [s]', 'Color', 'w');
    legend('TextColor', 'w', 'Color', 'k', 'EdgeColor', 'w');
    grid on;
    
    % ปรับ Theme แกน
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.3);
    xlim([min(time) max(time)]);
    hold off;

    % เชื่อมแกน X
    linkaxes([ax1, ax2], 'x');
end