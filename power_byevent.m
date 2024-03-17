%%% 
% Gamma_s and Gamma_m power analysis based on detected events
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%

clear;
close all;

% Set speed limit to cut by
speedLimit = 5;
isGetHigher = true;

% Set length of time slot to cut signal
minBinSize = 10; % second

doNormalize = 1; % z-score

datasetDir = "./dataset/";
outputDirPrefix = "./Output_PowerByEvent_"+datestr(datetime('now'), 'yyyymmdd_HHMM')+"/";

excelName = datestr(datetime('now'), 'yyyymmdd_HHMM')+".xlsx";

filetable = readtable("datasetmap.xlsx");

sr_ = 10000; % abf file sample rate

filterFuncTitles = ["GammaSlow", "GammaMid"];
filterFuncDisplayRanges = [[20 55]; [45 100];]; % used for plotting, not filtering

filterFuncs = [ ...
    {@(x,sr) filterGammaSlow(x, sr)}, ...
    {@(x,sr) filterGammaMid(x, sr)}, ...
];

excelOutHeader = ["MouseID", "RecordingIndex", "IsCtl", "FolderID", "FileName", ...
    "GammaSlowMaxPowF", "GammaSlowMaxPow", ...
    "GammaMidMaxPowF", "GammaMidMaxPow", ...
];

excelOut = [];

mkdir(outputDirPrefix);

fileID = fopen(outputDirPrefix+'config.txt','w');
fprintf(fileID, 'Speed Limit: %d cm/s\n', speedLimit);
if isGetHigher 
    higherWord = "higher";
else
    higherWord = "lower";
end
fprintf(fileID, 'Is get higher than Speed Limit? %s\n', higherWord);
fprintf(fileID, 'Min bin size: %d secs\n', minBinSize);
fprintf(fileID, 'Is Z-score normalized? %d\n', doNormalize);
fclose(fileID);

for i=1:height(filetable)

    filepath = datasetDir+filetable{i,"FolderID"}+"/"+filetable{i,"FileName"}+".abf";
    
    abfdata = abfload(filepath);
    
    dat_ = abfdata(:,1); % dataset
    movementSig_ = abfdata(:, 3);
    
    
    startTime = filetable{i,"StartTime"};
    endTime = filetable{i,"EndTime"};
    
    if isnan(startTime)
        startTime = 1;
    end
    
    if isnan(endTime)
        dat_= dat_(floor(startTime*sr_):end);
        movementSig_ = movementSig_(floor(startTime*sr_):end);
    else
        dat_= dat_(floor(startTime*sr_):floor(endTime*sr_));
        movementSig_ = movementSig_(floor(startTime*sr_):floor(endTime*sr_));
    end
    
    
    t_ = (0:(length(dat_)-1)) / sr_; % time vector
    
    dat_ = dat_ - mean(dat_);
    [sr, t, dat] = downsampleData(sr_, t_, dat_, 1000, 0, true);
    
    movementSig = downsample(movementSig_, sr_/sr);
    
    if doNormalize
        dat = (dat - mean(dat)) / std(dat);
    end
    
    % Get chosen speed ranges
    [ranges, ~, rangesPlot] = getSpeedRanges(t, movementSig, sr, speedLimit, isGetHigher, minBinSize);
    
    excelSubOut = [];
       
    for filtI = 1:length(filterFuncs)
        
        fprintf("Datafile %d of %d - Filtering %d of %d\n", i, height(filetable), filtI, length(filterFuncs));
        
        if size(ranges, 1) == 0 
            excelSubOut = repmat(["N/A"], [1 length(filterFuncs)*2]); % if no ranges found
            break;
        end
        
        filtFunc = filterFuncs{filtI};
        
        datFiltered = filtFunc(dat, sr);
    
        powAvg = 0;
        powAvgCount = 0;
        
        
        for j=1:size(ranges, 1)

            % boolean condition: t_vec >= t_low & t_vec <= t_high
            t_cut = t(t >= t(ranges(j,1)) & t <= t(ranges(j,2)));
            dat_cut = datFiltered(t >= t(ranges(j,1)) & t <= t(ranges(j,2)));

            eventLen = 0.2 * sr;
            datEvents = getEvents(dat_cut, 3, ceil(eventLen), ceil(0.0125 * sr), true);
            
            if size(datEvents) == 0
                continue;
            end
            
            for k=1:size(datEvents)
            
                dat_ecut = dat_cut(datEvents(k,1):datEvents(k,2));
                dat_ecut = dat_ecut - mean(dat_ecut);

                [powY, powX] = pwelch(dat_ecut, ceil(1*eventLen), ceil(0.1*eventLen), ceil(eventLen*10), sr);
                powAvg = powAvg + powY;
                powAvgCount = powAvgCount + 1;
            end
        end

        if powAvgCount > 0
            powAvg = powAvg / powAvgCount;
        end

        [powMax, powMaxI] = max(powAvg);
        powMaxF = powX(powMaxI);


        iFilenameDir = "Mouse"+filetable{i,"MouseID"}+"/";
        mkdir(outputDirPrefix + iFilenameDir);

        if filetable{i, "isCtl"}
            iFilename = "Mouse"+filetable{i,"MouseID"}+"_Ctl_"+filterFuncTitles(filtI);
        else
            iFilename = "Mouse"+filetable{i,"MouseID"}+"_CNO_"+filterFuncTitles(filtI);
        end

        iFilename = iFilename+filetable{i, "RecordingIndex"};
        iFilenameRaw = iFilename;
        iFilename = outputDirPrefix + iFilenameDir + iFilename;

        if powAvg ~=0
            dataToSave = [powX powAvg];
        else
            dataToSave = [];
        end
        
        save(iFilename+".mat", "dataToSave");
        if ~isempty(dataToSave)
            writetable(array2table(dataToSave, 'VariableNames', ["Freq(Hz)" "Power"]), iFilename+".xlsx");
        else
            writematrix(["Freq(Hz)" "Power"], iFilename+".xlsx");
        end

        plotfig = figure();
        plot(powX, powAvg);
        
        xlim(filterFuncDisplayRanges(filtI, :));
        
        title({iFilenameRaw, "Averaged Power of cuts "+higherWord+" than "+speedLimit+" cm/s", "Max: "+powMax+" on "+powMaxF+" Hz"}, "Interpreter", "none");

        saveas(plotfig, iFilename+".png");
        saveas(plotfig, iFilename+".fig");

        close all;

        excelSubOut = [excelSubOut powMaxF powMax];
    end
    
    excelOut = [excelOut; filetable{i, "MouseID"} filetable{i, "RecordingIndex"} filetable{i, "isCtl"} filetable{i, "FolderID"} filetable{i, "FileName"} num2cell(excelSubOut)];
    
end

writetable(cell2table(excelOut, 'VariableNames', excelOutHeader), outputDirPrefix+excelName);
