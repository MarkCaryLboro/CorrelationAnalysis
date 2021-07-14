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
    end % constructor and ordinary methods
    
    
end