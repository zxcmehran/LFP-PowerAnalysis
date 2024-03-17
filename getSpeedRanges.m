%%% 
% Function that calculates the movement speed of subject based on the 
% optical quadrature encoder signal, and then returns the ranges of signal 
% where speed matches the required criterion.
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%
% @param    t               Time vector
% @param    dat             Signal vector
% @param    sr              Sampling rate
% @param    speedLimit      Speed limit of interest
% @param    isGetHigher     Higher or lower of the limit is needed?
% @param    minBinSize      Minimum running/steady event length
%
% @return   ranges          Detected ranges
% @return   maskTotal       Mask of detected ranges
% @return   rangesPlot      Reference to debug plot, if available
%

function [ranges, maskTotal, rangesPlot] = getSpeedRanges(t, dat, sr, speedLimit, isGetHigher, minBinSize)
    isDebug = false;

    averageWindow = 1 * sr; % Averaging window used for speed calculation
    totalL = 24.19; % Distance traveled on each rotation in cm
    totalCount = 500; % Number of pulses in the signal representing a complete 360d rotation

    [crx,~] = midcross(dat, sr);
    Lt = (1:length(crx)) .* (totalL / totalCount);
    Lti = interp1(crx, Lt, t, 'linear', 'extrap');

    %% Speed calculation
    % average window x1 and x2
    wx1 = 1:(length(t)-averageWindow);
    wx2 = averageWindow+1:length(t);

    dL = Lti(wx2) - Lti(wx1);
    dt = averageWindow / sr;

    vAvg = dL/dt; % cm/s
    
    rangesPlot = [];
    if isDebug
        rangesPlot = figure();
        plot(t(wx2), vAvg);
        hold on;
        
        xlabel("Time (s)");
        ylabel("Speed (cm/s)");
        title("Averaged over "+(averageWindow/sr)+" seconds");
    end
    
%     vAvg(isnan(vAvg)) = 0;

    
    %% Cutting signal based on speed range

    % CHOOSE ONE:
    % Option 1. Between x and y
    % mask1 = vAvg > 5;
    % mask2 = vAvg < 7;
    % maskTotal = mask1 & mask2;

    if isGetHigher
        % Option 2. Higher than x
        maskTotal = vAvg > speedLimit;
    else
        % Option 3. lower than x
        maskTotal = vAvg <= speedLimit;
    end

    ranges = [];
    % Accept the time windows when it stays x seconds in the defined range. 
    % Otherwise discard the part.
    xseconds = minBinSize; % How many seconds
    xsamples = sr * xseconds;
    edges = diff(maskTotal);
    
    if maskTotal(1) == 1 && maskTotal(2) == 1
        edges(1) = 1;
    end
    
    if maskTotal(end) == 1 && maskTotal(end-1) == 1
        edges(end) = -1;
    end
    
    startT = 0;
    k = 1;
    for i=1:length(edges)-1
        if edges(i) == 0
            continue;
        elseif edges(i) == 1 % Rising edge: When it enters a section accepted by the mask
            startT = i;
        elseif startT~=0  % Falling edge: When it leaves the section, e.g. edges(i) == -1
            if i - startT < xsamples % If it is shorter than xseconds ...
                maskTotal((startT+1):i) = 0; % ... exclude this area from the mask.
            else % IT IS GOOD
                pair = [startT i];
                    
                if isDebug
                    plot(linspace(t(pair(1)), t(pair(2)), 100), ones(1, 100)*speedLimit, "LineWidth", 3);
                    text(t(pair(1)), speedLimit+0.5, string(k));
                end
                
                ranges = [ranges; pair];
                k = k + 1;
            end
            startT = 0;
        end
    end

end