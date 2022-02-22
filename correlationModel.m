classdef ( Abstract = true ) correlationModel < handle
    % A container for the for the battery test facility correlation
    % experiment analyses
    
    properties ( SetAccess = immutable, Abstract = true )
        Design                                                              % Design object
    end % immutable properties
    
    properties ( SetAccess = protected, Abstract = true )
    end % protected properties
    
    properties ( Constant = true, Abstract = true )
        ModelName   string                                                  % Name of model
    end % Constant & abstract properties
    
    properties ( SetAccess = protected, Dependent = true )
        NumFac      double                                                  % Number of design factors
    end % dependent properties
    
    properties ( SetAccess = protected )
        MleObj      	                                                    % MLE analysis object
        Model           supportedModelType          = "linear"              % Facility model terms
        B       (:,:)   double                                              % Level-1 fit coefficients
        S2      (1,1)   double                                              % Pooled level-1 variance parameter
        F       (1,:)   cell                                                % Level-1 information matrix
        Syms    (1,:)   string                                              % basis function list
    end % protected properties    
    
        
    properties ( SetAccess = protected, Dependent = true )
        Theta   (:,1)   double                                              % Level-2 regression coefficients
        Omega   (1,:)   double                                              % Level-2 covariance model coefficients
        D               double                                              % Level-2 covariance matrix
        C               double                                              % level-2 correlation matrix
        T               double                                              % level-2 standard errors
        CovQ            double                                              % Covariance matrix for Theta
    end % Dependent properties
    
    properties ( Access = private )
    end % private properties
    
    properties( SetAccess = protected, Dependent = true )
        Factor              table                                           % Factor information
        Dc                  double                                          % Coded design matrix
        FacNames            string                                          % DoE factor names
    end % dependent properties
    
    properties( Access = private, Dependent = true )
    end % Private and dependent properties
    
    methods ( Abstract = true )
        A = basis( obj, X )                                                 % Generate basis function matrix
        [ B, S2, F ] = level1Fits( obj, D, NumTests, Xname, Yname )         % Perform the required analysis
        obj = defineModel( obj, Type )                                      % Define model
        Z = predictions( obj, X )                                           % Predictions
    end % abstract method signatures
    
    methods      
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
                obj         (1,1)               { mustBeNonempty( obj ) }
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
    end % ordinary methods
    
    methods
        function N = get.NumFac( obj )
            % Return number of factors
            N = obj.Design.NumFac;
        end
        
        function Dc = get.Dc( obj )
            % Get coded design matrix
            Dc = obj.Design.Design;
            Dc.( obj.Facility ) = double( Dc.( obj.Facility ) );
            Dc = table2array( Dc );
            Dc = obj.Design.code( Dc );
        end % codedDesignMatrix
        
        function F = get.Factor( obj )
            % Return factor definition table
            F = obj.Design.Factor;
        end
        
        function F = get.FacNames( obj )
            % Return the factor names as a string
            F = obj.Design.FacNames;
        end
    end % get set methods
    
    
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
    
    methods ( Access = protected )
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
    end % protected methods
    

    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true )
    end % Static methods
end