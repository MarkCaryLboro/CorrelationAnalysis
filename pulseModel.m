classdef pulseModel < correlationModel
    % Pulse facility correlation test level-2 model class
    
    properties
        Facility    (1,1)             string        = "Facility"            % Facility variable
    end % public properties
    
    properties ( Constant = true )
        ModelName   string                          = "Pulse"               % Name of model
    end % Constant & abstract properties    
    
    properties ( SetAccess = immutable )
        Design                                                              % Design object
    end % immutable properties     
    
    properties ( SetAccess = protected )
    end % protected properties    
    
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
            %                   "interaction", "quadratic", "cubic"
            %                   or "complete"
            %--------------------------------------------------------------
            arguments
                DesignObj   (1,1)   pulseDesign         { mustBeNonempty( DesignObj ) }
                MleObj      (1,1)   mleAlgorithms       = "EM"; 
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
                    obj.MleObj = mle();
            end
            obj = obj.setModel( ModelType );
            obj = obj.setModelSyms();
        end % constructor
        
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
            %               "interaction", "quadratic", "cubic"
            %               or "complete".
            %--------------------------------------------------------------
            try
                obj.Model = ModelStr;
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
            try
                Int = obj.getInteractionSyms( S );                          % Define any linear interaction terms
            catch
                Int = [];
            end
            try
                Qcon = obj.getConPureQuadSyms( S );                         % Define any pure continuous quadratic terms
            catch
                Qcon = [];
            end
            try
                IQcon = obj.getConLinQuadSyms( S );                         % Define any lin times quad continuous terms
            catch
                IQcon = [];
            end
            try
                Qcat = obj.getCatPureQuadSyms( S );                         % Define any pure quadratic categorical terms
            catch
                Qcat = [];
            end
            try
                Ccat = obj.getCatPureCubicSyms( S );
            catch
                Ccat = [];
            end
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
                    S = [ S Int Qcon Qcat ];
                case "cubic"
                    %------------------------------------------------------
                    % Cubic terms required
                    %------------------------------------------------------
                    S = [ S Int Qcon Qcat Ccat ];
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
                obj     (1,1)       pulseModel
                X       (:,:)       double          { mustBeNonempty( X ),...
                                                      mustBeNumeric( X ),...
                                                      mustBeReal( X ) }
            end
            R = size( X, 1 );
            Z = X;
            Zint = [];
            Zquad = [];
            ZIxQ = [];
            ZQcat = [];
            ZCcat = [];
            switch obj.Model
                case "interaction"
                    try
                        Zint = [ X obj.interactionTerms( X ) ];
                    catch
                        error('Cannot construct level-2 model of type "%s"',...
                                    obj.Model );
                    end
                case "quadratic"
                    try
                        Zquad = obj.quadTerms( X );
                        ZQcat = obj.quadCatTerms( X );
                    catch
                        error('Cannot construct level-2 model of type "%s"',...
                                    obj.Model );
                    end
                case "cubic"
                    try
                        Zquad = obj.quadTerms( X );
                        ZQcat = obj.quadCatTerms( X );
                        ZCcat = obj.cubicCatTerms( X );
                    catch
                        error('Cannot construct level-2 model of type "%s"',...
                                    obj.Model );
                    end
                case "complete"
                    try
                        [ Zquad, ZIxQ ] = obj.quadTerms( X );
                        ZQcat = obj.quadCatTerms( X );
                        Zint = obj.interactionTerms( X );
                    catch
                        error('Cannot construct level-2 model of type "%s"',...
                                    obj.Model );
                    end
            end
            Z = [ ones( R, 1 ), Z,  Zint, Zquad, ZIxQ, ZQcat ZCcat ];
            A = cell( 1, R );
            NumLv1Coeff = size( obj.B, 1 );
            for Q = 1:R
                A{ Q } = Z( Q, : );
                for T = 2:NumLv1Coeff
                    A{ Q } = blkdiag( A{ Q }, Z( Q, :) );
                end
            end
        end % basis
        
        function obj = defineModel( obj, Model )                                      
            %--------------------------------------------------------------
            % Define the experimental model
            %
            % obj = obj.defineModel( Model );
            %
            % Input Arguments:
            %
            % Model     --> (string) Facility model type, either {"linear"}
            %               or "quadratic"
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   rateModel       { mustBeNonempty( obj ) }
                Model   (1,1)   string          { mustBeMember( Model, [ "linear", "quadratic", "cubic"  ])} = "linear" 
            end            
            try
                obj.Model = supportedModelType( Model );
            catch
                obj.Model = supportedModelType( "linear" );
            end
        end % defineModel
        
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
                obj         (1,1)                   { mustBeNonempty( obj ) }
                D                   table           { mustBeNonempty( D ) }
                NumTests    (1,1)   double          { mustBeNonempty( NumTests ) }
                Xname       (1,1)   string          = "Cycle";
                Yname       (1,1)   string          = "DischargeIR"
            end
            Sn = unique( D.SerialNumber, 'stable' );
            N = numel( Sn );
            B = zeros( 4, NumTests );
            Kc = obj.socCode(0.5);                                          % knot in coded units
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
                    X = L{ I, "SoC" };
                    X = obj.socCode( X );
                    Xs = max( [zeros( size( X ) ), X - Kc ], [], 2 );
                    X = [ ones( size( X, 1 ), 1 ), X, X.^2, Xs.^2 ];        %#ok<AGROW>
                    Y = L{ I, Yname };
                    %------------------------------------------------------
                    % Eliminate any NaNs
                    %------------------------------------------------------
                    Yidx = ~isnan( Y );
                    Y = Y( Yidx );
                    X = X( Yidx, : );
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
        
        function A = getDefaultCon( obj )
            %--------------------------------------------------------------
            % Retrieve default contrast vector
            %
            % A = getDefaultCon();
            %--------------------------------------------------------------
            N = obj.Design.Factor.NumLevels;
            X = cell( 1, N );
            Xc = zeros( N, 1 );
            for Q = 1:N
                Xc( Q ) = obj.Design.code( Q );
                X{ Q } = obj.basis( Xc( Q ) );
            end
            Idx = ( Xc == 0 );
            R = X{ Idx };
            X = X( ~Idx );
            N = numel( X );
            A = N * R{ : };
            for Q = 1:N
                C = X{ Q };
                A = A - C{:};
            end
        end % getDefaultCon        
        
        function A = getAi( obj, D )
            %--------------------------------------------------------------
            % Return the cell array of level-2 regression matrices
            %
            % Input Arguments:
            %
            % D     --> (table) Data table
            %--------------------------------------------------------------
            A = D( :, [ "SerialNumber", obj.FacNames ] );
            A = unique( A, 'stable' );
            A = A( :, obj.FacNames );
            A = table2array( A );
            A = obj.Design.code( A );
            A = obj.basis( A );
        end % getAi       
        
        function Xc = codeSoC( obj, X )
            %--------------------------------------------------------------
            % Code SoC data
            %
            % Xc = obj.codeSoC( X );
            %
            % Input Arguments:
            %
            % X     --> Vector of soc data assumed to be in the interval
            %           [0,1].
            %
            % Output Arguments:
            %
            % Xc    --> Vector of coded soc data [0,1] --> [-1, 1]
            %--------------------------------------------------------------
            Xc = obj.socCode( X );
        end % codeSoC
    end % constructor and ordinary methods
    
    methods ( Access = protected, Static = true )
        function Xc = socCode( X )
            %--------------------------------------------------------------
            % Code the soc values
            %
            % Xc = obj.socCode( X );
            %
            % Input Arguments:
            %
            % X     --> Vector of soc data assumed to be in the interval
            %           [0,1].
            %
            % Output Arguments:
            %
            % Xc    --> Vector of coded soc data [0,1] --> [-1, 1]
            %--------------------------------------------------------------
            Xc = 2 * ( X - 0.5 );
        end
    end % protected static methods
end % classdef