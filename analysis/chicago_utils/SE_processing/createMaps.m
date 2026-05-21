function Survey3DDataRecord = createMaps(Survey3DData)

    Survey3DDataRecord = Survey3DData;
    qualities = fieldnames(Survey3DData(1).PFQualities);

    for d = 1:length(Survey3DData)
        if Survey3DData(d).NumSense == 0
            binaryMap = 'No_Report';
            binaryQualities = 'No_Report';   
        else
            binaryMap = zeros(size(Survey3DData(d).Model.vertices,1),1);
            binaryQualities = struct();

            for q = 1:length(qualities) 
                binaryQualities.(qualities{q}) = zeros(size(Survey3DData(d).Model.vertices,1),1);
            end
            
            for ns = 1:Survey3DData(d).NumSense
                for q = 1:length(qualities) 
                    if (~isempty(Survey3DData(d).PFQualities(ns).(qualities{q})))
                        binaryMap = binaryMap + Survey3DData(d).PFBasics(ns).fields;
                        binaryQualities.(qualities{q}) = binaryQualities.(qualities{q}) + Survey3DData(d).PFBasics(ns).fields;
                    end
                    %binaryQualities = binaryQualities + Survey3DData(d).PFBasics(ns).fields;
                end              
            end
            binaryMap(binaryMap>0) = 1;
            for q = 1:length(qualities) 
                binaryQualities.(qualities{q})(binaryQualities.(qualities{q})>0) = 1;
            end
        end
        Survey3DDataRecord(d).binaryMap = binaryMap;
        Survey3DDataRecord(d).binaryQualities = binaryQualities;
    end

end