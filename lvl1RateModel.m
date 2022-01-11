classdef lvl1RateModel < level1Model
    
    properties ( SetAccess = protected )
        F              cell                                                 % Level-1 coefficient covariance matrices
        DataObj (1,1)  rateData                                             % Data object
    end
    
    methods
        function obj = lvl1RateModel( DataObj, Xname, Yname, CovMdlName )
            %--------------------------------------------------------------
            % Class constructor
            %
            % obj = lvl1RateModel( DataObj, Xname, Yname, CovMdlName );
            %
            % Input Arguments;
            %
            % DataObj   --> (rateData) Data object containing experimental
            %               results
            % Xname     --> (string) Level-1 covariate signal name
            % Yname     --> (string) Response variable name
            %--------------------------------------------------------------
            arguments
                DataObj (1,1)   rateData        {mustBeNonempty( DataObj )}
                Xname   (1,1)   string     = string.empty
                Yname   (1,1)   string     = string.empty
                CovMdlName  (1,1)   string = "OLS"
            end
            obj.DataObj = DataObj;
            Ok = DataObj.channelPresent( Xname );
            if Ok
                obj.Xname = Xname;
            end
            Ok = DataObj.channelPresent( Yname );
            if Ok
                obj.Yname = Yname;
            end
            obj.CovMdl = CovMdlName;
        end % lvl1RateModel
        
        function obj = level1Fits( obj, D, Tests )  
            %--------------------------------------------------------------
            % Fit the level-1 model
            %
            % obj = obj.level1Fits( D, Tests );
            %
            % Input Arguments:
            %
            % D         --> (table) Data table
            % Tests     --> List of tests to fit {all}
            %--------------------------------------------------------------
            arguments
                obj     (1,1)   lvl1RateModel                               
                D       (1,1)   table                                       % Data table
                Tests   (:,1)                           = []                % List of tests to fit   
            end
            
        end % level1Fits
        
        function diagnosticPlots( obj, D, TestNumber )   
            %--------------------------------------------------------------
            % Make fit diagnostic plots
            %--------------------------------------------------------------
            
        end % diagnosticPlots
        
        function A = basis( obj, X, ModelName )      
            %--------------------------------------------------------------
            % basis function matrix generator
            %
            % 
            %--------------------------------------------------------------
            
        end
    end % Constructor and ordinary methods
end % classdef