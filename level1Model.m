classdef ( Abstract = true ) level1Model
    % An abstract class to implement the level-1 fitting.
    
    properties ( SetAccess = protected )
        Xname           string                                              % Level-1 covariate
        Yname           string                                              % Response variable
        CovMdl          lv1CovModelType                         = "OLS"     % Covariance model
        S2              double                                              % Level-1 variance scale factor
        Delta           double                                              % Level-1 covariance model parameter vector
        B               double                                              % array of level-1 fit coefficients
        Order   (1,1)   int8         { mustBeGreaterThan( Order, 0 ) } = 1 % Polynomial model order                                               % Polynomial order for level-1 model                                               
    end % protected properties
    
    properties ( SetAccess = protected, Abstract = true )
        F       cell                                                        % Level-1 coefficient covariance matrices
    end % abstract & protected properties
    
    properties ( Dependent = true )
        numCovPars  int8                                                    % Number of covariance model parameters
    end % dependent properties
    
    methods ( Abstract = true )
        obj = level1Fits( obj, D, Tests )                                   % Fit the level-1 model
        diagnosticPlots( obj, TestNumber )                                  % Make fit diagnostic plots
        A = basis( obj, X )                                                 % basis function matrix generator
    end % Abstract method signatures
    
    methods
        function obj = setCovMdlName( obj, CovMdlName )
            %--------------------------------------------------------------
            % Set the covariance model name to either:
            %
            % a) OLS        - ordinary least squares {default}
            % b) Power      - power model
            % c) TwoComp    - Two components of variance
            %
            % obj = setCovMdlName( CovMdlName )
            %
            % Input Arguments:
            %
            % CovMdlName    --> (string) Name of covariance model. {"OLS"}
            %--------------------------------------------------------------
            arguments
                obj         (1,1)
                CovMdlName  (1,1)   string = "OLS"
            end
            try
                obj.CovMdl = CovMdlName;
            catch
                warning('Level-1 Covariance Model "%s" is not recognised',...
                        CovMdlName );
            end
        end % setCovMdlName
        
        function obj = setXname( obj, Xname )
            %--------------------------------------------------------------
            % Set the name of the level-1 covariate (independent variable)
            %
            % obj = obj.setXname( Xname );
            %
            % Input Arguments:
            %
            % Xname     --> (string) Name of level-1 covariate
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                Xname   (1,1)   string   { mustBeNonempty( Xname ) }
            end
            obj.Xname = Xname;
        end % setXname
        
        function obj = setYname( obj, Yname )
            %--------------------------------------------------------------
            % Set the name of the level-1 response variable
            %
            % obj = obj.setYname( Yname );
            %
            % Input Arguments:
            %
            % Xname     --> (string) Name of level-1 covariate
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                Yname   (1,1)   string   { mustBeNonempty( Yname ) }
            end
            obj.Yname = Yname;
        end % 
    end % ordinary & constructor methods
    
    methods
        function N = get.numCovPars( obj )
            N = numel( obj.Delta );
        end
    end % get/set methods
end % classdef
