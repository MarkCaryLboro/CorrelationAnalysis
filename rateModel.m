classdef rateModel < correlationModel
    
    properties ( Constant = true )
        ModelName   string                  = "Rate"                        % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties  
    
    properties ( SetAccess = protected )
        MleObj      mle                                                     % MLE analysis object
        Model       supportedModelType                      = "linear "     % Facility model terms
    end % protected properties    
    
    methods
        function obj = rateModel( DesignObj )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = rateModel( DesignObj )
            %
            % Input Arguments:
            %
            % DesginObj     --> rateDesign object
            %--------------------------------------------------------------
            arguments
                DesignObj   (1,1)   rateDesign  { mustBeNonempty( DesignObj ) }
            end
            obj.Design = DesignObj;
        end % constructor
        
        function obj = defineModel( obj )
        end % defineModel
        
        function obj = fitModel( obj )
        end % fitModel
        
        function X = basis( obj, A )
        end % basis
    end % Constructor and ordinary methods
end % rateModel