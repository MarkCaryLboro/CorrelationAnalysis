classdef rateModel < correlationModel
    % Rate facility correlation test level-2 model class
    
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
        Model           supportedModelType          = "linear"              % Facility model terms
        B       (2,:)   double                                              % Level-1 fit coefficients
        S2      (1,1)   double                                              % Pooled level-1 variance parameter
        F       (1,:)   cell                                                % Level-1 information matrix
        Syms    (1,:)   string                                              % basis function list
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
        function obj = rateModel( DesignObj, MleObj, ModelType )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = rateModel( DesignObj, Algorithm, ModelType )
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
        
        function Z = predictions( obj, X )                                    
            %--------------------------------------------------------------
            % Calculate predictions
            %
            % Z = obj.predictions( X );
            %
            % Input Arguments:
            %
            % X     --> Ageing conditions ( R x #factors );
            %
            % Output Arguments:
            %
            % Z     --> ( R x P ) matrix of level-1 coefficient vectors
            %--------------------------------------------------------------
            Xc = obj.Design.code( X );
            A = obj.basis( Xc );
            R = size( Xc, 1 );
            P = size( obj.B, 1 );
            Z = zeros( R, P );
            for Q = 1:R
                Z( Q, : ) = ( A{Q} * obj.Theta ).';
            end
        end % predictions
        
        function [ B, Bref ] = predictLvl1( obj, A )
            %--------------------------------------------------------------
            % Predict slope and offset at user-specified ageing conditions
            %
            % [ B, Bref ] = predictLvl1( obj, A );
            %
            % Input Arguments:
            %
            % A     --> (NxK) Matrix of ageing conditions ( double )
            %
            % Output Arguments:
            %
            % B     --> (Nxp) Matrix of level-1 fit coefficients
            % Bref  --> (Nxp) Matrix of level-1 fit coefficients for
            %           reference facility
            %--------------------------------------------------------------
            Ac = obj.Design.code( A );
            Ac = obj.basis( Ac );
            Rc = A;
            Mdn = obj.Design.Factor{ obj.Facility, "Levels" };
            Idx = strcmpi( obj.FacNames, obj.Facility );
            Rc( :, Idx ) = median( double( Mdn{ : } ) );
            Rc = obj.Design.code( Rc );
            Rc = obj.basis( Rc );                                           % Reference basis
            B = cellfun( @(X)mtimes( X, obj.Theta ), Ac, 'UniformOutput',...
                                      false);
            B = cell2mat( B );
            Bref = cellfun( @(X)mtimes( X, obj.Theta ), Rc, 'UniformOutput',...
                                      false);
            Bref = cell2mat( Bref );
        end % predictLvl1
        
        function obj = setModel( obj, ModelStr )
            %--------------------------------------------------------------
            % Set the facility interaction model type to either "linear",
            % "interaction", "quadratic" or "complete".
            %
            % obj = obj.setModel( ModelStr );
            %
            % Input Arguments:
            %
            % ModelStr  --> (string) Required model, either "linear",
            %               "interaction", "quadratic" or "complete".
            %--------------------------------------------------------------
            try
                obj.Model = ModelStr;
                obj = obj.setModelSyms();
            catch
                warning('Property "Model" not changed');
            end
        end % setModel
        
        function obj = setModelSyms( obj )
            %--------------------------------------------------------------
            % Define model symbology for identifying terms in future
            % hypothesis tests
            %
            % obj = obj.setModelSyms();
            %--------------------------------------------------------------
            S = obj.Factor.Symbol.';                                        % Factor symbols
            Int = obj.getInteractionSyms( S );                              % Define any linear interaction terms
            Qcon = obj.getConPureQuadSyms( S );                             % Define any pure continuous quadratic terms
            IQcon = obj.getConLinQuadSyms( S );                             % Define any lin times quad continuous terms
            Qcat = obj.getCatPureQuadSyms( S );                             % Define any pure quadratic categorical terms
            switch string( obj.Model )
                case "interaction"
                    %------------------------------------------------------
                    % Interactions Necessary
                    %------------------------------------------------------
                    S = [ S Int ];
                case "quadratic"
                    %------------------------------------------------------
                    % Quadratic Terms Required
                    %------------------------------------------------------
                    S = [ S Int Qcon ];
                case "complete"
                    S = [ S Int Qcon IQcon Qcat ];
            end
            S = [ "1" S ];                                                  % Add constant
            obj.Syms = S;                                                   % Answer for a linear model
        end % setModelSyms
        
        function A = basis( obj, X ) 
            %--------------------------------------------------------------
            % Generate basis function matrix    
            %
            % A = obj.basis( X );
            %
            % Input Arguments:
            %
            % X     --> (double) (R x NumFac) data array in coded units
            %
            % Output Arguments:
            %
            % A     --> (cell) (1 x R) array of basis function matrices for
            %           the ith configuration
            %--------------------------------------------------------------
            arguments
                obj     (1,1)       rateModel
                X       (:,:)       double          { mustBeNonempty( X ),...
                                                      mustBeNumeric( X ),...
                                                      mustBeReal( X ) }
            end
            R = size( X, 1 );
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
                L = D( Idx, [ obj.Design.FacNames, Xname, Yname ] );
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
            % obj = obj.fitModel( D, S );
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
        
        function A = getDefaultCon( obj )
            %--------------------------------------------------------------
            % Retrieve default contrast vector
            %
            % A = getDefaultCon();
            %--------------------------------------------------------------
            Fac = obj.Design.Factor{ obj.Facility, "Symbol" };
            A = double( contains( obj.Syms, Fac ) );
            A = repmat( A, 1, size( obj.B, 1 ) );
        end % getDefaultCon

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
        
        function V = get.CovQ( obj )
            % Level-2 covariance matrix
            V = obj.MleObj.CovQ;
        end
        
        function T = get.T( obj )
            % Level-2 standard errors
            T = sqrt( diag( obj.D ) );
        end
        
        function C = get.C( obj )
            % Level-2 correlation matrix
            C = obj.D ./ ( obj.T * obj.T.' );
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
        
        function Qcat = getCatPureQuadSyms( obj, S )
            %--------------------------------------------------------------
            % Return pure quad terms for categorical factors
            %
            % Qcat = obj.getCatPureQuadSyms( S );
            %
            % input Arguments:
            %
            % S     --> (string) Linear factor symbols list
            %--------------------------------------------------------------
            Cat = ( obj.Factor.Type == "CATEGORICAL" ).';
            Cat = Cat & ( obj.Factor.NumLevels.' > 2 );
            K = 0;
            Qcat = string.empty( 0, sum( Cat ) );
            for Q = 1:obj.NumFac
                if ( Cat( Q ) )
                    K = K + 1;
                    Qcat( K ) = strjoin( [ S( Q ), "2" ], "^" );
                end
            end
        end % getCatPureQuadSyms
        
        function IQcon = getConLinQuadSyms( obj, S )
            %--------------------------------------------------------------
            % Return linear times quadratic interactions for continuous
            % variables
            %
            % IQcon = obj.getConLinQuadSyms( S );
            %
            % input Arguments:
            %
            % S     --> (string) Linear factor symbols list
            %--------------------------------------------------------------
            Cont = ( obj.Factor.Type == "CONTINUOUS" ).';
            Quad = Cont & ( obj.Factor.NumLevels.' > 2 );
            Lin = Cont & ( obj.Factor.NumLevels.' <= 2 );
            SS = arrayfun( @( X )strjoin( [ X, "2" ], "^" ), S );
            SS = SS( Quad );
            Finish = 0;
            IQcon = string.empty( 0, sum( Lin ) * sum( Quad ) );
            for Q = 1:obj.NumFac
                if Lin( Q ) 
                    for R = 1:sum( Quad )
                        Start =  Finish + 1;
                        Finish = Start + numel( SS ) - 1;
                        A = S( Q );
                        IQcon( Start:Finish ) = arrayfun( @( X )strjoin( ...
                            [ A, X ], "*"), SS );
                    end
                end
            end
        end
        
        function Qcon = getConPureQuadSyms( obj, S )
            %--------------------------------------------------------------
            % Return pure quadratic syms for continuous factors
            %
            % Qcon = obj.getConPureQuadSyms( S );
            %
            % input Arguments:
            %
            % S     --> (string) Linear factor symbols list
            %--------------------------------------------------------------
            Cont = ( obj.Factor.Type == "CONTINUOUS" ).';
            Cont = Cont & ( obj.Factor.NumLevels.' > 2 );
            K = 0;
            Qcon = string.empty( 0, sum( Cont ) );
            for Q = 1:obj.NumFac
                if ( Cont( Q ) )
                    K = K + 1;
                    Qcon( K ) = strjoin( [ S( Q ), "2" ], "^" );
                end
            end
        end % getConPureQuadSyms
        
        function I = getInteractionSyms( obj, S )
            %--------------------------------------------------------------
            % Return Interaction Symbol Strings
            %
            % Int = obj.getInteractionSyms( S );
            %
            % input Arguments:
            %
            % S     --> (string) Linear factor symbols list
            %--------------------------------------------------------------
            NumInt = factorial( obj.NumFac ) / factorial( 2 )...
                     / factorial( obj.NumFac - 2 );
            I = string.empty( 0, NumInt );
            K = 0;
            for Q = 1:( obj.NumFac - 1 )
                for R = ( Q + 1 ):obj.NumFac
                    K = K + 1;
                    I( K ) = strjoin( [ S( Q ), S( R ) ], "*");
                end
            end
        end % getInteractionSyms
    end % private methods
    
    methods ( Access = protected, Static = true )
        function I = interactionTerms( X )
            %--------------------------------------------------------------
            % Return continuous interaction terms
            %
            % I = obj.interactionTerms( X );
            %
            % Input Arguments:
            %
            % X     --> (double) data in coded units
            %--------------------------------------------------------------
            [ N, C_ ] = size( X );
            Nint = factorial( C_ )/ factorial( 2 )/factorial( C_ - 2 );
            I = zeros( N, Nint );
            K = 0;
            for Q = 1:( C_ - 1 )
                for R = ( Q + 1 ):C_
                    K = K + 1;
                    I( :, K ) = X( :, Q ).*X( :, R );
                end
            end
        end % interactionTerms
    end % Static methods
end % rateModel