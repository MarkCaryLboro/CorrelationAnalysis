classdef rateModel < correlationModel
    
    properties
        Facility    (1,1)             string        = "Facility"            % Facility variable
    end % public properties
    
    properties ( Constant = true )
        ModelName   string                          = "Rate"                % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties  
    
    properties ( SetAccess = protected )
        MleObj      	                                                    % MLE analysis object
        Model       supportedModelType                      = "linear"      % Facility model terms
        B   (2,:)   double                                                  % Level-1 fit coefficients
        S2  (1,1)   double                                                  % Pooled level-1 variance parameter
        F   (1,:)   cell                                                    % Level-1 information matrix
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
            % X     --> (double) data array in coded units
            %
            % Output Arguments:
            %
            % A     --> (cell) (1xM) array of basis function matrices for
            %           the ith training condition
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
            R = size( Z, 1 );
            A = cell( 1, R );
            for Q = 1:R
                A{ Q } = blkdiag( Z( Q, : ), Z( Q, :) );
            end
        end % basis
                
        function [ B, S2, F ] = level1Fits( obj, D )
            %--------------------------------------------------------------
            % Return level-1 fit vector.
            %
            % [ B, S2, F ] = obj.level1Fits( D );
            %
            % Input Arguments:
            %
            % D     --> Data table
            %
            % Output Arguments:
            %
            % B     --> ( 2 x M ) array of level-1 fit coefficients
            % S2    --> Pooled level-1 variance parameter
            % F     --> ( 1 x M ) cell array of level-1 information 
            %           matrices 
            %--------------------------------------------------------------
            Sn = unique( D.SerialNumber, 'stable' );
            N = numel( Sn );
            B = zeros( 2, obj.NumTests );
            K = 0;
            P = zeros( 1, obj.NumTests );
            F = zeros( 1, obj.NumTests );
            S2 = 0;
            for Q = 1:N
                %----------------------------------------------------------
                % Fit the local model for each sweep
                %----------------------------------------------------------
                Idx = strcmpi( D.SerialNumber, Sn{ Q } );
                L = D( Idx, [ obj.FacNames, "Cycle", obj.Response ] );
                L.( obj.Facility ) = double( correlationFacility( string(...
                                           L.( obj.Facility ) ) ) );
                Lcells = unique( L( :, obj.FacNames ), 'rows', 'stable' );
                NL = height( Lcells );
                for C = 1:NL
                    %------------------------------------------------------
                    % Fit the local model for each sweep
                    %------------------------------------------------------
                    K = K + 1;
                    I = L{ :, obj.FacNames } == Lcells{ C, : };
                    I = all( I, 2 );
                    X = L{ I, 'Cycle' };
                    X = [ ones( size( X, 1 ), 1 ), X ];                        %#ok<AGROW>
                    Y = L{ I, obj.Response };
                    %------------------------------------------------------
                    % Level-1 regression coefficients
                    %------------------------------------------------------
                    B( :, K ) = X\Y;
                    %------------------------------------------------------
                    % Calculate SSE for this sweep
                    %------------------------------------------------------
                    S2 = S2 + ( Y - X*B( :, K ) ).' * ( Y - X*B( :, K ) );
                    P( K ) = numel( Y );
                    F( K ) = X.'*X;
                end
            end
            %--------------------------------------------------------------
            % Pooled level-1 variance
            %--------------------------------------------------------------
            S2 = S2 / sum( P );
            F = cellfun( @( X )times( X, 1/S2 ), F );
        end % level1Fits       

        function obj = fitModel( obj, D ) 
            %--------------------------------------------------------------
            % Perform the required repeated measurments analysis
            %
            % obj = obj.fitModel( D );
            %
            % Input Arguments:
            %
            % D     --> Data table
            %
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   rateModel   { mustBeNonempty( obj ) }
                D               table       { mustBeNonempty( D ) }
            end
            %--------------------------------------------------------------
            % Perform the level-1 analysis
            %--------------------------------------------------------------
            [ obj.B, obj.S2, obj.P ] = obj.level1Fits( D );
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