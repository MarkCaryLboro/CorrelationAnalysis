classdef ( Abstract = true ) mle
    % A class to perfomr the mle analysis for the battery facility test
    % correlation study
    
    properties ( Constant = true, Abstract = true )
        Algorithm       mleAlgorithms
    end % Constant & abstract properties
    
    properties ( SetAccess = protected )
        Theta   (:,1)   double                                              % Level-2 regression coefficients
        Omega   (:,1)   double                                              % Level-2 covariance model parameters
        CovQ            double                                              % Covariance matrix for Theta
    end % protected properties
    
    properties ( Access = protected )
        I       (:,1)   double                                              % Row indices for Omega
        J       (:,1)   double                                              % Column indices for Omega
    end % protected properties
    
    properties ( SetAccess = protected, Dependent = true, Abstract = true )
        D               double                                              % level-2 covariance matrix
    end % dependent & abstract properties
    
    methods ( Abstract = true )
        L = costFcn( obj, Theta, A, B )                                     % MLE cost function
        [ Q, W ] = startingValues( obj, A, B )                              % Compute starting values for MLE
    end % abstract signatures
    
    properties ( SetAccess = protected, Dependent = true )
        C               double                                              % Level-2 correlation matrix
        T               double                                              % Level-2 standard errors
    end % dependent properties
    
    methods
        function obj = mleRegTemplate( obj, A, X, B )
            %--------------------------------------------------------------
            % Template for the analysis method
            %
            % obj = obj.mleRegTemplate( A, X, B );
            %
            % Input Arguments:
            %
            % A     --> (1xm) (cell) array of coded level-2 covariate 
            %                        matrices
            % X     --> (1xm) (cell) array of level-1 covariate matrices
            % B     --> (2xm) array of level-1 coefficient estimates
            %--------------------------------------------------------------
            
        end % mleRegTemplate
    end % constructor and ordinary methods
    
    methods
        function C = get.C( obj )
            % Fetch level-2 correlation matrix
            C = obj.D ./ ( obj.T * obj.T.' );
        end
        
        function T = get.T( obj )
            % Fetch level-2 standard errors
            T = sqrt( diag( obj.D ) );
        end
    end % get/set methods
    
    methods ( Access = protected )
        function CovQ = getCovQ( obj, A, X )
            %--------------------------------------------------------------
            % Calculate the covariance matrix for the vector Theta
            %
            % Input Arguments:
            %
            % A     --> Level-2 regression matrices
            %--------------------------------------------------------------
            CovQ = zeros( numel( obj.Theta ) );
            M = max( size( A ) );
            Id = eye( max( size( obj.D ) ) );
            for Q = 1:M
                S = X{ Q } \ Id;
                S = S + obj.D;
                S = S \ Id;
                CovQ = CovQ + A{ Q }.' * S * A{ Q };
            end
            Id = eye( numel( obj.Theta ) );
            CovQ = CovQ \ Id;
        end % getCovQ
    end % protected methods
end