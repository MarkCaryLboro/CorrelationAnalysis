classdef em < mle
    
    properties ( Constant = true ) 
        Algorithm       mleAlgorithms            = "em"
    end % Constant & abstract properties
    
    methods 
        function [ Q, D ] = costFcn( obj, D, Q, A, B )
            %--------------------------------------------------------------
            % EM algorithm cost function
            %
            % [ Q, D ] = obj.costFcn( D, A, B );
            %
            % Input Arguments:
            %
            % D     --> ( double) Level-2 covariance matrix
            % A     --> (cell) (1xm) level-2 regression matrices
            % B     --> (pxm) Matrix of level-1 model estimates
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   em          { mustBeNonempty( obj ) }
                D               double      { mustBeNonempty( D ) }
                Q               double      { mustBeNonempty( Q ) }
                A               cell        { mustBeNonempty( A ) }
                B               double      { mustBeNonempty( B ) }
            end
            M = numel( A );
            %--------------------------------------------------------------
            % E-Step - produce refined estimates of the level-1 fit
            % coefficients
            %--------------------------------------------------------------
            
        end % costFcn
    end % constructor and ordinary methods
end % em