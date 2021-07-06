classdef correlationAnalysis
    % A class to analyse the data from the correlation experiment to assess
    % the equivalency of different battery test facilities
    
    properties ( SetAccess = protected )
        DataObj     (1,1)           { mustBeDataObj( DataObj ) }            % Data object                      
        DesignObj   (1,1)           { mustBeDesignObj( DesignObj ) }        % Design object
        ModelObj    (1,1)           { mustBeModelObj( ModelObj ) }          % Model to be fitted
        ReportObj   (1,1)             correlationReport                     % Report generator
        Facility    (1,1)             string      = "Facility"              % Facility variable
        MatchList                     table                                 % List of matched factor and signal names
        Response    (1,1)             string      = "DischargeCapacity"
    end
    
    properties ( SetAccess = protected, Dependent = true )
        NumFacLvl   (1,1)           double                                  % Number of facilities
        FacNames    (1,:)           string                                  % Design Factor Names
        FacSymbols  (1,:)           string                                  % Design Factor Symbols
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
        end % constructor
        
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
                else
                    warning( 'Facility variable must be "CATEGORICAL"' );
                end
            else
                warning( 'Variable "%s" not recognised', F );
            end
        end % setFacilityVariable
        
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
            D = obj.getData();
            %--------------------------------------------------------------
            % Plot the data by temperature
            %--------------------------------------------------------------
            N = double( obj.DesignObj.NumFac - obj.DesignObj.NumCat );
            Cat = obj.DesignObj.Cat;
            ContFac = obj.DesignObj.Factor.Properties.RowNames( ~Cat );
            ContFac = string( ContFac );
            ContLvls = obj.DesignObj.Factor.NumLevels( ~Cat  );
            figure;
            Ax = repmat( axes, 1, N );
            Facs = string( D.( obj.Facility ) );
            for Q = 1:N
                Ax( Q ) = subplot( 1, N, Q );    
                Ax( Q ).NextPlot = "add";
                X = D.( ContFac( Q ) );
                T = unique( X ).';
                Idx = ( D.( ContFac( Q ) ) == T );
                for F = 1:obj.NumFacLvl
                    %------------------------------------------------------
                    % Plot the data by facility
                    %------------------------------------------------------
                    Fidx =  strcmpi( D.( obj.Facility ), Facs( F ) );
                    X = D( Fidx, [ ContFac( Q ), obj.Response ] );
                    X = table2array( X );
                    Color = rand( 1, 3 );
                    H = plot( Ax( Q ), X( :, 1 ), X( :, 2 ), 's' );
                    H.MarkerSize = 8;
                    H.MarkerFaceColor = Color;
                    H.MarkerEdgeColor = Color;
                end
            end
        end % plot
        
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
                Response    (1,1)   string  = "DischargeCapacity"
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
        
        function D = getData( obj )
            %--------------------------------------------------------------
            % Fetch the data table and correct column names to match the
            % design object
            %
            % D = obj.getData();
            %--------------------------------------------------------------
            D = obj.DataObj.DataTable;
            %--------------------------------------------------------------
            % Now substitue the data channel faactor names
            %--------------------------------------------------------------
            FacName = string( obj.MatchList.Properties.RowNames );
            N = obj.DesignObj.NumFac;
             for Q = 1:N
                 Signal = obj.MatchList.DataChannels( Q );
                 Idx = strcmpi( D.Properties.VariableNames, Signal );
                 D.Properties.VariableNames{ Idx } = char( FacName( Q ) );
             end
        end % getData
        
        function Ok = matchDesign( obj )
            %--------------------------------------------------------------
            % Match the data to the design.... return true (false ) if
            % matched ( not matched ).
            %
            % Ok = obj.matchDesign();
            %--------------------------------------------------------------
            
        end % matchDesign
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
    end % get/set methods
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
    % Validation function for DesignObj property
    %----------------------------------------------------------------------
    AllowedClasses = [ "rateModel", "pulseModel", "capacityModel" ];
    C = class( ModelObj );
    if ~isnumeric( ModelObj )
        Ok = any( strcmpi( C, AllowedClasses ) );
        Msg = "ModelObj is not a supported class!";
        assert( Ok, Msg );
    end
end % mustBeDesignObj