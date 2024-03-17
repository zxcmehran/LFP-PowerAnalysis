%%% 
% Function for downsampling vectors. It calculates the needed downsampling 
% ratio and iterations count to efficiently deliver the asked sampling 
% rate. It also takes care of anti-aliasing filtering before downsampling. 
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
% 
% @param    SampleFreq          Original Sampling Rate (SR)
% @param    xq                  Time vector
% @param    yq                  Signal vector
% @param    toSampleFreq        Target needed SR
% @param    skipSecs            Skip n seconds if needed
% @param    onlyRealDivision    Boolean on if should avoid fractional SRs.
%
% @return   newSampleFreq       New SR after downsampling
% @return   xq2                 Downsampled time vector
% @return   yq2                 Downsampled signal vector
%

function [newSampleFreq, xq2, yq2] = downsampleData(SampleFreq, xq, yq, toSampleFreq, skipSecs, onlyRealDivision)

    if ~ exist('onlyRealDivision', 'var')
        onlyRealDivision = false;
    end
    
    xdsF = 1;
    
    if skipSecs > 0
        xq = xq(SampleFreq*skipSecs +1 :end);
        yq = yq(SampleFreq*skipSecs +1 :end);
    end
    
    yq = yq - mean(yq);
    
    tabl = zeros(10,5);
    for i=1:10
        for j=1:5
            xx = i^j;
            if xx <= SampleFreq/toSampleFreq && (~onlyRealDivision || mod(SampleFreq, xx) == 0)
                tabl(i,j) = xx;
            else
                tabl(i,j) = NaN;
            end
        end
    end
    
    [M, I] = max(tabl);
    [~, I2] = max(M);
    I = I(I2);
    downsampler = I;
    dsMultip = I2;
    
    dsF = downsampler;
    for i=1:dsMultip
        
        xdsF = xdsF * dsF;
        f = SampleFreq / dsF / 2;

        d = designfilt('lowpassfir', ...
        'PassbandFrequency',0.8*f,'StopbandFrequency',1*f, ...
        'PassbandRipple',0.0001,'StopbandAttenuation',40, ...
        'DesignMethod','equiripple','SampleRate',SampleFreq);

        del = grpdelay(d);
        yq = [yq; zeros(ceil(del(1)), 1)];
        yq = filter(d, yq);
        yq = yq(1+ceil(del(1)):end);
        yq = downsample(yq, dsF);
        SampleFreq = SampleFreq / dsF;
    end

    xq = downsample(xq, xdsF);
    
    newSampleFreq = SampleFreq;
    xq2 = xq;
    yq2 = yq;
end