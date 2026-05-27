function electrodeText = getEText(bText)
    c_max = 4; % max number of channels, make sure this aligns with other parts
    channels = zeros(c_max,1);

    bText(bText=='[') = '';
    bText(bText==']') = '';
    elecNums = split(bText,' ');
    
    for i = 1:length(elecNums)
        channels(i) = str2num(elecNums{i});
    end

    electrodeText = sprintf('e_%d_%d_%d_%d',channels(1),channels(2),channels(3),channels(4));
end