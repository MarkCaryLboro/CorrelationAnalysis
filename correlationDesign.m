classdef ( Abstract = true ) correlationDesign < handle
    % Abstract interface class for correlation study designs
    
    properties ( SetAccess = immutable )
    end % immutable properties
    
    properties ( SetAccess = protected )
        Factor      table                         = table.empty( 0, 6 )     % Factor definition table
        Reps(1,1)   int8                          = 3                       % Number of replicates
    end % protected properties
    
    properties ( Access = protected )
        D           table                                                   % Design table
    end % protected  properties
    
    properties ( SetAccess = protected, Dependent = true )
        Levels      int8                                                    % Number of levels for each factor
        NumFac      double                                                  % Number of factors
        Design      table                                                   
    end % Dependent properties    
    
    methods ( Abstract = true )
        obj = design( obj )                                                 % Create design
    end % abstract method signatures
    
    methods
        function obj = setReplicates( obj, N )
            %--------------------------------------------------------------
            % Set number of replicates for the design
            %
            % obj = obj.setReplicates( N );
            %
            % Input Arguments:
            %
            % N     --> Number of replicates
            %--------------------------------------------------------------
            arguments
                obj 
                N(1,1)    double      { mustBePositive( N ) }   = 3 
            end
            obj.Reps = int8( N );
        end % setReplicates
        
        function obj = addFactor( obj, Name, Symbol, Units, Levels, Type )
            %--------------------------------------------------------------
            % Add a factor to the Factor definition table
            %
            % obj = obj.addFactor( Name, Symbol, Units, Levels );
            %
            % Input Arguments:
            %
            % Name      --> (string) (px1) Array of factor names
            % Symbol    --> (string) (px1) Array of factor symbols
            % Units     --> (string) (px1) Array of factor units
            % Levels    --> (cell) Factor levels
            % Type      --> (string) Either {"continuous"} or "categorical"
            %--------------------------------------------------------------
            arguments
                obj
                Name(:,1)       string                  {mustBeNonempty( Name ) }
                Symbol(:,1)    string                   {mustBeNonempty( Symbol ) }
                Units(:,1)      string
                Levels(:,1)     cell                    {mustBeNonempty( Levels ) }
                Type(:,1)       correlationVariableType 
            end
            P = numel( Name );
            %--------------------------------------------------------------
            % Parse inputs
            %--------------------------------------------------------------
            if ( nargin < 6 ) || ~isa( Type, "correlationVariableType" )
                Type = repmat( correlationVariableType( "continuous" ), P, 1 );                        % Apply default
            end
            if isempty( Units )
                Units = repmat( "N/A", P, 1 );
            end
            %--------------------------------------------------------------
            % Calculate Min & Max levels. If a categorical variable then
            % assign an integer coding from 1:N, where N is the number of
            % levels assigned to the factor.
            %--------------------------------------------------------------
            Max = obj.getMaxLevels( Levels, Type);
            Min = obj.getMinLevels( Levels, Type);
            %--------------------------------------------------------------
            % Generate a table of factor data
            %--------------------------------------------------------------
            T = table( Symbol, Units, Min, Max, Levels, Type );
            T.Properties.RowNames = Name;
            if isempty( obj.Factor )
                %----------------------------------------------------------
                % Assign the Factor table variable names if not defined
                %----------------------------------------------------------
                obj.Factor.Properties.VariableNames =...
                    T.Properties.VariableNames;
            end
            %--------------------------------------------------------------
            % Are the rows unique? If not then overwrite the original
            % rows in the factor definition table
            %--------------------------------------------------------------
            FacExist = string( obj.Factor.Properties.RowNames );
            for Q = 1:numel( Name )
                Idx = strcmpi( Name( Q ), FacExist );
                if isempty( Idx )
                    %------------------------------------------------------
                    % Assign new row
                    %------------------------------------------------------
                    obj.Factor = vertcat( obj.Factor, T( Name( Q ), : ) );
                else
                    %------------------------------------------------------
                    % Overwrite existing row
                    %------------------------------------------------------
                    obj.Factor( Idx, : ) = T( Name( Q ), : );
                end
            end
        end % addFactor
        
        function T = testPlan( obj )
        end % testPlan
    end % Ordinary methods
    
    methods        
        function L = get.Levels( obj )
            % Return a vector of factor levels
            L = cellfun( @numel, obj.Factor.Levels ).';
        end
        
        function N = get.NumFac( obj )
            % Return number of factors
            N = height( obj.Factor );
        end
        
        function D_ = get.Design( obj )
            % Return the design in engineering units
            D_ = obj.D;
            Cat = strcmpi( obj.Factor.Type, "categorical" );
            N = sum( Cat );
            Vcat = obj.Factor.Properties.RowNames( Cat );                   % Point to categorical variables
            Vcat = string( Vcat );
            L = obj.Levels( Cat );
            Cats = obj.Factor{ Cat, "Levels" };
            T = repmat( "", height( D_ ), 1 );
            for Q = 1:N
                V = string( Cats{ Q } );
                for R = 1:L( Q )
                    %------------------------------------------------------
                    % substitute the numerical coding for the fixed levels
                    % for each categorical variable
                    %------------------------------------------------------
                    Idx = ( D_.( Vcat( Q ) ) == R );
                    T( Idx ) = V( R );
                end
                D_.( Vcat( Q ) ) = T;
            end
        end
    end % Get set methods    
    
    methods ( Static = true )
        function Max = getMaxLevels( Levels, Type)
            %--------------------------------------------------------------
            % Return Max levels for all factors... If categorical variables
            % are present then assign an integer code to them.
            %
            % Max = obj.getMaxLevels( Levels, Type);
            %
            % Levels    --> (cell) Factor levels
            % Type      --> (string) Either {"continuous"} or "categorical"
            %--------------------------------------------------------------
            Cat = ( Type == "CATEGORICAL" ); 
            Con = ( Type == "CONTINUOUS" );
            Max = zeros( size( Type ) );
            Max( Con ) = cellfun( @max, Levels( Con ) );
            Max( Cat ) = cellfun( @numel, Levels( Cat ) );
        end % getMaxLevels
                
        function Min = getMinLevels( Levels, Type)
            %--------------------------------------------------------------
            % Return Min levels for all factors... If categorical variables
            % are present then assign an integer code to them.
            %
            % Max = obj.getMaxLevels( Levels, Type);
            %
            % Levels    --> (cell) Factor levels
            % Type      --> (string) Either {"continuous"} or "categorical"
            %--------------------------------------------------------------
            Con = ( Type == "CONTINUOUS" );
            Min = ones( size( Type ) );
            Min( Con ) = cellfun( @min, Levels( Con ) );
        end % getMinLevels
        
        function Dc = code( D, A, B, Ac, Bc )
            %--------------------------------------------------------------
            % Code the level-2 covariate data onto an arbitrary scale...
            % [ A, B ] --> [ Ac, Bc ].
            %
            %
            % Dc = obj.code( D, A, B, Ac, Bc );
            %
            % Input Arguments:
            %
            % D     --> Engineering data vector
            % A     --> Lower bound for engineering units
            % B     --> Upper bound for engineering units
            % Ac    --> Lower bound for coded units
            % Bc    --> Upper bound for coded units
            %--------------------------------------------------------------
            G = ( Bc - Ac)./( B - A );
            Dc = G.*( D - A ) + Ac;
        end % code 
        
        function D = decode( Dc, A, B, Ac, Bc )
            %--------------------------------------------------------------
            % convert coded data to engineering units
            %
            % D = obj.decode( Zc, A, B, Ac, Bc );
            %
            % Input Arguments:
            %
            % Zc    --> Coded data vector
            % A     --> Lower bound for engineering units
            % B     --> Upper bound for engineering units
            % Ac    --> Lower bound for coded units
            % Bc    --> Upper bound for coded units
            %--------------------------------------------------------------
            G = ( Bc - Ac)./( B - A );
            D = ( Dc - Ac )./G + A;
        end % decode
    end % Static methods
end % correlationDesign