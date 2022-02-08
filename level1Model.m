classdef ( Abstract = true ) level1Model
    % An abstract class to implement the level-1 fitting.
    
    properties ( SetAccess = protected )
        Xname    (1,1)  string                                              % Level-1 covariate
        Yname    (1,1)  string                                              % Response variable
        CovMdl   (1,1)  lv1CovModelType                         = "OLS"     % Covariance model
        S2              double                                              % Level-1 variance scale factor
        Delta    (:,1)  double                                              % Level-1 covariance model parameter vector
        B        (:,1)  double                                              % array of level-1 fit coefficients
        Degree   (1,1)  int8         { mustBeGreaterThan( Degree, 0 ) } = 1 % Polynomial model order                                               % Polynomial order for level-1 model                                               
        SerNum   (1,1)  string           = "SerialNumber"                   % Battery identifier (serial number) channel
    end % protected properties
    
    properties ( SetAccess = protected, Abstract = true )
        F       cell                                                        % Level-1 coefficient covariance matrices
    end % abstract & protected properties
    
    properties ( Dependent = true )
        numCovPars  int8                                                    % Number of covariance model parameters
        numCells    int8                                                    % Number of cells
    end % dependent properties
    
    methods ( Abstract = true )
        obj = level1Fits( obj )                                             % Fit the level-1 model
        A = basis( obj, X )                                                 % basis function matrix generator
        Yhat = predictions( obj, X, TestNumber )                            % Make predictions for a specific test
    end % Abstract method signatures
    
    methods
        function obj = setSerNum( obj, SN )
            %--------------------------------------------------------------
            % Set the level-1 polynomial regression order
            %
            % obj = obj.setSerNum( SN );
            %
            % Input Arguments:
            %
            % SN        --> (string) 
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                SN      (1,1)   string = "SerialNumber";
            end
            Ok = obj.DataObj.channelPresent( SN );
            if Ok
                obj.SerNum = SN;
            else
                error('Signal "%s" not present in data table', SN );
            end
        end % setSerNum
        
        function obj = setDegree( obj, Degree )
            %--------------------------------------------------------------
            % Set the level-1 polynomial regression order
            %
            % obj = obj.setDegree( Degree );
            %
            % Input Arguments:
            %
            % Degree    --> (int8) polymonial degree {1}
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                Degree  (1,1)   int8 = 1;
            end
            obj.Degree = Degree;
        end % setDegree
        
        function obj = setCovMdlName( obj, CovMdlName )
            %--------------------------------------------------------------
            % Set the covariance model name to either:
            %
            % a) OLS        - ordinary least squares {default}
            % b) Power      - power model
            % c) TwoComp    - Two components of variance
            %
            % obj = setCovMdlName( CovMdlName )
            %
            % Input Arguments:
            %
            % CovMdlName    --> (string) Name of covariance model. {"OLS"}
            %--------------------------------------------------------------
            arguments
                obj         (1,1)
                CovMdlName  (1,1)   string = "OLS"
            end
            try
                obj.CovMdl = CovMdlName;
            catch
                warning('Level-1 Covariance Model "%s" is not recognised',...
                        CovMdlName );
            end
        end % setCovMdlName
        
        function obj = setXname( obj, Xname )
            %--------------------------------------------------------------
            % Set the name of the level-1 covariate (independent variable)
            %
            % obj = obj.setXname( Xname );
            %
            % Input Arguments:
            %
            % Xname     --> (string) Name of level-1 covariate
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                Xname   (1,1)   string   
            end
            Ok = obj.DataObj.channelPresent( Xname );
            if Ok
                obj.Xname = Xname;
            else
                error('Signal "%s" not present in data table', Xname );
            end
        end % setXname
        
        function obj = setYname( obj, Yname )
            %--------------------------------------------------------------
            % Set the name of the level-1 response variable
            %
            % obj = obj.setYname( Yname );
            %
            % Input Arguments:
            %
            % Xname     --> (string) Name of level-1 covariate
            %--------------------------------------------------------------
            arguments
                obj     (1,1)
                Yname   (1,1)   string   
            end
            Ok = obj.DataObj.channelPresent( Yname );
            if Ok
                obj.Yname = Yname;
            else
                error('Signal "%s" not present in data table', Yname );
            end
        end % 
    end % ordinary & constructor methods
    
    methods
        function N = get.numCovPars( obj )
            N = numel( obj.Delta );
        end
        
        function N = get.numCells( obj )
            N = numel( unique( obj.DataObj.DataTable.SerialNumber ) );
        end
    end % get/set methods
    
    methods ( Access = protected )
      
        function X = extractTestXdata( obj, Test, Channels )
            %--------------------------------------------------------------
            % Extract the signal data for a specific test
            %
            % X = obj.extractTestXdata( Test, Channels );
            %
            % Input Arguments:
            %
            % Test      --> (string) Test to extract data for
            % Channels  --> (string) List of channels to extract
            %--------------------------------------------------------------
            arguments
                obj         (1,1)
                Test        (1,1)   string  {mustBeNonempty( Test )}
                Channels    (:,1)   string  {mustBeNonempty( Channels )}
            end
            Ok = obj.DataObj.channelPresent( Channels );
            if all( Ok )
                %----------------------------------------------------------
                % Channels exist, so try to grab the corresponding test 
                % data
                %----------------------------------------------------------
                Tok = obj.testsPresent( Test );
                if Tok
                    D = obj.DataObj.DataTable;
                    Ptr = strcmpi( Test, D.SerialNumber );
                    X = obj.DataObj.extractData( Channels );
                    X = table2array( X( Ptr, : ) );
                end
            else
                %----------------------------------------------------------
                % return a NaN if operation failed
                %----------------------------------------------------------
                X = NaN;
            end
        end % extractTestXdata        
        
        function Ok = testsPresent( obj, Tests )
            %--------------------------------------------------------------
            % Returns logical value to identify tests present. Ok is true
            % iff:
            %
            % (test is present) & (number of data points) > obj.Degree + 2
            %
            % Ok = obj.testsPresent( Tests );
            %
            % Input Arguments:
            %
            % Tests     --> List of tests
            %--------------------------------------------------------------
            Tests = string( Tests );
            D = obj.DataObj.DataTable;
            N = numel( Tests );
            X = string( D.SerialNumber );
            Ok = false( N, 1 );
            Thresh = obj.Degree + 2;
            for Q = 1:N
                NumX = sum( strcmpi( X, Tests( Q ) ) );
                Ok( Q ) = ( NumX >= Thresh );
            end
        end % testsPresent
    end % 
end % classdef
