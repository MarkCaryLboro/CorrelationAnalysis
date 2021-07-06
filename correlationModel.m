classdef ( Abstract = true ) correlationModel < handle
    % A container for the repeated measurements identification algorithm
    % for the battery test facility correlation experiment
    
    properties ( SetAccess = immutable, Abstract = true )
        Design                                                              % Design object
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
    
    properties( SetAccess = protected, Dependent = true )
        Factor  table                                                       % Factor information 
    end % dependent properties
    
    properties( Access = private, Dependent = true )
    end % Private and dependent properties
    
    methods ( Abstract = true )
        A = basis( obj, D )                                                 % Generate basis function matrix                                                        
        obj = fitModel( obj, D )                                            % Perform the required analysis
        obj = defineModel( obj )                                            % Define model
    end % abstract method signatures
    
    methods
    end % ordinary methods
    
    methods
        function Dc = codedDesignMatrix( obj )
            %--------------------------------------------------------------
            % Generate coded design matrix
            %
            % Dc = obj.codedDesignMatrix();
            %--------------------------------------------------------------
            Dc = obj.Design.testPlan();
        end % codedDesignMatrix
        
        function F = get.Factor( obj )
            % Return factor definition table
            F = obj.Design.Factor;
        end
    end % get set methods
    
    methods ( Access = protected )      
    end % protected methods
    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true )
    end % Static methods
end