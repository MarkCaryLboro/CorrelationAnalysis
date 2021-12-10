function pulseTestAnalysis( ModelType, Factors )
    %----------------------------------------------------------------------
    % Function to perform correlation analysis for the rate data.
    %
    % obj = rateTestAnalysis( ModelType, Factors );
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
    %
    % Output Arguments:
    %
    % obj           --> correlationAnalysis object
    % Ax            --> Data plot axes handle array
    %----------------------------------------------------------------------
    arguments
        ModelType   (1,1)   string
        Factors     (1,:)   struct
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
end % pulseTestAnalysis