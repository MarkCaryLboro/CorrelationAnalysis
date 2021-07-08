classdef rateTest < correlationModel
    
    properties ( SetAccess = immutable )
        Design      correlationDesign                                       % Design object
    end % immutable properties
    
    properties ( Constant = true )
        ModelName   string                                  = "rateTest"    % Name of model
    end % constant properties
    
    properties ( SetAccess = protected )
        MleObj      mle                                                     % MLE analysis object
        Model       supportedModelType                      = "linear "     % Facility model terms
    end % protected properties
    
    methods
        function obj = rateTest( DesignObj )
            %--------------------------------------------------------------
            % Construct a rateTest analysis object for analysing data for
            % the battery facility correlation experiment "Rate Test".
            %
            % obj = rateTest( DesignObj );
            %
            % Input Arguments:
            %
            % DesignObj     --> rateDesign object
            %--------------------------------------------------------------
            if ( nargin < 1 ) || ~isa( DesignObj, 'rateDesign' )
                error('Must supply a "rateDesign" object to the class constructor');
            else
                obj.Design = DesignObj;
            end
        end
        
        function A = basis( obj, Reps ) 
            %--------------------------------------------------------------
            % Generate basis function matrix    
            %
            % A = obj.basis( Reps );
            % Input Arguments:
            %
            % Reps  --> Number of replicates { obj.Reps }
            %--------------------------------------------------------------
        end % basis
        
        function obj = fitModel( obj ) 
            %--------------------------------------------------------------
            % Perform the required repeated measurments analysis
            %--------------------------------------------------------------
        end % fitModel
        
        function obj = defineModel( obj, Model )
            %--------------------------------------------------------------
            % Define the experimental model
            %
            % obj = obj.defineModel( Model );
            %
            % Input Arguments:
            %
            % Model     --> (string) Facility model type, either {"linear"}
            %               or "interaction"
            %--------------------------------------------------------------
        end % defineModel
    end % Ordinary and constructor methds
    
end % rateTest