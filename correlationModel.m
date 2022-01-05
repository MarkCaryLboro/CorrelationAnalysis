classdef ( Abstract = true ) correlationModel < handle
    % A container for the for the battery test facility correlation
    % experiment analyses
    
    properties ( SetAccess = immutable, Abstract = true )
        Design                                                              % Design object
    end % immutable properties
    
    properties ( SetAccess = protected, Abstract = true )
    end % protected properties
    
    properties ( Constant = true, Abstract = true )
        ModelName   string                                                  % Name of model
    end % Constant & abstract properties
    
    properties ( SetAccess = protected, Dependent = true )
        NumFac      double                                                  % Number of design factors
    end % dependent properties
    
    properties ( Access = private )
    end % private properties
    
    properties( SetAccess = protected, Dependent = true )
        Factor              table                                           % Factor information
        Dc                  double                                          % Coded design matrix
        FacNames            string                                          % DoE factor names
    end % dependent properties
    
    properties( Access = private, Dependent = true )
    end % Private and dependent properties
    
    methods ( Abstract = true )
        A = basis( obj, X )                                                 % Generate basis function matrix
        obj = fitModel( obj, D )                                            % Perform the required analysis
        obj = defineModel( obj, Type )                                      % Define model
        Z = predictions( obj, X )                                           % Predictions
    end % abstract method signatures
    
    methods
    end % ordinary methods
    
    methods
        function N = get.NumFac( obj )
            % Return number of factors
            N = obj.Design.NumFac;
        end
        
        function Dc = get.Dc( obj )
            % Get coded design matrix
            Dc = obj.Design.Design;
            Dc.( obj.Facility ) = double( Dc.( obj.Facility ) );
            Dc = table2array( Dc );
            Dc = obj.Design.code( Dc );
        end % codedDesignMatrix
        
        function F = get.Factor( obj )
            % Return factor definition table
            F = obj.Design.Factor;
        end
        
        function F = get.FacNames( obj )
            % Return the factor names as a string
            F = obj.Design.FacNames;
        end
    end % get set methods
    
    methods ( Access = protected )
    end % protected methods
    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true )
    end % Static methods
end