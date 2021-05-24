classdef correlationDesign < handle
    % Design generators for the battery facility correlation study
    
    properties ( SetAccess = immutable )
        Generator       string              = "Rate"
    end % immutable properties
    
    methods
        function obj = correlationDesign( Generator )
            %--------------------------------------------------------------
            % correlationDesign class constructor method
            %
            % obj = correlationDesign( Generator );
            %
            % Input Arguments:
            %
            % Generator     --> (string ), design generator type. May be
            %                   either {"Rate"}, "Pulse" or "Capacity"
        end
    end % Constructor and ordinary methods
end % correlationDesign