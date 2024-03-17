%%% 
% Function which designs Gamma_m filter and then perform zero-phased 
% filtering on the signal. Designed filters are cached for optimal speed 
% in loops.
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%
% @param    x      Signal vector
% @param    sr     Sampling Rate (SR)
%

function y = filterGammaMid(x, sr)

    persistent d  srCache
    if isempty(d) || srCache ~= sr
        d = designfilt('bandpassfir', ...       % Response type
           'StopbandFrequency1',52-8, ...    % A little before the range start
           'PassbandFrequency1',52-2, ...      % The range start
           'PassbandFrequency2',90+2, ...     % The range end
           'StopbandFrequency2',90+8, ...   % A little after the range end
           'DesignMethod','equiripple', ...         % Design method
            'PassbandRipple',0.001, ...
            'StopbandAttenuation1',80, ...  % The range start
            'StopbandAttenuation2',80, ...
           'SampleRate',sr);               % Sample rate
       srCache = sr;
    end
    
%     fvtool(d);
    
    y = filtfilt(d, x);

end