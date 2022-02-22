function [ obj, DataObj, Ax, ResAx ] = pulseTestAnalysis( ModelType, Factors, Response, Xname )
    %----------------------------------------------------------------------
    % Function to perform correlation analysis for the rate data.
    %
    % obj = pulseTestAnalysis( ModelType, Factors, Response );
    %
    % Input Arguments:
    %
    % ModelType     --> Model type either: {"linear"},
    %                   "interaction", "quadratic" or "complete"
    % Factors       --> (struct) multidimensional structure defining the
    %                   experimental factors. Each dimension defines an
    %                   individual factor, using fields:
    %
    %                   Name:   (string) Name of factor
    %                   Symbol: (string) Symbol denoting the factor.
    %                   Units:  (string) Unit string
    %                   Levels: (cell) levels for factor
    %                   Cat:    (logical) true for categorical factor
    %                   Values: (cell) possible numerical values for
    %                           categories
    %                   Cats:   (string) vector of category names
    % Response      --> (string) name of response variable
    % Xname         --> (string) name of level-1 covariate
    %
    % Output Arguments:
    %
    % obj           --> correlationAnalysis object
    % Ax            --> Data plot axes handle array
    % ResAx         --> Residual plots axes handle array
    %----------------------------------------------------------------------
    arguments
        ModelType   (1,1)   string     
        Factors     (1,:)   struct
        Response    (1,1)   string          = "DischargeIR"
        Xname       (1,1)   string          = "SoC"
    end
    %----------------------------------------------------------------------
    % Define design object
    %----------------------------------------------------------------------
    DesObj = pulseDesign();
    NumFac = max( size( Factors ) );
    for Q = 1:NumFac
        if Factors( Q ).Cat
            %--------------------------------------------------------------
            % Categorical factor
            %--------------------------------------------------------------
            DesObj = DesObj.addCatFactor( Factors( Q ).Name,...
                Factors( Q ).Symbol, Factors( Q ).Levels,...
                Factors( Q ).Values, Factors( Q ).Cats );
        else
            %--------------------------------------------------------------
            % Continuous factor
            %--------------------------------------------------------------
            DesObj = DesObj.addConFactor( Factors( Q ).Name,...
                Factors( Q ).Symbol, Factors( Q ).Units, ...
                Factors( Q ).Levels );
        end
    end
    DesObj = DesObj.design();
    %----------------------------------------------------------------------
    % Import data
    %----------------------------------------------------------------------
    [ Fname, Pname ] = uigetfile( "*.xlsx",...
                                  "Select File Containing Pulse Data" );
    Fname = strjoin( { Pname, Fname }, "" );
    DataObj = pulseData();
    DataObj = DataObj.addData( Fname );
    %----------------------------------------------------------------------
    % Confine the SoC data to the interval [ 0.15, 0.8 ]
    %----------------------------------------------------------------------
    DataObj = DataObj.trimData( Xname, 0.15, 0.8 );
    %----------------------------------------------------------------------
    % Define mle algorithm
    %----------------------------------------------------------------------
    Mle = mleAlgorithms( "em" );
    %----------------------------------------------------------------------
    % Define Model object
    %----------------------------------------------------------------------
    M = pulseModel( DesObj, Mle, ModelType );
    %----------------------------------------------------------------------
    % Define the report object
    %----------------------------------------------------------------------
    RepObj = correlationPulseReport( M );
    %----------------------------------------------------------------------
    % Define the analysis object
    %----------------------------------------------------------------------
    obj = correlationAnalysis( DataObj, DesObj, M, RepObj );
    %----------------------------------------------------------------------
    % Define the response variable
    %----------------------------------------------------------------------
    obj = obj.setResponse( Response );
    obj = obj.setRespUnits( "[Ohms]");
    obj = obj.setXname( Xname );
    %----------------------------------------------------------------------
    % Plot the data & fit the model
    %----------------------------------------------------------------------
    Ax = obj.plot();
    obj = obj.fitModel();
    %----------------------------------------------------------------------
    % plot the model residuals
    %----------------------------------------------------------------------
end % pulseTestAnalysis