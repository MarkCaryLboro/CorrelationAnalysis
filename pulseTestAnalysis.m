function [ obj, Ax] = pulseTestAnalysis( ModelType, Factors, Response, Xname )
    %----------------------------------------------------------------------
    % Function to perform correlation analysis for the rate data.
    %
    % obj = pulseTestAnalysis( ModelType, Factors, Response, Xname );
    %
    % Input Arguments:
    %
    % ModelType     --> Model type either: {"linear"},
    %                   "interaction", "quadratic", "cubic" or "complete"
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
    DesObj = DesObj.setReplicates( 18 );
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
    try
        Fname = strjoin( { Pname, Fname }, "" );
    catch
        error("Must select a data file - program terminated!");
    end
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
    % Add the model prediction to the plots
    %----------------------------------------------------------------------
    Xsoc = linspace( 0.1, 0.9, 101 ).';
    A = unique( obj.DataObj.DataTable( :, obj.Facility ) );
    A = table2array( A );
    A = correlationFacility( A(:) );
    Z = obj.predictions( A );                                               % compute the level-1 coefficients
    Z = Z.';
    %----------------------------------------------------------------------
    % Compute the level-1 basis fcn matrix
    %----------------------------------------------------------------------
    Kc = obj.ModelObj.codeSoC( 0.5 );                                       % spline knot
    X = obj.ModelObj.codeSoC( Xsoc ); 
    Xs = max( [zeros( size( X ) ), X - Kc ], [], 2 );
    X = [ ones( size( X, 1 ), 1 ), X, X.^2, Xs.^2 ];    
    %----------------------------------------------------------------------
    % Compute the predictions
    %----------------------------------------------------------------------
    Yp = X * Z;
    for Q = 1:obj.NumFacLvl
        plot( Ax( Q ), Xsoc, Yp( :, Q ), "c-", 'LineWidth', 2 );
    end
%     %----------------------------------------------------------------------
%     % Hypothesis test
%     %----------------------------------------------------------------------
%     A = obj.ModelObj.getDefaultCon();
%     H = obj.hypothesisTest( A, 0.05 );
end % pulseTestAnalysis