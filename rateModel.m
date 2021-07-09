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
        function I = interactionTerms( obj, X )
            %--------------------------------------------------------------
            % Return continuous interaction terms
            %
            % I = obj.interactionTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %--------------------------------------------------------------
            Cont = ( obj.Design.Factor.Type == "CONTINUOUS" ).';
            X = X( :, Cont );
            [ N, C ] = size( X );
            Nint = factorial( C )/ factorial( 2 )/factorial( C - 2 );
            I = zeros( N, Nint );
            K = 0;
            for Q = 1:( C - 1 )
                for R = ( Q + 1 ):C
                    K = K + 1;
                    I( :, K ) = X( :, Q ).*X( :, R );
                end
            end
        end % interactionTerms
        
        function Q = quadTerms( obj, X )
            %--------------------------------------------------------------
            % Return matrix of quadratic terms if a continuous factor has 3
            % or more levels.
            %
            % Q = obj.quadTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %--------------------------------------------------------------
            Cont = ( obj.Design.Factor.Type == "CONTINUOUS" ).';
            Cont = Cont & ( obj.Design.Factor.NumLevels.' > 2 );
            Q = X( :, Cont ).^2;
        end
    end
end % rateModel