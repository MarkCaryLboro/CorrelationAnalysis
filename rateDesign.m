classdef rateDesign < correlationDesign
    % Rate test design object
      
    properties ( SetAccess = protected )
    end % protected properties
    
    methods
        function obj = design( obj, Replicates )
            %--------------------------------------------------------------
            % Generate the design in natural units. Assumes a full
            % factorial. Output is for one-replicate
            %
            % obj = obj.design();
            % obj = obj.design( Replicates );
            %
            % Input Arguments:
            %
            % Replicates    --> (int8) number of replicates.
            %--------------------------------------------------------------
            arguments
                obj         rateDesign
                Replicates  int8        { mustBePositive( Replicates ) } = 3
            end
            obj = obj.setReplicates( Replicates );
            T = fullfact( obj.Levels );
            %--------------------------------------------------------------
            % Convert to engineering units
            %--------------------------------------------------------------
            Ac = obj.Factor.Min.';
            Bc = obj.Factor.Max.';
            T = obj.code( T, min( T ), max( T ), Ac, Bc );
            obj.D = array2table( T );
            obj.D.Properties.VariableNames = ...
                string( obj.Factor.Properties.RowNames ).';
            obj.D = obj.sortDesign( obj.D );
            H = height( obj.D );
            RunNumber = ( 1:H ).';
            RunNumber = array2table( RunNumber );
            obj.D = horzcat( RunNumber, obj.D );
        end % design
    end % constructor and ordinary methods
end % correlationDesign