classdef capacityTest < correlationModel
    
    
    properties ( Constant = true )
        ModelName   string                              = "capacityTest"    % Name of model
    end % constant properties
    
    methods
        
        function A = basis( obj, Levels ) 
            %--------------------------------------------------------------
            % Generate basis function matrix    
            %
            % Input Arguments:
            %
            % Levels    --> Factor levels
            %--------------------------------------------------------------
        end % basis
        
        function obj = fitModel( obj ) 
            %--------------------------------------------------------------
            % Perform the required repeated measurments analysis
            %--------------------------------------------------------------
        end % fitModel        
    end % constructor and ordinary methods
end % capacityTest