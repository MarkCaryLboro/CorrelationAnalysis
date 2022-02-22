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
                    obj.MleObj = mle();
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