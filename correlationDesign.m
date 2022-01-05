classdef ( Abstract = true ) correlationDesign < handle
    % Abstract interface class for correlation study designs
    
    properties ( Constant = true, Abstract = true )
        TestType    string
    end % constant & abstract properties
    
    properties ( SetAccess = protected )
        Factor      table                         = table.empty( 0, 7 )     % Factor definition table
        Reps(1,1)   int8                          = 3                       % Number of replicates
        Order(1,:)  int8                                                    % Order of sort
    end % protected properties
    
    properties ( Access = protected )
        D           table                                                   % Design table (coded)
    end % protected  properties
    
    properties ( SetAccess = protected, Dependent = true )
        Levels      int8                                                    % Number of levels for each factor
        NumFac      double                                                  % Number of factors
        Design      table                                                   % Design table in engineering units
        Cat         logical                                                 % logical pointer to categorical variables
        NumCat      int8                                                    % Number of categorical variables
        NumCon      int8                                                    % Number of continuous factors
        FacNames    string                                                  % List of factor names
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
        
        function obj = addCatFactor( obj, Name, Symbol, Levels, ValueSet, CatNames )
            %--------------------------------------------------------------
            % Add a continuous factor to the Factor definition table
            %
            % obj = obj.addConFactor( Name, Symbol, Units, Levels,...
            %                         ValueSet, CatNames );
            %
            % Input Arguments:
            %
            % Name      --> (string) (px1) Array of factor names
            % Symbol    --> (string) (px1) Array of factor symbols
            % Levels    --> (cell) (px1) Cell array of factor levels
            % ValueSet  --> (cell) (px1) ordinal categories (numeric)
            % CatNames  --> (cell) (px1) category names (string)
            %--------------------------------------------------------------
            arguments
                obj
                Name(:,1)       string                  { mustBeNonempty( Name ) }
                Symbol(:,1)     string                  { mustBeNonempty( Symbol ) }
                Levels          cell                    { mustBeNonempty( Levels ) }
                ValueSet        cell                    { mustBeNonempty( ValueSet ) }
                CatNames        cell                    { mustBeNonempty( CatNames ) }
            end
            P = numel( Name );
            Type = correlationVariableType( "Cat" );
            Type = repmat( Type, P, 1 );
            Units = "N/A";
            Units = repmat( Units, P, 1 );
            Cats = cell( P, 1 );
            for Q = 1:P
                %----------------------------------------------------------
                % Create the categorical variables
                %----------------------------------------------------------
                Cats{ P } = categorical( Levels{ P }, ValueSet{ P }, ...
                                         CatNames{ P }, 'Ordinal', true );
            end
            %--------------------------------------------------------------
            % Calculate Min & Max levels. 
            %--------------------------------------------------------------
            Max = cellfun( @max, ValueSet );
            Min = cellfun( @min, ValueSet );
            NumLevels = cellfun( @numel, Cats );
            %--------------------------------------------------------------
            % Generate a table of factor data
            %--------------------------------------------------------------
            Levels = Cats;
            T = table( Symbol, Units, Min, Max, Levels, NumLevels, Type);
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
                if isempty( Idx ) || all( ~Idx )
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
        end % addCatFactor
        
        function obj = addConFactor( obj, Name, Symbol, Units, Levels )
            %--------------------------------------------------------------
            % Add a continuous factor to the Factor definition table
            %
            % obj = obj.addConFactor( Name, Symbol, Units, Levels, Type );
            %
            % Input Arguments:
            %
            % Name      --> (string) (px1) Array of factor names
            % Symbol    --> (string) (px1) Array of factor symbols
            % Units     --> (string) (px1) Array of factor units
            % Levels    --> (cell) (px1) Cell array of factor levels
            %--------------------------------------------------------------
            arguments
                obj
                Name(:,1)       string                  { mustBeNonempty( Name ) }
                Symbol(:,1)     string                  { mustBeNonempty( Symbol ) }
                Units(:,1)      string
                Levels          cell                    { mustBeNonempty( Levels ) }
            end
            P = numel( Name );
            Type = correlationVariableType( "Cont" );
            Type = repmat( Type, P, 1 );
            %--------------------------------------------------------------
            % Parse inputs
            %--------------------------------------------------------------
            if isempty( Units )
                Units = repmat( "N/A", P, 1 );
            end
            %--------------------------------------------------------------
            % Calculate Min & Max levels. 
            %--------------------------------------------------------------
            Max = cellfun( @max, Levels );
            Min = cellfun( @min, Levels );
            NumLevels = cellfun( @numel, Levels );
            %--------------------------------------------------------------
            % Generate a table of factor data
            %--------------------------------------------------------------
            T = table( Symbol, Units, Min, Max, Levels, NumLevels, Type );
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
                if isempty( Idx ) || all( ~Idx )
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
        end % addConFactor
        
        function [ T, Xc ] = export2ws( obj )
            %--------------------------------------------------------------
            % Export the design to the workspace in coded form. Output is 
            % either a table or an array.
            %
            % [ T, Xc ] = obj.export2ws();
            %
            % Output Arguments:
            %
            % T     --> Design (table)
            % Xc    --> Design matrix (double)
            %--------------------------------------------------------------
            T = obj.D;  
            if ( nargout == 2 )
                Xc = table2array( T );
            end
        end % export2ws
        
        function T = testPlan( obj, FileName )
            %--------------------------------------------------------------
            % Generate the experimental test plan.
            %
            % T = obj.testPlan( FileName );
            %
            % Input Arguments:
            %
            % FileName  --> Name of output file. The file is assumed to be
            %               an Excel spread sheet. If no path information 
            %               is provided, the file is stored in the current
            %               directory. Optional argument. (string)
            %
            % Output Arguments:
            %
            % T         --> (table) test plan.
            %--------------------------------------------------------------
            if ( nargin > 1 ) && isstring( FileName )
                Export2file = true;
            elseif ( nargin > 1 ) && ischar( FileName )
                Export2file = true;
            else
                Export2file = false;
            end
            %--------------------------------------------------------------
            % Generate test plan
            %--------------------------------------------------------------
            T = obj.Design;
            if Export2file
                FileName = string( FileName );
                [ Fpath, Fname, ~ ] = fileparts( FileName );
                if ~isfolder( Fpath )
                    Fpath = cd;                                             % Apply default
                end
                Ext = ".xlsx";
                Fname = strjoin( [ Fname, Ext ], '' );                      % Ensure is an "xlsx" file
                FileName = fullfile( Fpath, Fname );                        % Full file specification                    
                %----------------------------------------------------------
                % Write the test plan to an XLSX file
                %----------------------------------------------------------
                H = height( T );
                W = width( T );
                Start = "A1";
                Col = upper( string( char( W + 96 ) ) );
                Row = string( H );
                Finish = strjoin( [ Col, Row ], '' );
                writetable( T, FileName, 'Sheet', 1, 'Range', ...
                            strjoin( [ Start, Finish ], ":" ),...
                            'WriteRowNames', true );
            end
        end % testPlan
        

        function Dc = code( obj, D )
            %--------------------------------------------------------------
            % Code the level-2 covariate data onto the interval
            % [ A, B ] --> [ -1, 1 ]. 
            %
            % Dc = obj.code( D );
            %
            % Input Arguments:
            %
            % D     --> Engineering data vector
            %--------------------------------------------------------------
            [ G, C ] = obj.codeVars();
            Dc = G .* D + C;
        end % code 
        
        function D = decode( obj, Dc )
            %--------------------------------------------------------------
            % convert coded data to engineering units
            %
            % D = obj.decode( Dc );
            %
            % Input Arguments:
            %
            % Dc    --> Coded data vector
            %--------------------------------------------------------------
            [ G, C ] = obj.codeVars();
            D = ( Dc - C ) ./ G;
        end % decode
    end % Ordinary methods
    
    methods        
        function L = get.Levels( obj )
            % Return a vector of factor levels
            L = cellfun( @numel, obj.Factor.Levels ).';
        end
        
        function F = get.FacNames( obj )
            % Return list of factor names
            F = obj.Factor.Properties.RowNames;
            F = string( F );
            F = reshape( F, 1, numel( F ) );
        end
        
        function N = get.NumFac( obj )
            % Return number of factors
            N = height( obj.Factor );
        end
        
        function D_ = get.Design( obj )
            % Return the design in engineering units
            D_ = obj.D;
            D_ = table2array( D_ );
            D_ = obj.decode( D_ );
            D_ = array2table( D_ );
            D_.Properties.VariableNames = obj.FacNames;
            F = D_.Facility;
            F = correlationFacility( F );
            D_.Facility = F;
        end
        
        function Cat = get.Cat( obj )
            % Return logical pointer to categorical variables
             Cat = strcmpi( obj.Factor.Type, "categorical" ).'; 
        end
        
        function Nc = get.NumCat( obj )
            % Return number of categorical variables
            Nc = int8( sum( obj.Cat ) );
        end
        
        function Nc = get.NumCon( obj )
            % Return number of continuous factors
            Nc = obj.NumFac - obj.NumCat;
        end
    end % Get set methods    
    
    methods ( Access = protected )
        function T = sortDesign( obj, T, Vars )
            %--------------------------------------------------------------
            % Sort the design by categorical variables first and then in
            % terms of number of levels of the continuous variables. It is
            % assumed the lower the number of levels the more difficult the
            % factor is to set. Refer to this as standard order
            %
            % T = obj.sortDesign( T );
            %
            % Use this syntax to sort the design in the order specified
            %
            % T = obj.sortDesign( T, Vars );
            %
            % Input Arguments:
            % 
            % T     --> Design table
            % Vars  --> List of design variables to sort design by
            %--------------------------------------------------------------
            if ( nargin < 3 )
                Vars = obj.stdOrder();
            end
            T = sortrows( T, Vars );
        end % sortDesign
    end % protected methods
    
    methods ( Access = private ) 
        function [ G, C ] = codeVars( obj )
            %--------------------------------------------------------------
            % Return gradient and intercept for coding calculations
            %
            % [ G, C ] = obj.codeVars();
            %
            % Output Arguments:
            %
            % G     --> Gradient
            % C     --> Intercept
            %
            % Xc = G * X + C
            %--------------------------------------------------------------
            A = obj.Factor.Min.';
            B = obj.Factor.Max.';
            G = 2./( B - A );
            C = ( B + A ) ./ ( A - B );
        end % codeVars
    end % private methods
    
    methods ( Static = true, Access = protected )
    end % Static methods
end % correlationDesign