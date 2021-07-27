classdef ( Abstract = true ) mle
    % A class to perfomr the mle analysis for the battery facility test
    % correlation study
    
    properties ( Constant = true, Abstract = true )
        Algorithm       mleAlgorithms
    end % Constant & abstract properties
    
    properties ( SetAccess = protected, Dependent = true )
    end % dependent properties
    
    methods ( Abstract = true )
        L = costFcn( obj, Theta, A, B ) 
    end % abstract signatures
    
    methods
        function obj = mleRegTemplate( obj, A, X, B, S )
            %--------------------------------------------------------------
            % Template for the analysis method
            %
            % obj = obj.mleRegTemplate( A, X, B, S );
            %
            % Input Arguments:
            %
            % A     --> (1xm) (cell) array of coded level-2 covariate 
            %                        matrices
            % X     --> (1xm) (cell) array of level-1 covariate matrices
            % B     --> (2xm) array of level-1 coefficient estimates
            % S     --> (1xm) (cell) array of level-1 information matrices
            %--------------------------------------------------------------
            
        end % mleRegTemplate
        
        function [ T, W ] = startingValues( obj )
            %--------------------------------------------------------------
            % Calculate starting values for Theta and Omega properties
            %
            % [ T, W ] = startingValues( obj );
            %
            % Output Arguments:
            %
            % T     --> Initial level-2 regression coefficients
            % W     --> Initial level-2 covariance model coefficients
            %--------------------------------------------------------------
            
        end % startingValues
    end % constructor and ordinary methods
    
    
end