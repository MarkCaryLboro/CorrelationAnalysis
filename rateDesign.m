classdef rateDesign < correlationDesign
    % Rate test design object
      
    properties ( SetAccess = protected )
    end % protected properties
    
    methods
        function obj = design( obj )
            %--------------------------------------------------------------
            % Generate the design in natural units. Assumes a full
            % factorial. Output is for one-replicate
            %
            % obj = obj.design();
            %--------------------------------------------------------------
            T = fullfact( obj.Levels );
            %--------------------------------------------------------------
            % Convert to engineering units
            %--------------------------------------------------------------
            Ac = obj.Factor.Min.';
            Bc = obj.Factor.Max.';
            T = obj.code( T, min( T ), max( T ), Ac, Bc );
            obj.D = array2table( T );
            obj.D.Properties.VariableNames = obj.Factor.Properties.RowNames;
        end % design
    end % constructor and ordinary methods
end % correlationDesign