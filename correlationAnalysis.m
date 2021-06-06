classdef correlationAnalysis
    % A class to analyse the data from the correlation experiment to assess
    % the equivalency of different battery test facilities
    
    properties ( SetAccess = protected )
        DataObj     (1,1)                                                   % Data object                      
        DesignObj   (1,1)                                                   % Design object
        ModelObj    (1,1)                                                   % Model to be fitted
        ReportObj   (1,1)                                                   % Report generator
    end
    
    methods
        function obj = correlationAnalysis( DataObj, DesignObj, ModelObj, ReportObj )
        end % constructor
        
        function Ok = matchDesign( obj )
            %--------------------------------------------------------------
            % Match the data to the design.... return true (false ) if
            % matched ( not matched ).
            %
            % Ok = obj.matchDesign();
            %--------------------------------------------------------------
        end % matchDesign
    end
end

