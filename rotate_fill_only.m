function rotate_fill_only(dataDir, subjectID, fileClosed, fileOpen)
% ROTATE_FILL_ONLY  Plot alpha-band (8–12 Hz) power difference with only the
% colour-filled scalp map rotated 90° clockwise.
%
%   rotate_fill_only(dataDir, subjectID, fileClosed, fileOpen)
%
%   Inputs:
%     dataDir    – folder containing the EEGLAB .set files
%     subjectID  – string for the plot title (e.g. 'sub-01')
%     fileClosed – filename of eyes-closed dataset
%     fileOpen   – filename of eyes-open   dataset
%
%   Example:
%     rotate_fill_only('/Users/gaganmundada/Desktop/eyedataset', ...
%                      'sub-01', ...
%                      'sub-01_ses-session1_task-eyesclosed_eeg.set', ...
%                      'sub-01_ses-session1_task-eyesopen_eeg.set');

% Load the eyes-closed dataset
EEG_closed = pop_loadset('filename', fileClosed, 'filepath', dataDir);

% Load the eyes-open dataset
EEG_open = pop_loadset('filename', fileOpen, 'filepath', dataDir);

% Keep only channels common to both (order of EEG_closed)
closedLabels = {EEG_closed.chanlocs.labels};
openLabels = {EEG_open.chanlocs.labels};
commonLabels = intersect(closedLabels, openLabels, 'stable');
EEG_closed = pop_select(EEG_closed, 'channel', commonLabels);
EEG_open = pop_select(EEG_open, 'channel', commonLabels);

% Compute power spectrum from 1 to 40 Hz for EEG_closed
[specC, freqs] = spectopo(EEG_closed.data, 0, EEG_closed.srate, 'freqrange', [1 40], 'plot', 'off');

% Compute power spectrum from 1 to 40 Hz for EEG_open
[specO, ~] = spectopo(EEG_open.data, 0, EEG_open.srate, 'freqrange', [1 40], 'plot', 'off');

% Identify alpha band indices (8–12 Hz)
alphaIdx = freqs >= 8 & freqs <= 12;

% Average alpha power for each channel
alpha_closed = mean(specC(:, alphaIdx), 2);
alpha_open = mean(specO(:, alphaIdx), 2);

% Compute difference (closed minus open)
alpha_diff = alpha_closed - alpha_open;

% Rotate the channel-location coordinates by +90° clockwise
rotChanlocs = EEG_closed.chanlocs;
for iChan = 1:length(rotChanlocs)
    x = rotChanlocs(iChan).X;
    y = rotChanlocs(iChan).Y;
    rotChanlocs(iChan).X = y;
    rotChanlocs(iChan).Y = -x;
end

% Plotting
figure;
lims = [min(alpha_diff) max(alpha_diff)];

% Draw the rotated filled map only with rotated chanlocs
hPatch = topoplot(alpha_diff, rotChanlocs, 'maplimits', lims, 'style', 'map', 'electrodes', 'off');
hold on;

% Additionally rotate the patch coordinates by +90° clockwise
X = hPatch.XData;
Y = hPatch.YData;
hPatch.XData = Y;
hPatch.YData = -X;

% Overlay unrotated contour lines and electrode markers
topoplot(alpha_diff, EEG_closed.chanlocs, 'maplimits', lims, 'style', 'contour', 'numcontour', 6, 'electrodes', 'on');

% Overlay the head outline (circle, nose, ears)
topoplot([], EEG_closed.chanlocs, 'style', 'outline', 'electrodes', 'off');

% Apply Jet colormap and add vertical colorbar with black labels
colormap(jet);
cb = colorbar;
cb.Label.String = 'Power difference (dB)';
cb.Label.Color = 'k';
cb.Color = 'k';

% Title the figure
title([subjectID, ': Alpha Power Difference (Eyes Closed - Eyes Open)'], 'FontWeight', 'bold', 'Color', 'k');
end
