function bText = getBText(electrodeText)
    splitText = string(split(electrodeText,'_'));
    numText = splitText(2:end);
    nonZero = numText(numText~='0');
    bText = '[' + strjoin(nonZero) + ']';
end