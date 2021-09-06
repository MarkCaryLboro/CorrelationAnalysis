classdef ( Abstract = true ) correlationReport < handle
    % Generates a report for the battery test facility correlation study
    
    properties ( SetAccess = protected )
        Alpha   (1,1)   double      { mustBeGreaterThan( Alpha, 0 ), ...
                                      mustBeLessThan( Alpha, 0.2 ) } = 0.05 % Significance level-1
        M       (1,1)               { mustBeNonempty( M ) }
    end % protected properties
    
    methods ( Abstract = true )
        H = hypothesisTest( obj, varargin )                                 % Conduct hypothesis testing
        CF = correctionFactor( obj, varargin )                              % Calculate correction factors
        surf( obj, varargin )                                               % plot surfaces for Bo and B1 for a given facility
        cont( obj, varargin )                                               % contour plots for Bo and B1 for a given facility
        compare( obj, varargin )                                            % compare Bo and B1 surfaces for two facilities
    end % ordinary & abstract methods
    
    methods
        function obj = setAlpha( obj, P )
            %--------------------------------------------------------------
            % Set the significance level for the hypothesis test
            %
            % obj = obj.setAlpha( P );
            %
            % Input Arguments:
            %
            % P     --> P-level for test [ 0 < P < 0.2 ]
            %--------------------------------------------------------------
            arguments
                obj
                P   (1,1)   double    = 0.05
            end
            obj.Alpha = P;
        end % setAlpha
    end % ordinary methods
end % correlationReport
