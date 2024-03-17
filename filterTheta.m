%%% 
% Function which designs Theta filter and then perform zero-phased 
% filtering on the signal. Designed filters are cached for optimal speed 
% in loops.
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%
% @param    x      Signal vector
% @param    sr     Sampling Rate (SR)
%

function y = filterTheta(x, sr)

    persistent d  srCache
    if isempty(d) || srCache ~= sr
        d = designfilt('bandpassfir', ...       % Response type
           'StopbandFrequency1',3, ...    % A little before the range start
           'PassbandFrequency1',4, ...      % The range start
           'PassbandFrequency2',12, ...     % The range end
           'StopbandFrequency2',18, ...   % A little after the range end
           'DesignMethod','equiripple', ...         % Design method
            'PassbandRipple',0.001, ...
            'StopbandAttenuation1',25, ...  % The range start
            'StopbandAttenuation2',25, ...
           'SampleRate',sr);               % Sample rate
       srCache = sr;
    end
    
%     fvtool(d);
    
    y = filtfilt(d, x);

end