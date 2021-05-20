classdef correlationModel
    % A container for the repeated measurements identification algorithm
    % for the battery test facility correlation experiment
    
    properties ( SetAccess = immutable )
    end % immutable properties
    
    methods ( Abstract = true )
        A = Basis( obj, D )                                                 %                                                         
    end % abstract method signatures
    
    methods
    end % constructor and ordinary methods
end