classdef correlationAnalysis
    % A class to analyse the data from the correlation experiment to assess
    % the equivalency of different battery test facilities
    
    properties ( SetAccess = protected )
        DataObj     (1,1)           { mustBeDataObj( DataObj ) }            % Data object                      
        DesignObj   (1,1)           { mustBeDesignObj( DesignObj ) }        % Design object
        ModelObj    (1,1)           { mustBeModelObj( ModelObj ) }          % Model to be fitted
        ReportObj   (1,1)           { mustBeReportObj( ReportObj ) }        % Report generator
    end
    
    methods
        function obj = correlationAnalysis( DataObj, DesignObj, ModelObj, ReportObj )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = correlatioAnalysis( DataObj, DesignObj, ModelObj,...
            %                           ReportObj );
            %
            % Input Arguments:
            %
            % DataObj       --> Correlation DataStore object
            % DesignObj     --> Correlation Design object
            % ModelObj      --> Correlation Model Object
            % ReportObj     --> Correlation analysis report object
            %--------------------------------------------------------------
            
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

function mustBeDataObj( DataObj )
    %----------------------------------------------------------------------
    % Validation function for DataObj argument
    %----------------------------------------------------------------------
    
end % mustBeDataObj