classdef pulseModel < correlationModel
    % Pulse facility correlation test level-2 model class
    
    properties
        Facility    (1,1)             string        = "Facility"            % Facility variable
    end % public properties
    
    properties ( Constant = true )
        ModelName   string                          = "Rate"                % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties     
    
    methods
        function obj = pulseModel( DesignObj, MleObj, ModelType )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = pulseModel( DesignObj, Algorithm, ModelType )
            %
            % Input Arguments:
            %
            % DesginObj     --> rateDesign object
            % Algorithm     --> algorithm type. Must be an mleAlgorithms
            %                   object
            % ModelType     --> Model type either: {"linear"},
            %                   "interaction", "quadratic" or "complete"
            %--------------------------------------------------------------
            arguments
                DesignObj   (1,1)   rateDesign          { mustBeNonempty( DesignObj ) }
                MleObj      (1,1)   mleAlgorithms       { mustBeNonempty( MleObj ) }    = "EM"; 
                ModelType   (1,1)   string              = "linear"
            end
            obj.Design = DesignObj;
            if ( nargin < 2 ) || ~ismember( upper( MleObj ), [ "EM", "IGLS", "MLE" ] )
                MleObj = "em";
            end
            switch mleAlgorithms( MleObj )
                case "EM"
                    obj.MleObj = em();
                case "IGLS"
                    obj.MleObj = igls();
                otherwise
            end
            obj = obj.setModel( ModelType );
            obj = obj.setModelSyms();
        end % constructor
    end % constructor and ordinary methods
end % classdef