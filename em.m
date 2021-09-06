classdef em < mle
    
    properties ( Constant = true ) 
        Algorithm       mleAlgorithms            = "em"
    end % Constant & abstract properties
    
    properties ( SetAccess = protected )
        Bi              double
    end % protected properties
    
    properties ( SetAccess = protected, Dependent = true )
        D               double                                              % level-2 covariance matrix
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
            obj = obj.startingValues( A, B );
            obj = obj.costFcn( A, X, B );
            obj.CovQ = obj.getCovQ( A, X );
        end % mleRegTemplate
        
        function obj = startingValues( obj, A, B )
            %--------------------------------------------------------------
            % Calculate starting values for Theta and Omega properties
            %
            % [ Q, W ] = obj.startingValues( A, B );
            %
            % Input Arguments:
            %
            % A     --> (cell) array of level-2 regression matrices
            % B     --> (double) (pxN) array of 
            %--------------------------------------------------------------
            obj = obj.startingOmega( B );
            obj = obj.startingTheta( A, B );
        end % startingValues
        
        function obj = costFcn( obj, A, X, B )
            %--------------------------------------------------------------
            % EM algorithm cost function
            %
            % obj = obj.costFcn( A, X, B );
            %
            % Input Arguments:
            %
            % A     --> (cell) (1xm) level-2 regression matrices
            % X     --> (cell) (1xm) level-1 information matrices
            % B     --> (pxm) Matrix of level-1 model estimates
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   em          { mustBeNonempty( obj ) }
                A               cell        { mustBeNonempty( A ) }
                X               cell        { mustBeNonempty( X ) }
                B               double      { mustBeNonempty( B ) }
            end
            [ Sz, M ] = size( B );
            StopFlg = false;
            while ~StopFlg
                Di = obj.D\eye( Sz );
                obj.Bi = zeros( size( B ) );
                C = cell( 1, Sz );
                %----------------------------------------------------------
                % E-Step - produce refined estimates of the level-1 fit
                % coefficients
                %----------------------------------------------------------
                for Q = 1:M
                    C{ Q } = ( X{ Q } + Di );
                    C{ Q } = C{ Q }\eye( Sz );
                    obj.Bi( :, Q ) = C{ Q }*( X{ Q }*B( :, Q ) +...
                                     Di*A{ Q }*obj.Theta);
                end
                %----------------------------------------------------------
                % M-step - obtain updated estimates of the population
                % parameters
                %
                % 1. Level-2 regression coefficients.
                %----------------------------------------------------------
                ATDiA = A{ 1 }.' * Di * A{ 1 };
                for Q = 2:M
                    ATDiA = ATDiA + A{ Q }.' * Di * A{ Q };
                end
                ATDiA = ATDiA \ eye( size( ATDiA, 2 ) );
                T = zeros( size( obj.Theta ) );
                for Q = 1:M
                    W = ATDiA * A{ Q }.' * Di;
                    T = T + W * obj.Bi( :, Q );
                end
                StopTheta = 100 * norm(obj.Theta - T ) / norm( T );
                StopTheta = ( StopTheta < 0.0001 );
                obj.Theta = T;
                %----------------------------------------------------------
                % M-step - obtain updated estimates of the population
                % parameters
                %
                % 2. Level-2 covariance matrix.
                %----------------------------------------------------------
                D_ = zeros( size( obj.D ) );
                for Q = 1:M
                    R = ( obj.Bi - A{ Q } * obj.Theta );
                    D_ = C{ Q } + R * R.';
                end
                D_ = D_ / M;
                W = obj.getOmega( D_ );
                StopOmega = 100 * ( norm( obj.Omega - W ) / norm( W ) );
                StopOmega = ( StopOmega < 0.0001 );
                obj.Omega = W;
                StopFlg = ( StopTheta & StopOmega );
            end
        end % costFcn
    end % constructor and ordinary methods
    
    methods 
        function D = get.D( obj )
            % Fetch covariance matrix
            T = numel( obj.Omega );
            Sz = max( roots( [ 0.5, 0.5 -T ] ) );
            D = obj.createD( Sz );
        end
    end % Get/Set methods
    
    methods ( Access = private )
        function D = createD( obj, Sz )
            %--------------------------------------------------------------
            % Return the current level-2 covariance matrix
            %
            % D = obj.createD( Sz );
            %
            % Input Arguments:
            %
            % Sz    --> (double) size of covariance matrix
            %--------------------------------------------------------------
            Idx = sub2ind( [ Sz Sz ], obj.I, obj.J );
            D = zeros( Sz );
            D( Idx )  = obj.Omega;
            D = D + tril( D, -1 ).';
        end % createD
        
        function W = getOmega( obj, D )
            %--------------------------------------------------------------
            % Update the level-2 covariance parameters
            %
            % W = obj.getOmega( D );
            %
            % Input Arguments:
            %
            % D     --> (double) New level-2 covariance matrix
            %--------------------------------------------------------------
            Sz = min( size( D ) );
            Idx = sub2ind( [ Sz Sz ], obj.I, obj.J );
            W = D( Idx );
        end % getOmega
        
        function obj = startingTheta( obj, A, B )
            %--------------------------------------------------------------
            % Compute the starting Theta vector for the level-2 regression
            % model
            %
            % Input Arguments:
            %
            % A     --> (1xm) cell of level-2 regression matrices
            % B     --> (pxm) Matrix of level-1 model coefficients
            %--------------------------------------------------------------
            M = size( B, 2 );                                               % Number of sweeps
            %--------------------------------------------------------------
            % Initialise the sums
            %--------------------------------------------------------------
            ATA = A{ 1 }.'*A{ 1 };
            ATB = A{ 1 }.'*B( :, 1 );
            for Q = 2:M
                ATA = ATA + A{ Q }.'*A{ Q };
                ATB = ATB + A{ Q }.'*B( :, Q );
            end
            I = eye( size( ATA, 1 ) );
            ATA = ATA\I;
            obj.Theta = ATA*ATB;
        end % startingTheta
        
        function obj = startingOmega( obj, B )
            %--------------------------------------------------------------
            % Compute the starting Omega vector for the level-2 covariance
            % model parameters and the corresponding subscript indexes
            %
            % Input Arguments:
            %
            % B     --> (pxm) Matrix of level-1 model estimates
            %--------------------------------------------------------------
            D_ = cov( B.' );
            C = tril( ones( size( D_ ) ) );
            P = size( D_, 1 );
            Idx = ( C > 0 );
            [ I, J ] = ind2sub( size( D_ ), 1:numel( D_ ) );
            I = reshape( I, P, P );
            J = reshape( J, P, P );
            obj.I = I( Idx );
            obj.J = J( Idx );
            W = D_( Idx );
            obj.Omega = W( : );
        end
    end % private methods
end % em