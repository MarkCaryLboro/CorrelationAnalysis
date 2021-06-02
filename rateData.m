classdef rateData < correlationDataStore
    
    properties ( SetAccess = immutable )
        TestName            allowableTestTypes                    
    end % immutable propertie
    
    methods
        function obj = rateData()
            %--------------------------------------------------------------
            % Creates a rateData object for holding data from the "rate"
            % test for the battery test facility correlation analysis
            %
            % obj = rateData( Source );
            %
            % Input Arguments:
            %
            % Source    --> Context correlationDataStore object
            %--------------------------------------------------------------
        end % constructor
    
    end % constructor and ordinary methods
end % rateData