classdef ( Abstract = true ) correlationDataStore < handle
    % Abstract datastor interface for the battery test facility correlation 
    % study
    
    properties ( Constant = true, Abstract = true )
        TestName            allowableTestTypes         
        FileFormats         string
    end % constant properties
    
    properties ( SetAccess = protected, Abstract = true )
        DataTable           table
    end % protected properties
    
    properties ( SetAccess = protected, Dependent = true )
        Facilities          string                                          % List of available facilities
        BaterryTypes        string                                          % List of available battery types
    end % Dependent properties
    
    methods ( Abstract = true )
        T = importData( obj, FileName )                                     % Import the data from a file
    end % abstract methods signature
    
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
            %--------------------------------------------------------------
            % Extract data from data table
            %
            %--------------------------------------------------------------
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
    
    methods ( Access = protected )
        function Ok = chkFileFormat( obj, Fname )
            %--------------------------------------------------------------
            % Returns logical value 
        end % fileFormat
    end % protected methods
    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true )
        function [LastRow, LastCol ] = findLastRow( ExcelFile, SheetName )
            %--------------------------------------------------------------
            % Return last nonempty row & columnin a spreadsheet
            %
            % [LastRow, LastCol ] = obj.findLastRow( ExcelFile, SheetName);
            %
            % Input Arguments:
            %
            % ExcelFile     --> Full file specification for excel file
            % SheetName     --> Name of sheet to search {1}
            %--------------------------------------------------------------
            if ( nargin < 2 )
                SheetName = 1;
            end
            E = actxserver('Excel.Application');                            % start excel
            Cleanup = onCleanup(@() E.Quit);                                % make sure to close excel even if an error occurs. Will also close the workbook if it is open since it never gets modified
            W = E.Workbooks.Open( ExcelFile );                              % open workbook
            S = get( W.Sheets, 'Item', SheetName );
            LastRow = S.UsedRange.Rows.Count;                               % get last used row
            LastCol = S.UsedRange.Columns.Count;                            % get last used column 
            W.Close;
        end % findLastRow
    end % static methods
end