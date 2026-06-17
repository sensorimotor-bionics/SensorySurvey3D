function electrodeText = getEText(bText)
% This function gets the text used for the button in the annotation viewer
% and gives back the set of electrodes.

    c_max = 4; % max number of channels, make sure this aligns with other parts
    channels = zeros(c_max,1);

    % Takes care of case when all electrodes are consolidated
    if bText(1) ~= '['
        channels(1) = 10000;
        splitText = split(bText,'/');
        channels(3) = str2num(splitText{1});
        splitText2 = split(splitText{2},' ');
        channels(2) = str2num(splitText2{1});
    % Standard electrode set
    else
        bText(bText=='[') = '';
        bText(bText==']') = '';
        elecNums = split(bText,' ');
        
        for i = 1:length(elecNums)
            channels(i) = str2num(elecNums{i});
        end
    end
    electrodeText = sprintf('e_%d_%d_%d_%d',channels(1),channels(2),channels(3),channels(4));
end