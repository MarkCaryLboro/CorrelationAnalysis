classdef rateTest < correlationModel
    
    properties ( Constant = true )
        ModelName   string                                  = "rateTest"    % Name of model
    end % constant properties
    
    properties ( SetAccess = protected )
        Reps        int8                                    = 3             % Number of replicates
    end % prootected properties
    
    methods
        function obj = rateTest(  )
            %--------------------------------------------------------------
            % 
        end
        
        function A = basis( obj, Reps ) 
            %--------------------------------------------------------------
            % Generate basis function matrix    
            %
            % A = obj.basis( Reps );
            % Input Arguments:
            %
            % Reps  --> Number of replicates
            %--------------------------------------------------------------
        end % basis
        
        function obj = fitModel( obj ) 
            %--------------------------------------------------------------
            % Perform the required repeated measurments analysis
            %--------------------------------------------------------------
        end % fitModel
    end % Ordinary and constructor methds
    
end % rateTest