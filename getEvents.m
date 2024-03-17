%%% 
% Function that detects the ranges of signal containing oscillation events 
% exceeding the mean plus *n* times of the signal's standard deviation, 
% and returns them.
% 
% @author   Mehran Ahadi
% @see      LICENSE for more information.
%
% @param    data        Signal vector
% @param    STD_Multip  How many times above STD?
% @param    rlen        Length needed for ranges
% @param    rmin        Minimum event length to consider as valid event
% @param    onlyMiddle  Boolean to return middle part of event (not whole)
%

function [ret] = getEvents(dat, STD_Multip, rlen, rmin, onlyMiddle)
    
    ret = [];

    % Compute Envelope
    hy = hilbert(dat);
    env = abs(hy);
    
    areavec = (env > mean(env)+STD_Multip*std(env))';
    
    % Find rising and falling edges
    ind1 = find(diff([0 areavec])==1);
    ind2 = find(diff([areavec 0])==-1);
    
    lengths = ind2-ind1;
    
    
    for Iw = 1:length(lengths)
        % Remove events with a duration smaller than rmin samples, or
        % events not having rlen points around them, i.e. head and tail of
        % the signal.
        if lengths(Iw) < rmin || ind1(Iw) < rlen || ind2(Iw) > length(dat)-rlen
            areavec(ind1(Iw):ind2(Iw)) = 0;
        else
            if onlyMiddle
                % If only the middle rlen points of the event are needed
                MidPoint = ind1(Iw) + round((ind2(Iw)-ind1(Iw))/2);
                ret = [ret; [MidPoint-rlen, MidPoint+rlen]];
            else
                % If the whole event is needed (Warning: variable-sized ranges)
                ret = [ret; [ind1(Iw), ind2(Iw)]];
            end
        end
    end
end