classdef correlationAnalysis
    % A class to analyse the data from the correlation experiment to assess
    % the equivalency of different battery test facilities
    
    properties ( SetAccess = protected )
        DataObj     (1,1)           { mustBeDataObj( DataObj ) }            % Data object                      
        DesignObj   (1,1)           { mustBeDesignObj( DesignObj ) }        % Design object
        ModelObj    (1,1)           { mustBeModelObj( ModelObj ) }          % Model to be fitted
        ReportObj   (1,1)           { mustBeReportObj( ReportObj ) }        % Report generator
        Facility    (1,1)             string      = "Facility"              % Facility variable
        MatchList                     table                                 % List of matched factor and signal names
        MatchedData 	              table                                 % Matched data to design
        Response    (1,1)             string      = "DischargeCapacity"     % Response variable
        RespUnits   (1,1)             string      = "[Ah]"                  % Response units
        Xname       (1,1)             string      = "Cycle"                 % Level-1 covariate variable
    end
    
    properties ( SetAccess = protected, Dependent = true )
        TestType    (1,1)           string                                  % Analysis type
        NumFacLvl   (1,1)           double                                  % Number of facilities
        FacNames    (1,:)           string                                  % Design Factor Names
        FacSymbols  (1,:)           string                                  % Design Factor Symbols
        NumTests    (1,1)           double                                  % Number of cells
        ModelSym    (1,:)           string                                  % Model basis functions
    end % Dependent properties
    
    methods
        function obj = correlationAnalysis( DataObj, DesignObj, ModelObj, ReportObj )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = correlatioAnalysis( DataObj, DesignObj, ModelObj,...
            %                           ReportObj );
            %
            % Input Arguments:
            %
            % DataObj       --> Correlation DataStore object
            % DesignObj     --> Correlation Design object
            % ModelObj      --> Correlation Model Object
            % ReportObj     --> Correlation analysis report object
            %--------------------------------------------------------------
            obj.DataObj = DataObj;
            obj.DesignObj = DesignObj;
            obj.ModelObj = ModelObj;
            obj.ReportObj = ReportObj;
            obj = obj.mapDataChannels();
            obj = obj.matchData2Design;
        end % constructor
        
        function Ai = getAi( obj )
            %--------------------------------------------------------------
            % Return the (1xM) cell array of level-2 regression matrices
            %
            % Ai = obj.getAi();
            %--------------------------------------------------------------
            D = obj.getData( true );     
            Ai = obj.ModelObj.getAi( D );
        end % getAi
                        
        function obj = fitModel( obj )
            %--------------------------------------------------------------
            % Identify the model parameters from the data
            %
            % obj = obj.fitModel()
            %--------------------------------------------------------------
            D = obj.getData( true );     
            S = obj.genModelOpts();
            obj.ModelObj = obj.ModelObj.fitModel( D, S );
        end % fitModel
        
        function obj = setFacilityVariable( obj, F )
            %--------------------------------------------------------------
            % Set the variable name for the facility factor (design object)
            %
            % obj = setFacilityVariable( F );
            %
            % Input Arguments:
            %
            % F     --> (string) Facility variable name.
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationAnalysis
                F       (1,1)   string                  = "Facility"
            end
            Factors = obj.DesignObj.FacNames;
            FacIdx = strcmpi( F, Factors );
            if any( FacIdx )
                %----------------------------------------------------------
                % Set the name if a categorical variable
                %----------------------------------------------------------
                if ( obj.DesignObj.Factor{ F, "Type" } == "CATEGORICAL" )
                    obj.Facility = Factors( FacIdx );
                    obj.ModelObj.Facility = obj.Facility;
                else
                    warning( 'Facility variable must be "CATEGORICAL"' );
                end
            else
                warning( 'Variable "%s" not recognised', F );
            end
        end % setFacilityVariable
        
        function obj = matchData2Design( obj )
            %--------------------------------------------------------------
            % Match the data to the design and return the list of
            % replicates
            %
            % obj = obj.matchData2Design();
            %--------------------------------------------------------------
            D = obj.getData( true );
            %--------------------------------------------------------------
            % Generate the data groups
            %--------------------------------------------------------------
            U = table2array( D( :, obj.FacNames  ) );
            %--------------------------------------------------------------
            % Generate the design groups
            %--------------------------------------------------------------
            [ ~, Tdes ] = findgroups( obj.DesignObj.Design );
            Tdes.( obj.Facility ) = double( Tdes.( obj.Facility ) );
            Tdes = unique( Tdes, 'stable' );
            N = height( Tdes );
            Replicates = cell( height( Tdes ), 1 );
            %--------------------------------------------------------------
            % Match the design to the data
            %--------------------------------------------------------------
            for Q = 1:N
                C = Tdes{ Q, : };
                Tol = eps( C );
                Idx = ( abs( U - C ) <= Tol );
                Idx = all( Idx, 2 );
                Sn = unique( string( D.SerialNumber( Idx ) ) ).';
                if isempty( Sn )
                    %------------------------------------------------------
                    % No replicates present
                    %------------------------------------------------------
                    Sn = NaN( 1, obj.DesignObj.Reps );
                elseif ( numel( Sn ) < obj.DesignObj.Reps )
                    %------------------------------------------------------
                    % Some replicates present
                    %------------------------------------------------------
                    Sn = [ Sn, NaN( 1,...
                                obj.DesignObj.Reps - numel( Sn ) ) ];       %#ok<AGROW>
                end
                Replicates{ Q } = Sn;
            end
            Replicates = cell2table( Replicates );
            obj.MatchedData = horzcat( Tdes, Replicates );
            obj.MatchedData.Facility = correlationFacility( ...
                                            obj.MatchedData.Facility );
        end % matchData2Design
       
        function obj = mapDataChannels( obj, DataChannels )
            %--------------------------------------------------------------
            % map the design factor names to the corresponding data signals
            % in the DataObj.
            %
            % obj = obj.mapDataChannels( DataChannels );
            %
            % Input Arguments:
            %
            % DataChannels  --> List of data channels to match.  
            %
            % Example:
            %
            % Assume that:
            %
            % obj.FacNames = [ "CRate"    "Temperature"    "Facility"]
            % obj.DataObj.Variables = ["BatteryName"    "SerialNumber",...
            %           "CRate"    "Cycle"    "Facility"  "Temperature",...  
            %           "DischargeCapacity"]
            %
            % Then:
            %
            % obj = obj.mapDataChannels( ["CRate", "Temperature",...
            % "Facility"] );  
            %
            % Matches the factor and signal names. The default is the
            % signal names are the factor names.
            %--------------------------------------------------------------
            arguments
                obj             (1,1)   correlationAnalysis
                DataChannels    (1,:)   string               = obj.FacNames
            end
            %----------------------------------------------------------
            % Apply the defaults
            %----------------------------------------------------------
            Ok = obj.DataObj.channelPresent( DataChannels );
            if all( Ok )
                %----------------------------------------------------------
                % Channels present so create match list table
                %----------------------------------------------------------
                DataChannels = reshape( DataChannels, numel( DataChannels ),...
                                        1 );
                DataChannels = array2table( DataChannels );
                DataChannels.Properties.RowNames = obj.FacNames;
                obj.MatchList = DataChannels;
            else
                %----------------------------------------------------------
                % Print out list of missing channels
                %----------------------------------------------------------
                obj.DataObj.missingChannels( DataChannels( ~Ok ) );
            end    
        end % mapDataChannels
        
        function H = hypothesisTest( obj, A, P )
            %--------------------------------------------------------------
            % Conduct multiple linear hypothesis test on Theta vector
            %
            % H = obj.hypothesisTest( obj, A, P)
            %
            % Input Arguments:
            %
            % A --> (double) (mxk) matrix of contrasts
            % P --> (double) Significance value for the test (0 < P < 0.2)
            %
            % Notes:
            %
            % If matrix "A" is not specified then it is assumed only the
            % facility terms require testing. Under these circumstances
            % "A" is automatically generated.
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationAnalysis
                A               double                    
                P       (1,1)   double                  { mustBeGreaterThan( P, 0 ),...
                                                          mustBeLessThan( P, 0.2 ) } = 0.05
            end
            if ( nargin < 2  || isempty( A ) )
                A = obj.getDefaultCon();
            end
            assert( size( A, 2 ) == numel( obj.ModelObj.Theta ), ...
                    'Number of columns of "A" must be %3.1f',...
                    numel( obj.ModelObj.Theta ) );
            H = obj.ReportObj.hypothesisTest( A, P );
        end % hypothesisTest
        
        function Z = predictions( obj, X )
            %--------------------------------------------------------------
            % Calculate predictions
            %
            % Z = obj.predictions( X );
            %
            % Input Arguments:
            %
            % X     --> Ageing conditions ( R x #factors );
            %
            % Output Arguments:
            %
            % Z     --> ( R x P ) matrix of level-1 coefficient vectors
            %--------------------------------------------------------------
            Z = obj.ModelObj.predictions( X );
        end % predictions
        
        function Ax = plot( obj )
            %--------------------------------------------------------------
            % Plot the data
            %
            % Ax = obj.plot()
            %
            % Output Arguments:
            %
            % Ax    --> Handles to plot axes.
            %--------------------------------------------------------------
            D = obj.getData( true );
            %--------------------------------------------------------------
            % Generate the required plot
            %--------------------------------------------------------------
            switch lower( obj.TestType )
                case "rate"
                    Ax = obj.plotRateData( D );
                case "pulse"
                    Ax = obj.plotPulseData( D );
                case "capacity"
            end
            %--------------------------------------------------------------
            % Ensure data axes have common limits
            %--------------------------------------------------------------
            obj.commonAxesLimits( Ax );
        end % plot
        
        function obj = setRespUnits( obj, Units )
            %--------------------------------------------------------------
            % Set the response variable units
            %
            % obj = obj.setRespUnits( Units );
            %
            % Input Arguments:
            %
            % Units     --> (string) Units 
            %--------------------------------------------------------------
            arguments
                obj
                Units   (1,1)   string = "[Ah]"
            end
            obj.RespUnits = Units;
        end % setRespUnits
        
        function obj = setResponse( obj, Response )
            %--------------------------------------------------------------
            % Set the response variable
            %
            % obj = obj.setResponse( Response );
            %
            % Input Arguments:
            %
            % Response  --> (string) Response
            %--------------------------------------------------------------
            arguments
                obj
                Response    (1,1)   string  
            end
            Dvars = obj.DataObj.Variables;
            Ok = strcmpi( Response, Dvars );
            if any( Ok )
                %----------------------------------------------------------
                % Assign the variable
                %----------------------------------------------------------
                obj.Response = Dvars( Ok );
            else
                %----------------------------------------------------------
                % Variable not found
                %----------------------------------------------------------
                warning('Variable "%s" not present in datastore',...
                         Response );
            end
        end % setResponse
        
        function obj = setXname( obj, Xlvl1 )
            %--------------------------------------------------------------
            % Set the level-1 covariate name
            %
            % obj = obj.setXname( Xlvl1 );
            %
            % Input Arguments:
            %
            % Xlvl1  --> (string) Level-1 covariate
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationAnalysis
                Xlvl1   (1,1)   string
            end
            Dvars = obj.DataObj.Variables;
            Ok = strcmpi( Xlvl1, Dvars );
            if any( Ok )
                %----------------------------------------------------------
                % Assign the variable
                %----------------------------------------------------------
                obj.Xname = Dvars( Ok );
            else
                %----------------------------------------------------------
                % Variable not found
                %----------------------------------------------------------
                warning('Variable "%s" not present in datastore',...
                         Xlvl1 );
            end
        end % setXname
        
        function D = getData( obj, Convert2Double )
            %--------------------------------------------------------------
            % Fetch the data table and correct column names to match the
            % design object
            %
            % D = obj.getData( Convert2Double );
            %
            % Input Arguments:
            %
            % Convert2Double    --> (logical) set to true to convert
            %                       facility variable to double
            %--------------------------------------------------------------
            if ( nargin < 2 ) || ~islogical( Convert2Double )
                Convert2Double = false;
            end
            D = obj.DataObj.DataTable;
            %--------------------------------------------------------------
            % Now substitute the data channel factor names
            %--------------------------------------------------------------
            FacName = string( obj.MatchList.Properties.RowNames );
            N = obj.DesignObj.NumFac;
            for Q = 1:N
                Signal = obj.MatchList.DataChannels( Q );
                Idx = strcmpi( D.Properties.VariableNames, Signal );
                D.Properties.VariableNames{ Idx } = char( FacName( Q ) );
            end
            if Convert2Double
                %----------------------------------------------------------
                % Convert all categorical variables to their ordinal values
                %----------------------------------------------------------
                F = obj.DesignObj.Factor;
                NumFacs = height( F );
                for Q = 1:NumFacs
                    Name = obj.FacNames( Q );
                    C = F.Levels( Q );
                    if iscell( C )
                        C = C{ : };
                    end
                    if isa( C, "categorical" )
                        CatNames = categories( C );
                        ValueSet = 1:numel( CatNames );
                        CatVar = categorical( D.( Name ), CatNames,...
                                    string( ValueSet ), 'Ordinal', true );
                        D.( Name ) = double( CatVar );
                    end
                end
            end
        end % getData
    end % constructor & ordinary methods
    
    methods
        function N = get.FacNames( obj )
            % Return design factor names
            N = obj.DesignObj.FacNames;
        end
        
        function N = get.FacSymbols( obj )
            % Return list of factor symbols
            N = obj.DesignObj.Factor.Symbol.';
        end
        
        function L = get.NumFacLvl( obj )
            % Number of facility factor levels
            Fac = obj.DesignObj.Factor;
            L = Fac{ obj.Facility, "NumLevels" };
        end
        
        function T = get.TestType( obj )
            % retrieve test type
            T = lower( string( obj.DesignObj.TestType ) );
        end
        
        function S = get.ModelSym( obj )
            % retrieve the model in symbolic form
            S = obj.ModelObj.Syms;
        end
        
        function M = get.NumTests( obj )
            % retrieve the number of cells
            T = obj.DataObj.DataTable;
            T = T( :, "SerialNumber" );
            T = unique( T, 'rows' );
            M = height( T );
        end 
    end % get/set methods
    
    methods ( Access = private )   
        function Ax = plotPulseData( obj, D )
            %--------------------------------------------------------------
            % Plot the raw rate data sweeps for all institutions
            %
            % Ax = obj.plotPulseData( D );
            %
            % Input Arguments:
            %
            % D     --> (table) Data table 
            %--------------------------------------------------------------
            Facs = obj.DesignObj.Factor;
            NumFac = Facs.NumLevels;
            Lvls = obj.DesignObj.Factor.Levels{ : };
            Color = [ "red", "blue", "green", "magenta", "black" ].';
            figure;
            Ax = axes;
            Ax = repmat( Ax, 1, NumFac );
            for Q = 1:NumFac
                %----------------------------------------------------------
                % Plot the data
                %----------------------------------------------------------
                Ax( Q ) = subplot( 3, 2, Q );                               
                Ax( Q ).NextPlot = "add";                                   
                Fidx = ( double( Lvls( Q ) ) == D.Facility );
                Sn = unique( D( Fidx, "SerialNumber" ), "stable" );
                Sn = table2cell( Sn );
                N = numel( Sn );
                for S = 1:N
                    Sidx = strcmpi( Sn{ S }, D.SerialNumber );
                    X = D{ Sidx, obj.Xname };
                    Y = D{ Sidx, obj.Response };
                    Marker = strjoin( [ "s", Color( Q ) ], "" );
                    plot( Ax( Q ), X, Y, Marker, "MarkerFaceColor", Color( Q ) );
                    Ax( Q ).GridAlpha = 0.75;
                    Ax( Q ).GridLineStyle = "--";
                    Ax( Q ).GridColor = [0.025 0.025 0.025];
                    grid on;
                    xlabel( obj.Xname, "FontSize", 14 );
                    ylabel( obj.Response, "FontSize", 14 );
                    title( string( Lvls( Q ) ), "FontSize", 16 );
                end
            end
        end % plotPulseData
        
        function Ax = plotRateData( obj, D )
            %--------------------------------------------------------------
            % Plot the raw rate data sweeps for all institutions
            %
            % Ax = obj.plotRateData( D );
            %
            % Input Arguments:
            %
            % D     --> (table) Data table 
            %--------------------------------------------------------------
            Cat = obj.DesignObj.Cat;              
            %--------------------------------------------------------------
            % Determine number of plots & Develop matric of continuous 
            % factor levels.
            %--------------------------------------------------------------
            Lvls = fullfact( obj.DesignObj.Levels );
            Lvls = obj.DesignObj.mapLevels( Lvls );
            Lvls = Lvls( :, ~Cat );
            Lvls = unique( Lvls, 'rows', 'stable' );
            ContLvls = obj.DesignObj.Levels( ~Cat );
            R = ContLvls(1);
            if ( obj.DesignObj.NumCon > 1 )
                C = ContLvls(2);
            else
                C = 1;
            end
            ConFacs = obj.DesignObj.Factor.Properties.RowNames( ~Cat );
            ConFacs = string( ConFacs );
            NumPlots = prod( ContLvls );
            %--------------------------------------------------------------
            % Plot the data by continuous factors
            %--------------------------------------------------------------
            figure;
            Ax = repmat( axes, R, C );
            Facs = unique( D.( obj.Facility ) );
            LegStr = true( obj.NumFacLvl, NumPlots );
            Color = [ "red", "blue", "green", "magenta", "black" ].';
            for F = 1:numel( Facs )
                %------------------------------------------------------
                % Plot the data for the current factor settings by
                % facility as a parameter
                %------------------------------------------------------
                Fidx = ( D.( obj.Facility ) == Facs( F ) );                 % Point to the data for the current facility
                %------------------------------------------------------
                % Find the data corresponding to the current levels for
                % the Fth facility
                %------------------------------------------------------
                X = D( Fidx, [ "Cycle", ConFacs.', obj.Response, obj.Facility ] );
                for L = 1:NumPlots
                    %--------------------------------------------------
                    % Plot the facility data on each graph
                    %--------------------------------------------------
                    Ax( L ) = subplot( R, C, L );
                    Ax( L ).NextPlot = "add";
                    axes( Ax( L ) );                                        %#ok<LAXES>
                    Idx = all( ( X{:,ConFacs.'} == Lvls( L, : ) ), 2 );
                    Xd = X( Idx, : );
                    H = plot( Xd.( obj.Xname), Xd.( obj.Response ), 's' );
                    if ~isempty( H )
                        H.MarkerSize = 8;
                        H.MarkerFaceColor = Color( F, : );
                        H.MarkerEdgeColor = Color( F, : );
                        xlabel( 'Cycle [#]', 'FontSize', 14 );
                        Str = strjoin( [ obj.Response, obj.RespUnits ],...
                            " " );
                        ylabel( Str, 'FontSize', 14 );
                        Str = sprintf('( %s, %s ) = ( %5.2f, %3.1f )',...
                            ConFacs, Lvls( L, : ) );
                        title( Str, 'FontSize', 14 );
                        grid on;
                    else
                        %--------------------------------------------------
                        % Set the corresponding logical legend string 
                        % pointer to false
                        %--------------------------------------------------
                        LegStr( F, L ) = false;
                    end
                end
            end
            %--------------------------------------------------------------
            % Add legends
            %--------------------------------------------------------------
            for Q = 1:numel( Ax )
                axes( Ax( Q ) );                                            %#ok<LAXES>
                Ax( Q ).FontSize = 12;
                Ax( Q ).GridAlpha = 0.75;
                Ax( Q ).GridColor = [0.025 0.025 0.025];
                Ax( Q ).GridLineStyle = "--";
                warning off;
                Facs = correlationFacility( Facs );
                legend( string( Facs( LegStr( :, Q ) ) ), 'Location',...
                                'eastoutside', 'Orientation', 'Vertical' );
                warning on;
            end
        end % plotRateData
        
        function S = genModelOpts( obj )
            %--------------------------------------------------------------
            % Generate the interface structure for the current analysis
            %
            % S = obj.genModelOpts();
            %--------------------------------------------------------------
            switch obj.TestType
                case "rate"
                    S = obj.genRateOpts();
                case "pulse"
                    S = obj.genPulseOpts();
                case "capacity"
                otherwise
                    error('Test type "%s" not recognised', obj.TestType );
            end
        end % genModelOpts
        
        function S = genRateOpts( obj )
            %--------------------------------------------------------------
            % Generate analysis argument structure for rate test
            %
            % S = obj.genRateOpts();
            %--------------------------------------------------------------
            S.NumTests = double( obj.NumTests );
            S.Xname = "Cycle";
            S.Yname = obj.Response;
        end % genRateOpts
        
        function S = genPulseOpts( obj )
            %--------------------------------------------------------------
            % Generate analysis argument structure for pulse test
            %
            % S = obj.genPulseOpts();
            %--------------------------------------------------------------
            S.NumTests = double( obj.NumTests );
            S.Xname = "SoC";
            S.Yname = obj.Response;
        end % genPulseOpts
        
        function A = getDefaultCon( obj )
            %--------------------------------------------------------------
            % Retrieve default contrast vector
            %
            % A = getDefaultCon();
            %--------------------------------------------------------------
            A = obj.ModelObj.getDefaultCon();
        end % getDefaultCon
    end % private methods
    
    methods ( Static = true, Access = protected )    
        function commonAxesLimits( Ax )
            %--------------------------------------------------------------
            % Enusre subplots have common axes limits
            %
            % obj.commonAxesLimits( Ax );
            %
            % Input Arguments:
            %
            % Ax    --> Array of axes handles
            %--------------------------------------------------------------
            N = numel( Ax );
            Str = [ "XLim", "YLim", "ZLim" ];
            D = numel( Str );
            for Q = 1:D
                 Lim = [ Ax.( Str( Q ) ) ];
                 Lim = [ Lim( 1:2:end ); Lim( 2:2:end ) ].';
                 switch lower( Str( Q ) )
                     case "xlim"
                         XMin = min( Lim( :, 1 ) );
                         XMax = max( Lim( :, 2 ) );
                     case "ylim"
                         YMin = min( Lim( :, 1 ) );
                         YMax = max( Lim( :, 2 ) );
                     otherwise
                         ZMin = min( Lim( :, 1 ) );
                         ZMax = max( Lim( :, 2 ) );
                 end
            end
            for Q = 1:N
                Ax( Q ).XLim = [ XMin, XMax ];
                Ax( Q ).YLim = [ YMin, YMax ];
                Ax( Q ).ZLim = [ ZMin, ZMax ];
            end
        end % commonAxesLimits
    end % static and protected methods
end % correlationAnalysis

function mustBeDataObj( DataObj )
    %----------------------------------------------------------------------
    % Validation function for DataObj property
    %----------------------------------------------------------------------
    AllowedClasses = [ "rateData", "pulseData", "capacityData" ];
    C = class( DataObj );
    if ~isnumeric( DataObj )
        Ok = any( strcmpi( C, AllowedClasses ) );
        Msg = "DataObj is not a supported class!";
        assert( Ok, Msg );
    end
end % mustBeDataObj

function mustBeDesignObj( DesignObj )
    %----------------------------------------------------------------------
    % Validation function for DesignObj property
    %----------------------------------------------------------------------
    AllowedClasses = [ "rateDesign", "pulseDesign", "capacityDesign" ];
    C = class( DesignObj );
    if ~isnumeric( DesignObj )
        Ok = any( strcmpi( C, AllowedClasses ) );
        Msg = "DesignObj is not a supported class!";
        assert( Ok, Msg );
    end
end % mustBeDesignObj

function  mustBeModelObj( ModelObj )
    %----------------------------------------------------------------------
    % Validation function for ModelObj property
    %----------------------------------------------------------------------
    AllowedClasses = [ "rateModel", "pulseModel", "capacityModel" ];
    C = class( ModelObj );
    if ~isnumeric( ModelObj )
        Ok = any( strcmpi( C, AllowedClasses ) );
        Msg = "ModelObj is not a supported class!";
        assert( Ok, Msg );
    end
end % mustBeModelObj

function mustBeReportObj( ReportObj )
    %----------------------------------------------------------------------
    % Validation function for ReportObj property
    %----------------------------------------------------------------------
    AllowedClasses = [ "correlationRateReport", "correlationPulseReport",...
        "correlationCapacityReport" ];
    C = class( ReportObj );
    if ~isnumeric( ReportObj )
        Ok = any( strcmpi( C, AllowedClasses ) );
        Msg = "ModelObj is not a supported class!";
        assert( Ok, Msg );
    end
end % mustBeReportObj