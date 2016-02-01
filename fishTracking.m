% ------------------------------------------------------------------------
% Fish Tracking
% Drago Senic - dragosenic@gmail.com
% 19.11.2015.
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% user instructions:
% Open "fishTracking.m" file in MATLAB and run. 
% Please make sure that "result" folder is in the same directory with 
% "fishTracking.m" file. "result" folder must contain all
% subfolders as originaly provided. Also make sure that all videos are also
% located in the same folder.
%
% -- fishTracking_Drago_Senic.m
% -- Video01_09Nov2015.mp4
% -- Video02_09Nov2015.mp4
% -- Video03_09Nov2015.mp4
% -- Video04_09Nov2015.mp4
% -- Video05_09Nov2015.mp4
% -- result
%       +-- Video01_09Nov2015
%           +-- FishPositions
%           +-- FishWithoutBackground
%       +-- Video02_09Nov2015
%           +-- FishPositions
%           +-- FishWithoutBackground
%       +-- Video03_09Nov2015
%           +-- FishPositions
%           +-- FishWithoutBackground
%       +-- Video04_09Nov2015
%           +-- FishPositions
%           +-- FishWithoutBackground
%       +-- Video05_09Nov2015
%           +-- FishPositions
%           +-- FishWithoutBackground
%
% ------------------------------------------------------------------------


% ------------------------------------------------------------------------
% 0. Load the video 
% ------------------------------------------------------------------------
% 0.1 open list dialog so user can choose a video
videoIndex = listdlg( ...
    'ListString', {'Video01_09Nov2015.mp4' 'Video02_09Nov2015.mp4' 'Video03_09Nov2015.mp4' 'Video04_09Nov2015.mp4' 'Video05_09Nov2015.mp4'}, ...
    'SelectionMode', 'Single', ...
    'Name', 'Choose a Video');

if strcmp(num2str(videoIndex),'')
    return;
end

videoName = sprintf('Video0%s_09Nov2015', num2str(videoIndex));

% 0.2 load the chosen video
oVideo = VideoReader(sprintf('%s.mp4',videoName));

vHeight = oVideo.Height;
vWidth = oVideo.Width;
vDuration = oVideo.Duration;

% 0.3 clear the output file
out = fopen(strcat('.\result\', videoName, '\output.txt'),'w');
fprintf(out,'');
fclose(out);
% fprintf('%s, duration %ss, height %spx, width %spx', videoName, num2str(vDuration), num2str(vHeight), num2str(vWidth));
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% 1. Detect the arena 
fprintf('1. Detect the arena');
% The arena will be estimated as twice the size of the black area.
% Black area will be extracted by means of high contrast.
% ------------------------------------------------------------------------
absoluteAverageBackground = zeros(vHeight,vWidth,3,'uint16');
absoluteAverageBackground8bit = zeros(vHeight,vWidth,3,'uint8');

% 1.1 calculate 5 second average background
% from 5th and 10th second of the video in order to identify black area
highContrastAverageBackground = zeros(vHeight,vWidth,3,'uint8');
BLACKWHITE_CONTRAST_THRESHOLD = 30; % this value is determined experimentally 

k = 1;
oVideo.CurrentTime = 5;         % from 5th second
while oVideo.CurrentTime <= 10  % to 10th second
    
    %
    currentFrame = readFrame(oVideo);
   
    %
    for m = 1:vHeight
        for n = 1:vWidth
            absoluteAverageBackground(m,n,1) = absoluteAverageBackground(m,n,1) + uint16(currentFrame(m,n,1));
            absoluteAverageBackground(m,n,2) = absoluteAverageBackground(m,n,2) + uint16(currentFrame(m,n,2));
            absoluteAverageBackground(m,n,3) = absoluteAverageBackground(m,n,3) + uint16(currentFrame(m,n,3));
        end
    end
            
    %
    if mod(k,10) == 0
       fprintf('*');
    end
    
    %
    k = k + 1;
end

minXplayground = vWidth;
maxXplayground = 0;
minYplayground = vHeight;
maxYplayground = 0;

% 1.2 apply high contrast to identifz black area
for m = 1:vHeight 
    for n = 1:vWidth
        
        absoluteAverageBackground8bit(m,n,1) = uint8(absoluteAverageBackground(m,n,1)/(k-1));
        absoluteAverageBackground8bit(m,n,2) = uint8(absoluteAverageBackground(m,n,2)/(k-1));
        absoluteAverageBackground8bit(m,n,3) = uint8(absoluteAverageBackground(m,n,3)/(k-1));
        
        shadeOfGrey = uint8(( ...
            absoluteAverageBackground(m,n,1)/(k-1) + ...
            absoluteAverageBackground(m,n,2)/(k-1) + ...
            absoluteAverageBackground(m,n,3)/(k-1)) / 3.0);
        
        BorW = 255; % white
        if (shadeOfGrey <= BLACKWHITE_CONTRAST_THRESHOLD)
            BorW = 0; % black
            
            if n < minXplayground
                minXplayground = n;
            end
            if n > maxXplayground
                maxXplayground = n;
            end
            if m < minYplayground
                minYplayground = m;
            end
            if m > maxYplayground
                maxYplayground = m;
            end
        end
        
        highContrastAverageBackground(m,n,1) = BorW;
        highContrastAverageBackground(m,n,2) = BorW; 
        highContrastAverageBackground(m,n,3) = BorW; 
    end
end

% 1.3 width of the arena is twice the width of black area
maxXplayground = minXplayground + 2 * (maxXplayground - minXplayground);

% 1.4 draw perpendicular lines to outline arena
for m = 1:vHeight 
    highContrastAverageBackground(m,minXplayground,1) = 0;
    highContrastAverageBackground(m,minXplayground,2) = 0; 
    highContrastAverageBackground(m,minXplayground,3) = 255; 
        
    highContrastAverageBackground(m,maxXplayground,1) = 255;
    highContrastAverageBackground(m,maxXplayground,2) = 0; 
    highContrastAverageBackground(m,maxXplayground,3) = 0; 
end
for n = 1:vWidth
    highContrastAverageBackground(minYplayground,n,1) = 255;
    highContrastAverageBackground(minYplayground,n,2) = 255; 
    highContrastAverageBackground(minYplayground,n,3) = 0;
    
    highContrastAverageBackground(maxYplayground,n,1) = 0;
    highContrastAverageBackground(maxYplayground,n,2) = 255; 
    highContrastAverageBackground(maxYplayground,n,3) = 0;  
end

% 1.5 write images to files
filename = strcat('.\result\', videoName, '\arena.jpg');
imwrite(highContrastAverageBackground,filename);

filename = strcat('.\result\', videoName, '\averageBackground.jpg');
imwrite(absoluteAverageBackground8bit,filename);

% 1.6 set the playgroundWidth and playgroundHeight
playgroundWidth = maxXplayground - minXplayground + 1;
playgroundHeight = maxYplayground - minYplayground + 1;

out = fopen(strcat('.\result\', videoName, '\output.txt'),'a');
fprintf('\nplayground height %spx, playground width %spx\n\n', num2str(playgroundHeight), num2str(playgroundWidth));
fprintf(out, 'playground X=%spx, playground Y=%spx\r\n', num2str(minXplayground), num2str(minYplayground));
fprintf(out, 'playground height=%spx, playground width=%spx\r\n\r\n', num2str(playgroundHeight), num2str(playgroundWidth));
% ------------------------------------------------------------------------


% ------------------------------------------------------------------------
% 2. Fish tracking 
% ------------------------------------------------------------------------
fprintf('2. Fish tracking\n');
fprintf(out, 'time, posX, posY\r\n');
% The algorithm for fish detection is based on calculating the difference 
% between current frame and average background. The average background
% will be calculated from most recent frames and this number of frames 
% is stored in BACKGROUND_FRAMES_COUNT variable (constant).
%
% Since the background is not static (i.e. the water is moving all the time)
% a decision is taken to introduce an additional parameter that will help to
% better differentiate fish from the background. This parameter is the color
% of fish and it is determined manually as RGB color, one when fish is on 
% the black part and another one when fish is on the white part of the arena.
%
% NOTE: this algorithm will not detect the fish if it is not moving.
% ------------------------------------------------------------------------
BACKGROUND_FRAMES_COUNT = 40;
backgroundFrames = cell(BACKGROUND_FRAMES_COUNT);
averageBackground = zeros(vHeight,vWidth,3,'uint16');

% this holds all detected positions (drawn as yellow squares)
fishPositionsJpg = zeros(vHeight,vWidth,3,'uint8');

% this holds the difference between current frame
% and average background
deltaFrame = zeros(vHeight,vWidth,3,'uint8');

% The difference between current frame and the average background will be 
% calculated for every pixel by taking in account all neighbouring pixels that
% that belong to a square window with center at that pixel.
% PIXEL_WINDOW_SIZE variable will hold the value of window size
%
%     x x x x x
%     x x x x x
%     x x X x x
%     x x x x x
%     x x x x x  "pixel window 5x5"
%
% -----------------------------------------------
PIXEL_WINDOW_SIZE = 3; % odd number

% fish colors determined manually
fishColors = cell(5);
fishColors{1} = struct('left',[85 75 65], 'right',[110 90 65]);
fishColors{2} = struct('left',[85 75 65], 'right',[110 90 65]);
fishColors{3} = struct('left',[40 50 45], 'right',[110 90 65]);
fishColors{4} = struct('left',[85 75 65], 'right',[110 90 65]);
fishColors{5} = struct('left',[45 40 35], 'right',[75 60 40]);

fishColor = ...
    [fishColors{videoIndex}.left(1) fishColors{videoIndex}.left(2) fishColors{videoIndex}.left(3); ...
    fishColors{videoIndex}.right(1) fishColors{videoIndex}.right(2) fishColors{videoIndex}.right(3)];

%
previous_fish_positionX = double(0);
previous_time = double(0);
time_spent_in_black = double(0);
time_fishtracking = double(0);

%create output video
%video_output_pathfile = strcat('.\result\', videoName, '\video_output.avi');
video_output_pathfile = strcat('.\out_', videoName, '.avi');
videoOutput = VideoWriter(video_output_pathfile);
videoOutput.FrameRate = 29; 
videoOutput.Quality = 100;   
open(videoOutput);

% ------------------------------------------------------------------------
% The main loop
% ------------------------------------------------------------------------
k = 1; 
oVideo.CurrentTime = 0;
while oVideo.CurrentTime < vDuration
    
    %
    currentFrame = readFrame(oVideo);
    
    % a) calculate initial average background
    if k <= BACKGROUND_FRAMES_COUNT
        
        %
        for m = minYplayground:maxYplayground
            for n = minXplayground:maxXplayground
                averageBackground(m,n,1) = averageBackground(m,n,1) + uint16(currentFrame(m,n,1));
                averageBackground(m,n,2) = averageBackground(m,n,2) + uint16(currentFrame(m,n,2));
                averageBackground(m,n,3) = averageBackground(m,n,3) + uint16(currentFrame(m,n,3));
            end
        end
        
        %
        backgroundFrames{k} = currentFrame;
        
    % b) fish tracking starts after initial background was calculated   
    else
        
        %
        for m = minYplayground:maxYplayground
            for n = minXplayground:maxXplayground
                averageBackground(m,n,1) = averageBackground(m,n,1) - uint16(backgroundFrames{1}(m,n,1)) + uint16(currentFrame(m,n,1));
                averageBackground(m,n,2) = averageBackground(m,n,2) - uint16(backgroundFrames{1}(m,n,2)) + uint16(currentFrame(m,n,2));
                averageBackground(m,n,3) = averageBackground(m,n,3) - uint16(backgroundFrames{1}(m,n,3)) + uint16(currentFrame(m,n,3));
            end
        end        
 
        %        
        for i = 1:BACKGROUND_FRAMES_COUNT - 1
            backgroundFrames{i} = backgroundFrames{i + 1};
        end
        backgroundFrames{BACKGROUND_FRAMES_COUNT} = currentFrame;        
        
        %
        fishCenterOfMassX = double(0);
        fishCenterOfMassY = double(0);
        sumMassX = double(0);
        sumMassY = double(0);
        
        %
        fishCenterOfMass2X = double(0);
        fishCenterOfMass2Y = double(0);
        sumMass2X = double(0);
        sumMass2Y = double(0);
        
        %
        for countY = minYplayground:minYplayground + playgroundHeight
            for countX = minXplayground:minXplayground + playgroundWidth		
                
                avgDelta = double(0);
                energy_pixels_count = 0;
                for i = -fix(PIXEL_WINDOW_SIZE/2):fix(PIXEL_WINDOW_SIZE/2)
                    for j = -fix(PIXEL_WINDOW_SIZE/2):fix(PIXEL_WINDOW_SIZE/2)
                        m = countY + i;
                        n = countX + j;
                        
                        % -----------------------------------------------
                        % To save processing power and time a rule is
                        % applied that if PIXEL_WINDOW_SIZE is greater 
                        % then 3 then it will process only pixels in the 
                        % diagonale of the window
                        %   x           x  
                        %     x       x
                        %       x x x
                        %       x X x
                        %       x x x
                        %     x       x
                        %   x           x
                        % -----------------------------------------------
                        if (abs(i) > 1 || abs(j) > 1) && abs(i) ~= abs(j)
                            continue;
                        end
                        % -----------------------------------------------
                        
                        energy_pixels_count = energy_pixels_count + 1;
                        
                        %
                        currentColorR = double(currentFrame(m,n,1));
                        currentColorG = double(currentFrame(m,n,2));
                        currentColorB = double(currentFrame(m,n,3));                        
                        currentColorMagnitude = sqrt(currentColorR^2 + currentColorG^2 + currentColorB^2);
                        
                        backgroundColorR = double(averageBackground(m,n,1))/double(BACKGROUND_FRAMES_COUNT);
                        backgroundColorG = double(averageBackground(m,n,2))/double(BACKGROUND_FRAMES_COUNT);
                        backgroundColorB = double(averageBackground(m,n,3))/double(BACKGROUND_FRAMES_COUNT);
                        backgroundColorMagnitude = sqrt(backgroundColorR^2 + backgroundColorG^2 + backgroundColorB^2);                        
                                             
                        delta = double(0.0);
                        
                        COLOR_IS_TOO_DARK = 10; %
                        if backgroundColorMagnitude >= COLOR_IS_TOO_DARK && currentColorMagnitude >= COLOR_IS_TOO_DARK
                            %
                            currentColorRnormalized = currentColorR / currentColorMagnitude;
                            currentColorGnormalized = currentColorG / currentColorMagnitude;
                            currentColorBnormalized = currentColorB / currentColorMagnitude;                    
                    
                            %
                            backgroundColorRnormalized = backgroundColorR / backgroundColorMagnitude;
                            backgroundColorGnormalized = backgroundColorG / backgroundColorMagnitude;
                            backgroundColorBnormalized = backgroundColorB / backgroundColorMagnitude;
                                   
                            % calculate the distance of current pixel color
                            % from background color considering the angle
                            % difference and the linear 3d difference
                            distanceFromBackgroundColor_angle = ...
                                    acos(backgroundColorRnormalized * currentColorRnormalized + ... 
                                    backgroundColorGnormalized * currentColorGnormalized + ... 
                                    backgroundColorBnormalized * currentColorBnormalized) ;
                    
                            distanceFromBackgroundColor_3D = sqrt( ...
                                    (backgroundColorR - currentColorR)^2 + ...
                                    (backgroundColorG - currentColorG)^2 + ...
                                	(backgroundColorB - currentColorB)^2 );
                            
                            distanceFromBackgroundColor = distanceFromBackgroundColor_3D * distanceFromBackgroundColor_angle;  

                            % calculate the distance of current pixel color
                            % from "left fish" color considering the angle
                            % difference and the linear 3d difference
                            fishColorLeft_r = fishColor(1,1);
                            fishColorLeft_g = fishColor(1,2);
                            fishColorLeft_b = fishColor(1,3); 
                            fishColorLeft_magnitude = sqrt(fishColorLeft_r^2 + fishColorLeft_g^2 + fishColorLeft_b^2);
                        
                            fishColorLeftNormalized_r = fishColorLeft_r / fishColorLeft_magnitude;
                            fishColorLeftNormalized_g = fishColorLeft_g / fishColorLeft_magnitude;
                            fishColorLeftNormalized_b = fishColorLeft_b / fishColorLeft_magnitude;
                           
                            distanceFromLeftFishColor_angle = ...
                                    acos(fishColorLeftNormalized_r * currentColorRnormalized + ... 
                                    fishColorLeftNormalized_g * currentColorGnormalized + ... 
                                    fishColorLeftNormalized_b * currentColorBnormalized) ;
                            
                            distanceFromLeftFishColor_3d = sqrt( ...
                                    (fishColorLeft_r - currentColorR)^2 + ... 
                                    (fishColorLeft_g - currentColorG)^2 + ...
                                    (fishColorLeft_b - currentColorB)^2 );
                            
                            distanceFromFishColor_left = distanceFromLeftFishColor_3d * distanceFromLeftFishColor_angle;  
                            
                            % calculate the distance of current pixel color
                            % from "right fish" color considering the angle
                            % difference and the linear 3d difference
                            fishColorRight_r = fishColor(1,1);
                            fishColorRight_g = fishColor(1,2);
                            fishColorRight_b = fishColor(1,3); 
                            fishColorRight_magnitude = sqrt(fishColorRight_r^2 + fishColorRight_g^2 + fishColorRight_b^2);
                        
                            fishColorRightNormalized_r = fishColorRight_r / fishColorRight_magnitude;
                            fishColorRightNormalized_g = fishColorRight_g / fishColorRight_magnitude;
                            fishColorRightNormalized_b = fishColorRight_b / fishColorRight_magnitude;
                           
                            distanceFromRightFishColor_angle = ... 
                                    acos(fishColorRightNormalized_r * currentColorRnormalized + ... 
                                    fishColorRightNormalized_g * currentColorGnormalized + ... 
                                    fishColorRightNormalized_b * currentColorBnormalized) ;
                            
                            distanceFromRightFishColor_3d = sqrt( ...
                                    (fishColorRight_r - currentColorR)^2 + ... 
                                    (fishColorRight_g - currentColorG)^2 + ...
                                    (fishColorRight_b - currentColorB)^2 );
                            
                            distanceFromFishColor_right = distanceFromRightFishColor_3d * distanceFromRightFishColor_angle;
                            
                            %
                            if (distanceFromFishColor_right < distanceFromFishColor_left)
                                distanceFromFishColor = distanceFromFishColor_right;
                            else
                                distanceFromFishColor = distanceFromFishColor_left;
                            end
                    
                            %
                            delta = 0;
                            if distanceFromFishColor > 0 % this is to avoid division by zero
                                
                                % delta is the calculated difference between current color
                                % and the background color, considering the color of fish.
                                delta = distanceFromBackgroundColor_3D * distanceFromBackgroundColor / distanceFromFishColor;
                            
                            end
                            

                        end

                        avgDelta = avgDelta + delta;
                    end
                end
                
                avgDelta = avgDelta / energy_pixels_count; %(PIXEL_WINDOW_SIZE * PIXEL_WINDOW_SIZE);
                        
                finalDifference = avgDelta;
                if finalDifference < 50; % theshhold determined experimentally
                    finalDifference = 0;
                end
                
                deltaFrame(m,n,1) = finalDifference;
                deltaFrame(m,n,2) = finalDifference;
                deltaFrame(m,n,3) = finalDifference;  
                if finalDifference == 0
                    deltaFrame(m,n,3) = 124; % blue
                else
                    
                    % center of mass power 1
                    fishCenterOfMassX = fishCenterOfMassX + n * finalDifference;
                    sumMassX = sumMassX + finalDifference;
                
                    fishCenterOfMassY = fishCenterOfMassY + m * finalDifference;
                    sumMassY = sumMassY + finalDifference;
                    
                    % center of mas power 2
                    fishCenterOfMass2X = fishCenterOfMass2X + n * finalDifference * finalDifference;
                    sumMass2X = sumMass2X + finalDifference * finalDifference;
                
                    fishCenterOfMass2Y = fishCenterOfMass2Y + m * finalDifference * finalDifference;
                    sumMass2Y = sumMass2Y + finalDifference * finalDifference;
                end
                
                
            end
        end			        
        
        fishCenterOfMassX = uint16(fishCenterOfMassX / sumMassX);
        fishCenterOfMassY = uint16(fishCenterOfMassY / sumMassY);
        
        fishCenterOfMass2X = uint16(fishCenterOfMass2X / sumMass2X);
        fishCenterOfMass2Y = uint16(fishCenterOfMass2Y / sumMass2Y);
        
        %
        ct = oVideo.CurrentTime;
        if (fishCenterOfMassX ~= 0 && fishCenterOfMassX ~= 0)
            fprintf('%s frame %ss, fish position: x=%s, y=%s\n', videoName, strrep(sprintf('%5.2f', ct), ' ', '0'), sprintf('%02d', fishCenterOfMassX), sprintf('%02d', fishCenterOfMassY));
            fprintf(out,'%s, %s, %s\r\n', strrep(sprintf('%5.2f', ct), ' ', '0'), sprintf('%02d', fishCenterOfMassX), sprintf('%02d', fishCenterOfMassY));
        else
            fprintf('%s frame %ss, fish position: no location\n', videoName, strrep(sprintf('%5.2f', ct), ' ', '0') );
            fprintf(out,'%s, no location, no location\r\n', strrep(sprintf('%5.2f', ct), ' ', '0'));
        end

        %
        fishPositionsJpg(m,n,1) = 0;
        fishPositionsJpg(m,n,2) = 0;
        fishPositionsJpg(m,n,3) = 128;
        
        %
        if (fishCenterOfMassX > 0 && fishCenterOfMassY > 0)
            
            %
            time_fishtracking = time_fishtracking + oVideo.CurrentTime - previous_time;
            
            currentSide = sign(double(fishCenterOfMass2X) - double(minXplayground) - double(playgroundWidth / 2));
            previousSide = sign(double(previous_fish_positionX) - double(minXplayground) - double(playgroundWidth / 2));
            if currentSide == -1 && previousSide == -1 
           
                time_spent_in_black = time_spent_in_black + oVideo.CurrentTime - previous_time;
                
            elseif currentSide ~= previousSide
                
                time_spent_in_black = time_spent_in_black + (oVideo.CurrentTime - previous_time) / 2;
                
            end
            
            % fish center of mass 2 (yellow square)
            for i = -3:3
                for j = -3:3
                    m = fishCenterOfMass2Y + j;
                    n = fishCenterOfMass2X + i;
     
                    currentFrame(m,n,1) = 255;
                    currentFrame(m,n,2) = 255;
                    currentFrame(m,n,3) = 0;

                    deltaFrame(m,n,1) = 255;
                    deltaFrame(m,n,2) = 255;
                    deltaFrame(m,n,3) = 0;
                    
                    fishPositionsJpg(m,n,1) = 255;
                    fishPositionsJpg(m,n,2) = 255;
                    fishPositionsJpg(m,n,3) = 0;
                end
            end
            
            % fish center of mass (red cross)
            for i = -4:4
                for j = -4:4
                    if i == 0 || j == 0
                        m = fishCenterOfMassY + j;
                        n = fishCenterOfMassX + i;
     
                        currentFrame(m,n,1) = 255;
                        currentFrame(m,n,2) = 0;
                        currentFrame(m,n,3) = 0;
                        
                        deltaFrame(m,n,1) = 255;
                        deltaFrame(m,n,2) = 0;
                        deltaFrame(m,n,3) = 0;
                    end
                end
            end            
            
        end
        
        %
        previous_fish_positionX = fishCenterOfMass2X;
        previous_time = oVideo.CurrentTime;
              
        %
        filename = strcat('.\result\', videoName, '\FishWithoutBackground\frame_', strrep(strrep(sprintf('%6.3f', ct), ' ', '0'), '.','s_'), 'ms.jpg');
        imwrite(deltaFrame,filename);
        
        %
        filename = strcat('.\result\', videoName, '\FishPositions\frame_', strrep(strrep(sprintf('%6.3f', ct), ' ', '0'), '.','s_'), 'ms.jpg');
        imwrite(currentFrame,filename);

        % filename = strcat('.\backgroundFrames\backgroundFrame', sprintf('%03d',k), '.jpg');
        % imwrite(backgroundFrame,filename);
        
        writeVideo(videoOutput, currentFrame);
    end
    
    %
    k = k + 1;
end

close(videoOutput);

%
filename = strcat('.\result\', videoName, '\fishPositions.jpg');
imwrite(fishPositionsJpg,filename);

% -- end -----------------------------------------------
fprintf(    'time spent in black %ss, time spent in white %ss, total tracking time %ss\n', sprintf('%0.2f', time_spent_in_black), sprintf('%0.2f', time_fishtracking - time_spent_in_black), sprintf('%0.2f', time_fishtracking));
fprintf('number of frames processed: %s\n', num2str(k));
fprintf(out,'\r\ntime spent in black %ss\r\n time spent in white %ss\r\n total tracking time %ss\r\nnumber of frames processed %s\r\n', sprintf('%0.2f', time_spent_in_black), sprintf('%0.2f', time_fishtracking - time_spent_in_black), sprintf('%0.2f', time_fishtracking), num2str(k));
fclose(out);
% ------------------------------------------------------
