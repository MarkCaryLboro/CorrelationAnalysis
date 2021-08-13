classdef correlationRateReport < correlationReport
    % Generate reports for the facility correlation rate test
    
    methods
        function obj = correlationRateReport( M )
            %--------------------------------------------------------------
            % class constructor
            %
            % obj = correlationRateReport( M )
            %
            % Input Arguments:
            %
            % M     --> Model object. Must be one of the following object
            %           types: 
            %           {"correlationRateReport"}, 
            %            "correlationCapacityReport"
            %            "correlationPulseReport"
            %--------------------------------------------------------------
            obj.M = M;
        end % Constructor
        
        function T = hypothesisTest( obj, A, P )
            %--------------------------------------------------------------
            % hypothesis testing procedure for significance og facility 
            % terms. Based on Chi-2 distribution.
            %
            % T = obj.hypothesisTest( A, P );
            %
            % Input Arguments:
            %
            % A         --> (double) (mxk) matrix of linear coefficients
            % P         --> (double) p-value threshold for tests
            %
            % Output Arguments:
            %
            % T         --> (table) Hypothesis test report table
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationRateReport
                A       (:,:)   double                  { mustBeNonempty( A ),...
                                                          mustBeNumeric( A ),...
                                                          mustBeReal( A ) }
                P       (1,1)   double                  { mustBeNumeric( P ),...
                                                          mustBeReal( P ) } = 0.05
            end
            Theta = obj.M.Theta;                                            % Level-2 model parameters
            V = obj.M.CovQ;                                                 % Covariance matrix for theta
            DoF = size( A, 1 );                                             % Number of hypotheses
            obj = obj.setAlpha( P );                                        % Set the significance level
            XmA mkm lpha = chi2inv( ( 1 - obj.Alpha ), DoF );                    % Critical Chi-2 value
            %--------------------------------------------------------------
            % Compute the test statistic
            %--------------------------------------------------------------
            I = eye( DoF );
            V = A * V * A.';
            V = V \ I;
            Xm = ( A * Theta ).' * V * ( A * Theta );
            Pvalue = chi2cdf( Xm, DoF );
            Ho = ( Pvalue < P );
            %--------------------------------------------------------------
            % Generate the report table
            %--------------------------------------------------------------
            T = table( { A }, Xm, XmAlpha, DoF, Pvalue, P, Ho ); 
            T.Properties.VariableNames = [ "a.'" "Test Statistic", "Critical Value", ...
                "DoF", "P-value", "P", "Ho" ];
        end % hypothesisTest
        
        function CF = correctionFactor( obj, A, Ai )
        end % correctionFactor
        
        function surf( obj, varargin )                                               
            % plot surfaces for Bo and B1 for a given facility
        end % surf
        
        function cont( obj, varargin )                                               
            % contour plots for Bo and B1 for a given facility
        end % cont
        
        function compare( obj, varargin )                                            
            % compare Bo and B1 surfaces for two facilities
        end % compare
        
    end % ordinary methods
end % correlationRateReport