classdef rateModel < correlationModel
    
    properties
        Facility    (1,1)             string      = "Facility"              % Facility variable
    end % public properties
    
    properties ( Constant = true )
        ModelName   string                  = "Rate"                        % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties  
    
    properties ( SetAccess = protected )
        MleObj      	                                                    % MLE analysis object
        Model       supportedModelType                      = "linear"      % Facility model terms
    end % protected properties    
    
    methods
        function obj = rateModel( DesignObj, MleObj )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = rateModel( DesignObj, MleObj )
            %
            % Input Arguments:
            %
            % DesginObj     --> rateDesign object
            % MleObj        --> Maximum likelihood estimation object
            %--------------------------------------------------------------
            arguments
                DesignObj   (1,1)   rateDesign          { mustBeNonempty( DesignObj ) }
                MleObj      (1,1)   mleAlgorithms       { mustBeNonempty( MleObj ) }    = "em";           
            end
            obj.Design = DesignObj;
            if ( nargin < 2 ) || ~ismember( A, [ "EM", "IGLS", "MLE" ] )
                MleObj = "em";
            end
            switch mleAlgorithms( MleObj )
                case "EM"
                    obj.MleObj = em();
                case "IGLS"
                    obj.MleObj = igls();
                otherwise
            end
        end % constructor
        
        function obj = setModel( obj, ModelStr )
            %--------------------------------------------------------------
            % Set the facility interaction model type to either "linear" or
            % "interaction".
            %
            % obj = obj.setModel( ModelStr );
            %
            % Input Arguments:
            %
            % ModelStr  --> (string) Required model, either "linear" or
            %               "interaction".
            %--------------------------------------------------------------
            try
                obj.Model = ModelStr;
            catch
                warning('Property "Model" not changed');
            end
        end % setModel
            
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
            [ Quad, IxQ ] = obj.quadTerms( X );
            Int = obj.interactionTerms( X );
            Fint = obj.facilityIntTerms( X );
            Z = [ ones( size( X, 1 ), 1 ), X, Int, Quad, IxQ, Fint ];
            [ R, C ] = size( Z );
            A = zeros( 2*R, 2*C );
            for Q = 1:R
                K = 2*Q - 1;
                A( K, 1:C ) = Z( Q, : );
                A( K + 1, C+1:end ) = Z( Q, : );
            end
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
        function FxL = facilityIntTerms( obj, X )
            %--------------------------------------------------------------
            % Return facility times continuous factor interaction terms
            %
            % FxL = obj.facilityIntTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %--------------------------------------------------------------
            FxL = double.empty( size( X, 1 ), 0 );                          % default result
            if strcmpi( obj.Model, "interaction" )
                %----------------------------------------------------------
                % calculate linear facility interaction terms
                %----------------------------------------------------------
                Idx = ismember( obj.Design.FacNames, obj.Facility );
                Fac = X( :, Idx );
                X = X( :, ~Idx );
                FxL = X.*Fac;
            end
        end % facilityIntTerms
        
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
            Cont = ( obj.Factor.Type == "CONTINUOUS" ).';
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
        
        function [ Q, IxQ ] = quadTerms( obj, X )
            %--------------------------------------------------------------
            % Return matrix of quadratic terms if a continuous factor has 3
            % or more levels.
            %
            % Q = obj.quadTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %
            % Output Arguments:
            %
            % Q     --> Pure quadratic terms
            % IxQ   --> linear times qudratic interactions
            %--------------------------------------------------------------
            Cont = ( obj.Factor.Type == "CONTINUOUS" ).';
            ContQ = Cont & ( obj.Factor.NumLevels.' > 2 );
            ContL = Cont & ( obj.Factor.NumLevels.' <= 2 );
            Q = X( :, ContQ ).^2;
            IxQ = X( :, ContL ).*Q;
        end
    end
end % rateModel