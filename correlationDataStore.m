classdef ( Abstract = true ) correlationDataStore < handle
    % Abstract datastor interface for the battery test facility correlation 
    % study
    
    properties ( Constant = true, Abstract = true )
        TestName            allowableTestTypes              
    end % constant properties
    
    properties ( SetAccess = protected, Abstract = true )
        DataTable           table
    end % protected properties
    
    properties ( SetAccess = protected, Dependent = true )
        Facilities          string                                          % List of available facilities
        BaterryTypes        string                                          % List of available battery types
    end % Dependent properties
    
    methods
        function obj = addData( obj, Data )
            %--------------------------------------------------------------
            % Add data to data table. Data is stored in a table indexed by
            % (rows) facilities and (columns) battery types.
            %
            % obj = obj.addData( Data );
            %
            % Input Arguments:
            %
            % Data  --> (table) Data table containing additional data to be
            %           added to the database
            %--------------------------------------------------------------
            arguments
                obj(1,1)         
                Data        table         { mustBeNonempty( Data ) }
            end
            %--------------------------------------------------------------
            % Append new data to existing table.
            %--------------------------------------------------------------
            Data = obj.newData( Data );
            
        end % addData
        
        function T = extractData( obj )
        end % extractData
    end % constructor and ordinary methods
    
    methods
        function F = get.Facilities( obj )
            % Return available facilites
            F = string( obj.DataTable.Properties.RowNames );
        end
        
        function B = get.BaterryTypes( obj )
            % Return available battery types
            B = string( obj.DataTable.Properties.VariableNames );
        end
    end % get/set methods
    
    methods ( Access = private )
    end % private methods
end