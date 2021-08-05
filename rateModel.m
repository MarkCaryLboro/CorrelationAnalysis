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
        Model           supportedModelType                      = "linear"  % Facility model terms
        B       (2,:)   double                                              % Level-1 fit coefficients
        S2      (1,1)   double                                              % Pooled level-1 variance parameter
        F       (1,:)   cell                                                % Level-1 information matrix
    end % protected properties    
    
    properties ( SetAccess = protected, Dependent = true )
        Theta   (:,1)   double                                              % Level-2 regression coefficients
        Omega   (1,3)   double                                              % Level-2 covariance model coefficients
        D               double                                              % Level-2 covariance matrix
        C               double                                              % level-2 correlation matrix
        T               double                                              % level-2 standard errors
        CovQ            double                                              % Covariance matrix for Theta
    end % Dependent properties
    
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
                MleObj      (1,1)   mleAlgorithms       { mustBeNonempty( MleObj ) }    = "EM";           
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
        end % constructor
        
        function Z = predictions( obj, A, X )                                    
            %--------------------------------------------------------------
            % Calculate predictions
            %
            % Z = obj.predictions( A, X )
            %
            % Input Arguments:
            %
            % A     --> Ageing conditions ( level-2 covariate matrix)
            % X     --> Cycle number to predict ( level-1 covariate );
            %--------------------------------------------------------------
        end % predictions
        
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
            R = size( X, 1 );
            Z = ones( R, 1 );
            switch obj.Model
                case "linear"
                    Z = X;
                case "interaction"
                    Z = [ X obj.interactionTerms( X ) ];
                case "quadratic"
                    Z = [ X obj.interactionTerms( X ) obj.quadTerms( X ) ];
                case "complete"
                    [ Q, IxQ ] = obj.quadTerms( X );
                    Qcat = obj.quadCatTerms( X );
                    Z = [ X obj.interactionTerms( X ), Q, IxQ, Qcat  ];
            end
            Z = [ ones( size( X, 1 ), 1 ), Z ];
            A = cell( 1, R );
            for Q = 1:R
                A{ Q } = blkdiag( Z( Q, : ), Z( Q, :) );
            end
        end % basis
                
        function [ B, S2, F ] = level1Fits( obj, D, NumTests, Xname, Yname )
            %--------------------------------------------------------------
            % Return level-1 fit vector.
            %
            % [ B, S2, F ] = obj.level1Fits( D, NumTests, Xname, Yname );
            %
            % Input Arguments:
            %
            % D         --> Data table
            % NumTests  --> Number of tests
            % Xname     --> (string) Name of independent variable
            % Yname     --> (string) Name of response variable
            %
            % Output Arguments:
            %
            % B     --> ( 2 x M ) array of level-1 fit coefficients
            % S2    --> Pooled level-1 variance parameter
            % F     --> ( 1 x M ) cell array of level-1 information 
            %           matrices 
            %--------------------------------------------------------------
            arguments
                obj         (1,1)   rateModel       { mustBeNonempty( obj ) }
                D                   table           { mustBeNonempty( D ) }
                NumTests    (1,1)   double          { mustBeNonempty( NumTests ) }
                Xname       (1,1)   string          = "Cycle";
                Yname       (1,1)   string          = "DischargeCapacity"
            end
            Sn = unique( D.SerialNumber, 'stable' );
            N = numel( Sn );
            B = zeros( 2, NumTests );
            K = 0;
            P = zeros( 1, NumTests );
            F = cell( 1, NumTests );
            S2 = 0;
            for Q = 1:N
                %----------------------------------------------------------
                % Fit the local model for each sweep
                %----------------------------------------------------------
                Idx = strcmpi( D.SerialNumber, Sn{ Q } );
                L = D( Idx, [ obj.Design.FacNames, "Cycle", Yname ] );
                Lcells = unique( L( :, obj.Design.FacNames ), 'rows',...
                                       'stable' );
                NL = height( Lcells );
                for C_ = 1:NL
                    %------------------------------------------------------
                    % Fit the local model for each sweep
                    %------------------------------------------------------
                    K = K + 1;
                    I = L{ :, obj.Design.FacNames } == Lcells{ C_, : };
                    I = all( I, 2 );
                    X = L{ I, 'Cycle' };
                    X = [ ones( size( X, 1 ), 1 ), X ];                        %#ok<AGROW>
                    Y = L{ I, Yname };
                    %------------------------------------------------------
                    % Level-1 regression coefficients
                    %------------------------------------------------------
                    B( :, K ) = X\Y;
                    %------------------------------------------------------
                    % Calculate SSE for this sweep
                    %------------------------------------------------------
                    S2 = S2 + ( Y - X*B( :, K ) ).' * ( Y - X*B( :, K ) );
                    P( K ) = numel( Y );
                    F{ K } = X.'*X;
                end
            end
            %--------------------------------------------------------------
            % Pooled level-1 variance
            %--------------------------------------------------------------
            S2 = S2 / sum( P );
            F = cellfun( @( X )times( X, 1/S2 ), F, 'UniformOutput', false );
        end % level1Fits       
        
        function obj = fitModel( obj, D, S ) 
            %--------------------------------------------------------------
            % Perform the required repeated measurments analysis
            %
            % obj = obj.fitModel( D, NumTests, S );
            %
            % Input Arguments:
            %
            % D         --> (table) Data table
            % S         --> (struct) Analysis information with fields:
            %
            %           NumTests --> (double) Number of tests
            %           Xname    --> (string) Level-1 dependent variable
            %           Yname    --> (string) Response variable
            %--------------------------------------------------------------
            arguments
                obj         (1,1)   rateModel   { mustBeNonempty( obj ) }
                D                   table       { mustBeNonempty( D ) }
                S           (1,1)   struct      { mustBeNonempty( S ) }
            end
            %--------------------------------------------------------------
            % Perform the level-1 analysis
            %--------------------------------------------------------------
            [ obj.B, obj.S2, obj.F ] = obj.level1Fits( D, S.NumTests,...
                                           S.Xname, S.Yname );
            %--------------------------------------------------------------
            % Generate the level-2 covariate matrices
            %--------------------------------------------------------------
            A = obj.getAi( D );
            obj.MleObj = obj.MleObj.mleRegTemplate( A, obj.F, obj.B );
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
            %               "interaction", "quadratic" or "complete"
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   rateModel       { mustBeNonempty( obj ) }
                Model   (1,1)   string          = string.empty;
            end
            try
                obj.Model = supportedModelType( Model );
            catch
                obj.Model = supportedModelType( "linear" );
            end
        end % defineModel
        
        function A = getAi( obj, D )
            %--------------------------------------------------------------
            % Return the cell array of level-2 regression matrices
            %
            % Input Arguments:
            %
            % D     --> (table) Data table
            %--------------------------------------------------------------
            Idx = ( D.Cycle == 1 );
            A = D( Idx, obj.FacNames );
            A = table2array( A );
            A = obj.Design.code( A );
            A = obj.basis( A );
        end % getAi
    end % Constructor and ordinary methods
    
    methods
        function Q = get.Theta( obj )  
            % Level-2 regression coefficients
            Q = obj.MleObj.Theta;
        end
        
        function W = get.Omega( obj )  
            % Level-2 covariance model coefficients
            W = obj.MleObj.Omega;
        end
        
        function D = get.D( obj )
            % Level-2 covariance matrix
            D = obj.MleObj.D;
        end
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
        end % quadTerms
        
        function Q = quadCatTerms( obj, X )
            %--------------------------------------------------------------
            % Return matrix of quadratic terms if a categorical factor has
            % 3 or more levels.
            %
            % Q = obj.quadCatTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %--------------------------------------------------------------
            Cat = ( obj.Factor.Type == "CATEGORICAL" ).';
            CatQ = Cat & ( obj.Factor.NumLevels.' > 2 );
            Q = X( :, CatQ ).^2;
        end % quadCatTerms
    end
end % rateModel