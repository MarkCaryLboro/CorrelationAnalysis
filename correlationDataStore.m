classdef ( Abstract = true ) correlationDataStore < handle
    % A database object for the battery test facility correlation data
    
    properties ( SetAccess = immutable, Abstract = true )
        TestName            allowableTestTypes                    
    end % immutable properties
    
    methods
        function obj = addData( obj, Data )
        end % addData
    end % constructor and ordinary methods
end