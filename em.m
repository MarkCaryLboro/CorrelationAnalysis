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
            P = any( B ~= 0 );
            B = B( :, P );
            [ Sz, M ] = size( B );
            StopFlg = false;
            Iteration = 0;
            while ~StopFlg
                Iteration = Iteration + 1;
                Di = obj.D\eye( Sz );
                obj.Bi = zeros( size( B ) );
                C = cell( 1, Sz );
                %----------------------------------------------------------
                % E-Step - produce refined estimates of the level-1 fit
                % coefficients
                %----------------------------------------------------------
                for Q = 1:M
                    try
                        C{ Q } = ( X{ Q } + Di );
                        C{ Q } = C{ Q }\eye( Sz );
                        obj.Bi( :, Q ) = C{ Q }*( X{ Q }*B( :, Q ) +...
                            Di*A{ Q }*obj.Theta);
                    catch
                    end
                end
                %----------------------------------------------------------
                % M-step - obtain updated estimates of the population
                % parameters
                %
                % 1. Level-2 regression coefficients.
                %----------------------------------------------------------
                ATDiA = [];
                for Q = 1:M
                    if isempty( ATDiA )
                        try
                            ATDiA = A{ Q }.' * Di * A{ Q };
                        catch
                        end
                    else
                        try
                            ATDiA = ATDiA + A{ Q }.' * Di * A{ Q };
                        catch
                        end
                    end
                end
                ATDiA = ATDiA \ eye( size( ATDiA, 2 ) );
                T = zeros( size( obj.Theta ) );
                for Q = 1:M
                    try
                        W = ATDiA * A{ Q }.' * Di;
                        T = T + W * obj.Bi( :, Q );
                    catch
                    end
                end
                StopTheta = norm(obj.Theta - T ) / norm( T );
                fprintf('\n Iteration %3.0f: StopTheta = %6.5f', ...
                                                    Iteration, StopTheta );
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
                    try
                        R = ( obj.Bi - A{ Q } * obj.Theta );
                        D_ = C{ Q } + R * R.';
                    catch
                    end
                end
                D_ = D_ / M;
                W = obj.getOmega( D_ );
                StopOmega = ( norm( obj.Omega - W ) / norm( W ) );
                fprintf(', StopOmega = %6.5f\n', StopOmega );
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
            P = any( B ~= 0 );                                              % Data present
            M = size( B, 2 );                                               % Number of sweeps
            %--------------------------------------------------------------
            % Initialise the sums
            %--------------------------------------------------------------
            ATA = [];
            ATB = [];
            for Q = 1:M
                if P( Q )
                    %------------------------------------------------------
                    % Process non-zero data only
                    %------------------------------------------------------
                    if isempty( ATA )
                        %--------------------------------------------------
                        % Initialise sum
                        %--------------------------------------------------
                        ATA = A{ Q }.'*A{ Q };
                    else
                        %--------------------------------------------------
                        % Update sum
                        %--------------------------------------------------
                        ATA = ATA + A{ Q }.'*A{ Q };
                    end
                    if isempty( ATB )
                        %--------------------------------------------------
                        % Initialise sum
                        %--------------------------------------------------
                        ATB = A{ Q }.'*B( :, Q );
                    else
                        %--------------------------------------------------
                        % Update sum
                        %--------------------------------------------------
                        ATB = ATB + A{ Q }.'*B( :, Q );
                    end
                end
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