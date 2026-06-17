function bText = getBText(electrodeText)
% This function gets the set of electrodes and gives the text used for the
% button in the annotation viewer.
    splitText = string(split(electrodeText,'_'));   
    numText = splitText(2:end);
    % Takes care of case when all electrodes are consolidated
    if numText(1) == "10000"
        bText = sprintf('%s/%s electrodes',numText(3),numText(2));
    % Standard electrode set
    else
        nonZero = numText(numText~='0');
        bText = '[' + strjoin(nonZero) + ']';
    end
end