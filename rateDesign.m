classdef rateDesign < correlationDesign
    % Rate test design object
      
    properties ( Constant = true )
        TestType    string          = "Rate";
    end % constant & abstract properties
    
    methods
        function obj = design( obj, Replicates, SortOrder )
            %--------------------------------------------------------------
            % Generate the design in natural units. Assumes a full
            % factorial. Output is for one-replicate
            %
            % obj = obj.design( Replicates, SortOrder );
            %
            % Input Arguments (Name, Value) Pairs:
            %
            % Replicates    --> (int8) number of replicates.
            % SortOrder     --> (int8) vector of sort columns.
            %--------------------------------------------------------------
            if ( nargin < 2 ) || ( Replicates < 1 )
                Replicates = 3;
            end
            if ( nargin < 3 ) || ~isnumeric( SortOrder ) || ( numel( SortOrder ) ~= obj.NumFac )
                SortOrder = obj.getStandardOrder();
            end
            obj = obj.setReplicates( Replicates );
            T = fullfact( obj.Levels );
            %--------------------------------------------------------------
            % Convert to engineering units & replicate
            %--------------------------------------------------------------
            T = obj.mapLevels( T );
            T = repmat( T, obj.Reps, 1 );
            T = array2table( T );
            T.Properties.VariableNames = ...
                string( obj.Factor.Properties.RowNames ).';
            %--------------------------------------------------------------
            % Assign levels for categorical factors
            %--------------------------------------------------------------
            VarNames = string( T.Properties.VariableNames );
            for Q = 1:obj.NumFac
                if ( obj.Factor{ Q, "Type" } == "CATEGORICAL" )
                    Vs = T{ :, Q };
                    Vars = obj.Factor{ Q, "Levels" };
                    Vars = Vars{ : };
                    C = categorical( Vs, ( 1:obj.Factor{Q, "NumLevels" } ),...
                                          Vars );
                    T.( VarNames( Q ) ) = C;                  
                end
            end
            obj.D = T;
            %--------------------------------------------------------------
            % Sort the design
            %--------------------------------------------------------------
            obj = obj.setSortOrder( SortOrder );
            V = obj.D.Properties.VariableNames( obj.Order );
            obj.D = sortrows( obj.D, V );          
        end % design
        
        function obj = setSortOrder( obj, SortOrder )
            %--------------------------------------------------------------
            % Set the order by which columns are sorted
            %
            % obj = obj.setSortOrder( SortOrder );
            %
            % Input Arguments:
            %
            % SortOrder     --> (int8) order in which to sort columns
            %--------------------------------------------------------------
            arguments
                obj         (1,1)   rateDesign
                SortOrder   (1,:)   int8        { mustBePositive( SortOrder ) }
            end
            UniqueOrder = unique( SortOrder );
            IsUnique = ( numel( UniqueOrder ) == numel( SortOrder ) );
            IsInRange = ( max( SortOrder ) == obj.NumFac ) & ...
                        ( min( SortOrder ) == 1 );
            Ok = IsUnique & IsInRange;
            if Ok
                obj.Order = SortOrder;
            else
                obj.Order = 1:obj.NumFac;
            end
        end % setSortOrder
        
        function T = mapLevels( obj, T )
            %--------------------------------------------------------------
            % Map levels of the design
            %
            % T = obj.mapLevels( T );
            %
            % Input Arguments:
            %
            % T     --> (double) Test plan matrix
            %--------------------------------------------------------------
            for Q = 1:obj.NumFac
                if ( obj.Factor.Type( Q ) == "CONTINUOUS" )
                    Lev = obj.Factor{ Q, "Levels" };
                    if iscell( Lev )
                        Lev = Lev{ : };
                    end
                    T( :, Q ) = Lev( T( :, Q ) ).';
                end
            end
        end % mapLevels
    end % constructor and ordinary methods
    
    methods ( Access = protected )
        function S = getStandardOrder( obj )
            %--------------------------------------------------------------
            % Return the standard order. Sort by categorical variables
            % first and then continuous. Assumes the lower the number of
            % levels the more difficult the factor is to change.
            %
            % S = obj.getStandardOrder();
            %--------------------------------------------------------------
            [ ~, Idx ] = sort( obj.Factor.NumLevels );
            C = ( obj.Factor.Type == "CATEGORICAL" );
            S = [ Idx( C ); Idx( ~C ) ].';
        end % getStandardOrder
    end % protected methods
end % correlationDesign