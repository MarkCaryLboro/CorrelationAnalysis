classdef em < mle
    
    properties ( Constant = true ) 
        Algorithm       mleAlgorithms            = "em"
    end % Constant & abstract properties
    
    methods 
        function [ Q, W ] = costFcn( obj, Q, W, A, B )
        end % costFcn
    end % constructor and ordinary methods
end % em