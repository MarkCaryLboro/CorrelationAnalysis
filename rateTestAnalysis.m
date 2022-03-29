function [ obj, Ax, ResAx ] = rateTestAnalysis( ModelType, Factors, Response, Xname )
    %----------------------------------------------------------------------
    % Function to perform correlation analysis for the rate data.
    %
    % obj = rateTestAnalysis( ModelType, Factors, Response, Xname );
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
    % ResAx         --> Residual plot axes handle array
    %----------------------------------------------------------------------
    arguments
        ModelType   (1,1)   string
        Factors     (1,:)   struct
        Response    (1,1)   string          = "DischargeCapacity"
        Xname       (1,1)   string          = "Cycle"
    end
    %----------------------------------------------------------------------
    % Define design object
    %----------------------------------------------------------------------
    DesObj = rateDesign();
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
                                  "Select File Containing Rate Data" );
    try
        Fname = strjoin( { Pname, Fname }, "" );
    catch
        error("Must select a data file - program terminated!");
    end
    DataObj = rateData();
    DataObj = DataObj.addData( Fname );
    %----------------------------------------------------------------------
    % Define mle algorithm
    %----------------------------------------------------------------------
    Mle = mleAlgorithms( "em" );
    %----------------------------------------------------------------------
    % Define Model object
    %----------------------------------------------------------------------
    M = rateModel( DesObj, Mle, ModelType );
    %----------------------------------------------------------------------
    % Define the report object
    %----------------------------------------------------------------------
    RepObj = correlationRateReport( M );
    %----------------------------------------------------------------------
    % Define the analysis object
    %----------------------------------------------------------------------
    obj = correlationAnalysis( DataObj, DesObj, M, RepObj );
    %----------------------------------------------------------------------
    % Define the response variable
    %----------------------------------------------------------------------
    obj = obj.setResponse( Response );
    obj = obj.setRespUnits( "[Ah]");
    obj = obj.setXname( Xname );
    %----------------------------------------------------------------------
    % Plot the data & fit the model
    %----------------------------------------------------------------------
    Ax = obj.plot();
    obj = obj.fitModel();
    %----------------------------------------------------------------------
    % plot the model residuals
    %----------------------------------------------------------------------
    A = obj.getData( true );
    Idx = ( A.Cycle == 1 );
    A = A( Idx, obj.FacNames );
    A = table2array( A );
    Bp = obj.predictions( A );
    Res = obj.ModelObj.B.' - Bp;
    figure;
    ResAx = subplot( 1, 2, 1 );
    H = plot( Bp( :, 1 ), Res( :, 1 ), 'ko' );
    H.MarkerFaceColor = "Black";
    grid on
    ResAx.GridColor = [0.025 0.025 0.025];
    ResAx.GridLineStyle = "--";
    ResAx.GridAlpha = 0.75;
    xlabel( "Predicted \beta_0", "FontSize", 14 );
    ylabel( "Residual \beta_0", "FontSize", 14 );
    title( "Intercept", "FontSize", 16 );
    ResAx( 2, 1 ) = subplot( 1, 2, 2 );
    H = plot( Bp( :, 2 ), Res( :, 2 ), 'ko' );
    H.MarkerFaceColor = "Black";
    grid on
    ResAx( 2, 1 ).GridColor = [0.025 0.025 0.025];
    ResAx( 2, 1 ).GridLineStyle = "--";
    ResAx( 2, 1 ).GridAlpha = 0.75;
    xlabel( "Predicted \beta_1", "FontSize", 14 );
    ylabel( "Residual \beta_1", "FontSize", 14 );
    title( "Slope", "FontSize", 16 );
end % rateTestAnalysis
