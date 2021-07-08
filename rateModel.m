classdef rateModel < correlationModel
    
    properties ( Constant = true )
        ModelName   string                  = "Rate"                        % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties  
    
    properties ( SetAccess = protected )
        MleObj      mle                                                     % MLE analysis object
        Model       supportedModelType                      = "linear"      % Facility model terms
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
        
        function A = basis( obj, X ) 
            %--------------------------------------------------------------
            % Generate basis function matrix    
            %
            % A = obj.basis( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data table in coded units
            %--------------------------------------------------------------
            arguments
                obj     (1,1)       rateModel
                X       (:,:)       double          { mustBeNonempty( X ),...
                                                      mustBeNumeric( X ),...
                                                      mustBeReal( X ) }
            end
            Quad = obj.quadTerms( X );
            Int = obj.interactionTerms( X );
            switch obj.Model
                case "interaction"
                    Fint = obj.facilityIntTerms( X );
                otherwise
                    Fint = double.empty( size( X, 1 ), 0 );
            end
            A = [ ones( size( X, 1 ) ), X, Quad, Int, Fint ];
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
            if ( nargin < 2 )
                Model = "linear";
            else
                Model = lower( Model );
            end
            obj.Model = supportedModelType( Model );
        end % defineModel
    end % Constructor and ordinary methods
    
    methods
    end % get/set methods
    
    methods ( Access = private )
        function Q = quadTerms( obj, X )
            %--------------------------------------------------------------
            % Return matrix of quadratic terms if a continuous factor has 3
            % or more levels.
            %
            % Q = obj.quadTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data table in coded units
            %--------------------------------------------------------------
            Cont = ( obj.Design.Factor.Type == "CONTINUOUS" ).';
        end
    end
end % rateModel