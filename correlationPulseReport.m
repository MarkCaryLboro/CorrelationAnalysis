classdef  correlationPulseReport < correlationReport
    % Generate reports for the facility correlation rate test
    
    methods
        function obj = correlationPulseReport( M )
            %--------------------------------------------------------------
            % class constructor
            %
            % obj = correlationPulseReport( M )
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
            XmAlpha = chi2inv( ( 1 - obj.Alpha ), DoF );                    % Critical Chi-2 value
            %--------------------------------------------------------------
            % Compute the test statistic
            %--------------------------------------------------------------
            I = eye( DoF );
            V = A * V * A.';
            V = V \ I;
            Xm = ( A * Theta ).' * V * ( A * Theta );
            Pvalue = 1 - chi2cdf( Xm, DoF );
            H1 = ( Pvalue < P );
            %--------------------------------------------------------------
            % Generate the report table
            %--------------------------------------------------------------
            T = table( { A }, Xm, XmAlpha, DoF, Pvalue, P, ~H1 ); 
            T.Properties.VariableNames = [ "a.'" "Test Statistic", "Critical Value", ...
                "DoF", "P-value", "P", "Ho" ];
        end % hypothesisTest
        
        function [ OfCF, SlpCF, Off, Slp, OffRef, SlpRef, C, T ] = correctionFactor( obj, Fac, N )
            %--------------------------------------------------------------
            % Generate correction factors for the slope and offset term.
            %
            % [ OfCF, SlpCF, Off, Slp, OffRef, SlpRef, C, T ] = ...
            %                               obj.correctionFactor( Fac, N );
            %
            % Input Arguments:
            %
            % Fac   --> Facility name (string)
            % N     --> Mesh size (double)
            %
            % Output Arguments:
            %
            % OfCF      --> (NxN) matrix of B0 correction factors
            % SlpCF     --> (NxN) matrix of B1 correction factors
            % Off       --> (NxN) of B0 coefficients for the specified
            %               facility
            % Slp       --> (NxN) of B1 coefficients for the specified
            %               facility
            % OffRef    --> (NxN) of B0 coefficients for the reference
            %               facility
            % SlpRef    --> (NxN) of B1 coefficients for the reference
            %               facility
            % C         --> (NxN) matrix of C-Rate factor levels
            % T         --> (NxN) matrix of Temperature factor levels
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationRateReport
                Fac     (1,1)   string  { mustBeNonempty( Fac ) }
                N       (1,1)   double  { mustBePositive( N ), mustBeReal( N ),...
                                          mustBeNumeric( N ) } = 11;
            end
            %--------------------------------------------------------------
            % Create correlationFacility object & convert to double
            %--------------------------------------------------------------
            F = correlationFacility( Fac );
            F = double( F );
            %--------------------------------------------------------------
            % Create evaluation mesh
            %--------------------------------------------------------------
            Cont = ( obj.M.Design.Factor.Type == "CONTINUOUS" ).';
            Cfactors = obj.M.FacNames( Cont );
            NumContFac = numel( Cfactors );
            for Q = 1:NumContFac
                %----------------------------------------------------------
                % Generate mesh vectors
                %----------------------------------------------------------
                switch lower( Cfactors( Q ) )
                    case "temperature"
                        T = obj.makeLevels( Cfactors( Q ), N );
                    otherwise
                        C = obj.makeLevels( Cfactors( Q ), N );
                end
            end
            %--------------------------------------------------------------
            % Generate level-2 ageing conditions matrix in engineering
            % units
            %--------------------------------------------------------------
            [ C, T ] = meshgrid( C, T );
            F = repmat( F, N.^2, 1 );
            A = zeros( N.^2, obj.M.NumFac );
            Cat = obj.M.Design.Cat;
            A( :, ~Cat ) = [ C( : ), T( : ) ];
            A( :, Cat ) = F;
            %--------------------------------------------------------------
            % Generate correction factors
            %--------------------------------------------------------------
            [ B, Bref ] = obj.M.predictLvl1( A );
            Off = reshape( B( 1, : ), N, N );
            Slp = reshape( B( 2, : ), N, N );
            OffRef = reshape( Bref( 1, : ), N, N );
            SlpRef = reshape( Bref( 2, : ), N, N );
            OfCF = OffRef - Off;
            SlpCF = SlpRef - Slp  ;
        end % correctionFactor
        
        function Ax = surf( obj, Fac, N )
            %--------------------------------------------------------------
            % plot surfaces for Bo and B1 for a given facility
            %
            % Ax = obj.surf( Fac, N );
            %
            % Input Arguments:
            %
            % Fac   --> Facility name (string)
            % N     --> Mesh size (double)
            %
            % Output Arguments:
            %
            % Ax    --> Handles to axes objects
            %--------------------------------------------------------------
            [ OfCF, SlpCF, Off, Slp, OffRef, SlpRef,...
                                   C, T ] = obj.correctionFactor( Fac, N );
            Fac = string( correlationFacility( Fac ) );
            S = sprintf("( Surf, Mesh ) = ( %s, Reference )", Fac );
            figure;
            Ax( 4 ) = subplot( 2, 2, 4);
            for Q = 1:4
                Ax( Q ) = subplot( 2, 2, Q);
                Ax( Q ).NextPlot = 'add';
                switch Q
                    case 1
                        surf( C, T, Off );
                        mesh( C, T, OffRef );
                        zlabel("\beta_0", 'FontSize', 16);
                        title( S, 'FontSize', 16 );
                    case 2
                        surf( C, T, Slp );
                        mesh( C, T, SlpRef );
                        zlabel("\beta_1", 'FontSize', 16);
                        title( S, 'FontSize', 16 );
                    case 3
                        mesh( C, T, OfCF );
                        zlabel("\beta_0", 'FontSize', 16);
                        title("Correction Factor", 'FontSize', 16);
                    otherwise
                        mesh( C, T, SlpCF );
                        zlabel("\beta_1", 'FontSize', 16);
                        title("Correction Factor", 'FontSize', 16);
                end
                view( Ax( Q ), 3 );
                xlabel( "CRate", 'FontSize', 16 );
                ylabel( "Temperature", 'FontSize', 16 );
                grid on;
            end
        end % surf
        
        function cont( obj, N )                     
            %--------------------------------------------------------------
            % contour plots for Bo and B1 for all facilities
        end % cont
        
        function Ax = compare( obj, Facs, N )
            %--------------------------------------------------------------
            % Compare Bo and B1 surfaces for two facilities
            %
            % Ax = obj.compare( Facs, N );
            %
            % Input Arguments:
            %
            % Input Arguments:
            %
            % Facs  --> (1x2) Facility names (string)
            % N     --> Mesh size (double)
            %
            % Output Arguments:
            %
            % Ax    --> Handles to axes objects
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   correlationRateReport
                Facs    (1,2)   string  { mustBeNonempty( Facs ) }
                N       (1,1)   double  { mustBePositive( N ), mustBeReal( N ),...
                                          mustBeNumeric( N ) } = 11;
            end
            F = correlationFacility( Facs );
            [ ~, ~, Off1, Slp1, ~, ~, C, T ] = correctionFactor( obj,...
                                                            Facs( 1 ), N );
            [ ~, ~, Off2, Slp2 ] = correctionFactor( obj, Facs( 2 ), N );
            figure;
            Ax( 2 ) = subplot( 1, 2, 2 );
            S = sprintf("( Surf, Mesh ) = ( %s, %s )", string( F ) );
            for Q = 2:-1:1
                Ax( Q ) = subplot( 1, 2, Q );
                Ax( Q ).NextPlot = 'add';
                switch Q
                    case 1
                        surf( C, T, Off1 );
                        mesh( C, T, Off2 );
                        zlabel( "\beta_0", 'FontSize', 16 ); 
                    otherwise
                        surf( C, T, Slp1 );
                        mesh( C, T, Slp2 );
                        zlabel( "\beta_1", 'FontSize', 16 ); 
                end
                view( Ax( Q ), 3 );
                grid on;
                title( S, 'FontSize', 16 );
                xlabel( "CRate", 'FontSize', 16 );
                ylabel( "Temperature", 'FontSize', 16 );
            end
        end % compare        
    end % ordinary and constructor methods
end % classdef