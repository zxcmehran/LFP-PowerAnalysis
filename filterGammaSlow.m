%%% 
% Function which designs Gamma_s filter and then perform zero-phased 
% filtering on the signal. Designed filters are cached for optimal speed 
% in loops.
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%
% @param    x      Signal vector
% @param    sr     Sampling Rate (SR)
%

function y = filterGammaSlow(x, sr)

    persistent d  srCache
    if isempty(d) || srCache ~= sr
        d = designfilt('bandpassfir', ...       % Response type
           'StopbandFrequency1',30-8, ...    % A little before the range start
           'PassbandFrequency1',30-2, ...      % The range start
           'PassbandFrequency2',47+2, ...     % The range end
           'StopbandFrequency2',47+8, ...   % A little after the range end
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