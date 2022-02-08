classdef lvl1RateModel < level1Model
    
    properties ( SetAccess = protected )
        F              cell                                                 % Level-1 coefficient covariance matrices
        DataObj (1,1)  rateData                                             % Data object
    end
    
    methods
        function obj = lvl1RateModel( DataObj, Args )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = lvl1RateModel( DataObj, "Name1", Value1, ...,
            %                                "Name4", Value4);
            %
            % Input Arguments;
            %
            % DataObj    --> (rateData) Data object containing experimental
            %                results
            %
            % Name-Value Arguments
            % "Xname"    --> (string) Level-1 covariate signal name
            % "Yname"    --> (string) Response variable name
            % "Degree"   --> (int8) degree of polynomial to fit {1}
            % "CovMdl"   --> (lv1CovModelType) Name of COV model {OLS}
            % "ExpUnit"  --> (string) battery identifier. Must be unique
            %                         for all cells
            %--------------------------------------------------------------
            arguments
                DataObj (1,1)   rateData        {mustBeNonempty( DataObj )}
            end
            %--------------------------------------------------------------
            % Optional Arguments
            %--------------------------------------------------------------
            arguments
                Args.Xname      (1,1)   string       = "Cycle"
                Args.Yname      (1,1)   string       = "DischargeCapacity"                
                Args.Degree     (1,1)   int8        {mustBeNumeric( Args.Degree ),...
                                                     mustBeGreaterThan( Args.Degree , 0 )} = 1
                Args.CovMdl     (1,1)   lv1CovModelType        = lv1CovModelType( "ols" )
                Args.ExpUnit    (1,1)   string        = "SerialNumber"
            end
            obj.DataObj = DataObj;
            obj = obj.setDegree( Args.Degree );
            obj = obj.setCovMdlName( Args.CovMdl );
            F = string( fields( Args ) );
            if contains( "Xname", F )
                Ok = DataObj.channelPresent( Args.Xname );
                if Ok
                    obj = obj.setXname( Args.Xname );
                end
            end
            if contains( "Yname", F )
                Ok = DataObj.channelPresent( Args.Yname );
                if Ok
                    obj = obj.setYname( Args.Yname );
                end
            end
        end % lvl1RateModel
        
        function obj = level1Fits( obj )  
            %--------------------------------------------------------------
            % Fit the level-1 model
            %
            % obj = obj.level1Fits();
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   lvl1RateModel                               
            end
            D = obj.DataObj.DataTable;
            Tests = unique( D.SerialNumber );
            obj.B = zeros( ( obj.Degree + 1 ), obj.numCells );              % define for storage
            if ( nargin < 2 ) || isempty( Tests )
                %----------------------------------------------------------
                % Default is all tests
                %----------------------------------------------------------
                Tests = unique( D.SerialNumber );
            end
            N = obj.numCells;
            for Q = 1:N
                A = obj.extractTestXdata( Tests( Q ), obj.Xname);
                Y = obj.extractTestXdata( Tests( Q ), obj.Yname);
                Ok = ~any( any( isnan( A ) ) | any( isnan( Y ) ) );
                if Ok
                    %------------------------------------------------------
                    % Fit the data
                    %------------------------------------------------------
                    A = obj.basis( A );
                    obj.B( :, Q ) = A\Y;
                end
            end
        end % level1Fits
        
        function A = basis( obj, X )      
            %--------------------------------------------------------------
            % Basis function matrix generator
            %
            % A = obj.basis( X );
            %
            % Input Arguments:
            %
            % X     --> (double) Vector of level-1 covariate values
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   lvl1RateModel
                X       (:,1)   double
            end
            A = X.^( double( 0:obj.Degree ) );
        end % basis
        
        function Yhat = predictions( obj, X )
            %--------------------------------------------------------------
            % Return predictions at any X-value for a given test(s)
            %
            % Yhat = obj.predictions( X );
            %
            % Input Arguments:
            %
            % X             --> (double) X-covariate settings
            %
            % Output Arguments:
            %
            % yhat          --> (cell) Array of predictions corresponding
            %                   to TestNumbers
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   lvl1RateModel   { mustBeNonempty( obj ) }
                X       (:,1)   double          { mustBeNonempty( X ) }    
            end
            Tests = unique( obj.DataObj.DataTable.( obj.SerNum ),...
                            'stable' );
            A = obj.basis( X );                                             % Compute basis function matrix
            N = numel( Tests );
            Yhat = cell( N, 1 );                                            % Define storage
            for Q = 1:N
                %----------------------------------------------------------
                % Compute the predictions
                %----------------------------------------------------------
                
            end
        end % predictions
    end % Constructor and ordinary methods
end % classdef