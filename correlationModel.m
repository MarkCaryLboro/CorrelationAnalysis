classdef correlationModel
    % A container for the repeated measurements identification algorithm
    % for the battery test facility correlation experiment
    
    properties ( SetAccess = immutable, Abstract = true )
        Design      correlationDesign                                       % Design object
    end % immutable properties
    
    properties ( SetAccess = protected, Abstract = true )
    end % protected properties
    
    properties ( Constant = true, Abstract = true )
        ModelName   string                                                  % Name of model
    end % Constant & abstract properties
    
    properties ( Constant = true )
    end % constant properties
    
    properties ( Access = private )
    end % private properties
    
    properties( Access = private, Dependent = true )
        Dc      double                                                      % Coded design matrix
    end % Private and dependent properties
    
    methods ( Abstract = true )
        A = basis( obj, D )                                                 % Generate basis function matrix                                                        
        obj = fitModel( obj, D )                                            % Perform the required analysis
        obj = defineModel( obj )
    end % abstract method signatures
    
    methods
    end % ordinary methods
    
    methods
        function Dc = get.Dc( obj )
        end
    end % get set methods
    
    methods ( Access = protected )      
    end % protected methods
    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true )
    end % Static methods
end