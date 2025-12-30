% modified by cbd 12/08/2025
% autoDetectTubes: Automatically detects circular phantom tubes in an image
% and creates ROI structures for each detected tube.
%
% This function uses background subtraction, connected component analysis,
% and circular ordering to detect and label phantom tubes.
%
%   INPUTS:
%       img             - 2D image matrix to analyze
%       imageSize       - [height, width] of the image
%       gaussSigma      - Sigma for Gaussian smoothing (default: 4)
%       minTubePixels   - Minimum pixels per tube (default: 10)
%       roiNamePrefix   - Prefix for ROI names (default: 'Tube')
%       sortCircular    - Sort tubes by circular position (default: true)
%
%   OUTPUTS:
%       roi             - Struct array containing detected ROI data with fields:
%                         .coords - polygon coordinates outlining the tube
%                         .mask - binary mask for the ROI
%                         .name - ROI name
%                         .nomConc - nominal concentration (initialized to NaN)
%                         .nomExch - nominal exchange rate (initialized to NaN)
%                         .center - [x, y] center coordinates
%                         .tubeIndex - tube index in circular order
%
function roi = autoDetectTubes(img, imageSize, gaussSigma, minTubePixels, ...
    roiNamePrefix, sortCircular)

%% Input validation and default parameters
if nargin < 3 || isempty(gaussSigma)
    gaussSigma = 4;
end
if nargin < 4 || isempty(minTubePixels)
    minTubePixels = 10;
end
if nargin < 5 || isempty(roiNamePrefix)
    roiNamePrefix = 'Tube';
end
if nargin < 6 || isempty(sortCircular)
    sortCircular = true;
end

%% Step 1: Detect phantom outline
% Smooth the image to reduce noise
Sm = imgaussfilt(img, gaussSigma);

% Normalize image to [0,1]
Smn = mat2gray(Sm);

% Threshold (Otsu)
bw_phantom = imbinarize(Smn);

% Keep only the largest connected component (phantom box)
CCp = bwconncomp(bw_phantom);
numPix = cellfun(@numel, CCp.PixelIdxList);
[~, idxMax] = max(numPix);
phantom_outline = false(size(bw_phantom));
phantom_outline(CCp.PixelIdxList{idxMax}) = true;

% Fill any holes inside phantom
phantom_outline = imfill(phantom_outline, "holes");

% Optional: Smooth outline
phantom_outline = imopen(phantom_outline, strel('disk', 5));

%% Step 2: Detect tubes using background subtraction
% Estimate background by heavy smoothing
bgd = imgaussfilt(img, gaussSigma);

% Subtract background
I = img - bgd;

% Binarize using Otsu's method
bw = imbinarize(I);

% Apply phantom outline mask to remove regions outside phantom
bw(~phantom_outline) = 0;

%% Step 3: Filter connected components to find tubes
CC = bwconncomp(bw, 8);
numOfPixels = cellfun(@numel, CC.PixelIdxList);

% Remove the largest component (likely not a tube)
[~, indexOfMax] = max(numOfPixels);
bw(CC.PixelIdxList{indexOfMax}) = 0;

% Remove very small components (noise)
indexOfSmall = find(numOfPixels < minTubePixels);
for i = 1:length(indexOfSmall)
    bw(CC.PixelIdxList{indexOfSmall(i)}) = 0;
end

% Fill holes in remaining tubes
bw = imfill(bw, "holes");

% Clear tubes touching image border
bw = imclearborder(bw);

%% Step 4: Label remaining tubes
CC = bwconncomp(bw, 8);
numTubes = CC.NumObjects;

if numTubes == 0
    roi = struct('coords', {}, 'mask', {}, 'name', {}, 'nomConc', {}, ...
                 'nomExch', {}, 'center', {}, 'tubeIndex', {});
    warning('autoDetectTubes:NoTubesDetected', ...
        'No tubes detected. Try adjusting detection parameters.');
    return;
end

% Get tube properties
stats = regionprops(CC, 'Centroid', 'PixelIdxList');
centroids = cat(1, stats.Centroid);

%% Step 5: Sort tubes by circular position (optional)
if sortCircular && numTubes > 1
    % Compute phantom center
    phantomStats = regionprops(phantom_outline, 'Centroid');
    phantomCenter = phantomStats.Centroid;

    % Compute angle of each tube centroid relative to phantom center
    angles = atan2(centroids(:,2) - phantomCenter(2), ...
                   centroids(:,1) - phantomCenter(1));

    % Sort tubes by angle (counter-clockwise from right)
    [~, sortedIdx] = sort(angles);
else
    % No sorting - use original order
    sortedIdx = (1:numTubes)';
end

%% Step 6: Create ROI structures
roi = struct('coords', cell(1, numTubes), ...
             'mask', cell(1, numTubes), ...
             'name', cell(1, numTubes), ...
             'nomConc', cell(1, numTubes), ...
             'nomExch', cell(1, numTubes), ...
             'center', cell(1, numTubes), ...
             'tubeIndex', cell(1, numTubes));

for i = 1:numTubes
    idx = sortedIdx(i);

    % Create binary mask for this tube
    tubeMask = false(imageSize);
    tubeMask(CC.PixelIdxList{idx}) = true;

    % Get boundary coordinates
    boundaries = bwboundaries(tubeMask, 'noholes');
    if ~isempty(boundaries)
        boundary = boundaries{1};
        % Convert from [row, col] to [x, y]
        coords = [boundary(:,2), boundary(:,1)];
    else
        % Fallback: create circular boundary from centroid
        c = centroids(idx, :);
        theta = linspace(0, 2*pi, 100);
        r = sqrt(numel(CC.PixelIdxList{idx}) / pi);
        coords = [c(1) + r*cos(theta)', c(2) + r*sin(theta)'];
    end

    % Store ROI data
    roi(i).coords = coords;
    roi(i).mask = tubeMask;
    roi(i).name = sprintf('%s%d', roiNamePrefix, i);
    roi(i).nomConc = NaN;
    roi(i).nomExch = NaN;
    roi(i).center = centroids(idx, :);
    roi(i).tubeIndex = i;
end

end