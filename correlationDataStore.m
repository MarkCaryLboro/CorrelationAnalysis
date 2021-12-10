classdef ( Abstract = true ) correlationDataStore < handle
    % Abstract datastor interface for the battery test facility correlation 
    % study
    
    properties ( Constant = true, Abstract = true )
        DataType            allowableTestTypes                              % Type of test  
        FileFormats         string                                          % Supported file formats
    end % constant properties 
    
    properties ( SetAccess = protected )
        DataTable           table                                           % Data table
        Units       (1,:)   string                                          % variable units
    end % protected properties
    
    properties ( SetAccess = protected, Dependent = true )
        Variables           string                                          % List of data variables 
    end % Dependent properties
    
    properties ( Access = private )
        Variables_          string
    end
    
    methods ( Abstract = true )
    end % abstract methods signature
    
    methods
        function Ok = channelPresent( obj, Channels )
            %--------------------------------------------------------------
            % Return logical output if supplied signal name is present in
            % the datastore.
            %
            % Ok = obj.channelPresent( Channels );
            %
            % Input Arguments:
            %
            % Channels  --> (string) list of data channels to search for
            %--------------------------------------------------------------
            arguments
                obj
                Channels (1,:)  string        { mustBeNonempty( Channels ) }
            end
            Ok = false( size( Channels ) );
            N = numel( Channels );
            for Q = 1:N
                Ok( Q ) = any( strcmpi( Channels( Q ), obj.Variables ) );
            end
        end % channelPresent
        
        function obj = addData( obj, Fname )
            %--------------------------------------------------------------
            % Add data to existing data table. 
            %
            % obj = obj.addData( Fname );
            %
            % Input Arguments:
            %
            % Fname     --> (string) Name of file containing additional
            %               data
            %--------------------------------------------------------------
            arguments
                obj     (1,1)            
                Fname   (1,1)   string            
            end
            %--------------------------------------------------------------
            % check file exists
            %--------------------------------------------------------------
            if ~isfile( Fname )
                error( 'File "%s" does not exist', Fname );
            end
            %--------------------------------------------------------------
            % Check the file format is supported
            %--------------------------------------------------------------
            Ok = obj.chkFileFormat( Fname );
            if Ok
                Data = obj.importData( Fname );
                if isempty( obj.DataTable )
                    obj.DataTable = Data;
                else
                    Data = Data( :, obj.Variables );
                    obj.DataTable = vertcat( obj.DataTable, Data );
                end
            else
                %----------------------------------------------------------
                % Unsupported file format
                %----------------------------------------------------------
                [ ~, ~, Ext ] = fileparts( Fname );
                error( 'Unsupported data file format %s', Ext );
            end
        end % addData
        
        function T = extractData( obj, Channels )
            %--------------------------------------------------------------
            % Extract data from the data table
            %
            % T = obj.extractData( Channels );
            %
            % Input Channels
            %
            % Channels  --> (string) List of channels to extract
            %--------------------------------------------------------------
            if ( nargin < 2 )
                Channels = obj.Variables;
            end
            Channels = string( Channels );
            Ok = contains( Channels, obj.Variables, 'IgnoreCase', true );
            if all( Ok )
                T = obj.DataTable( :, Channels );
            else
                Missing = Channels( ~Ok );
                obj.missingChannels( Missing );
            end
        end % extractData
    end % ordinary methods
    
    methods
        function V = get.Variables( obj )
            % Fetch list of variables
            V = obj.Variables_;
        end
    end % get/set methods
    
    methods ( Access = protected )
        function Data = importData( obj, FileName )
            %--------------------------------------------------------------
            % Import the data from a supported file format and output to a 
            % table
            %
            % Data = obj.importData( FileName );
            %
            % Input Arguments:
            %
            % FileName      --> (string) Name of file to import 
            %--------------------------------------------------------------
            if ( nargin < 2 ) || ~isfile( FileName )
                %----------------------------------------------------------
                % Prompt user for filename
                %----------------------------------------------------------
                [ FileName, Fpath ] = uigetfile( cellstr( obj.FileFormats ),...
                    'Select Facility Correlation Rate Test Data File',...
                    'MultiSelect', 'off');
                if isnumeric( FileName ) 
                    %------------------------------------------------------
                    % user hit the cancel button
                    %------------------------------------------------------
                    error('Must supply a valid file name for data import'); 
                end     
            elseif isfile( FileName )
                [ Fpath, FileName, Ext ] = fileparts( FileName );
                FileName = strjoin( string( { FileName, Ext } ), '' );
            end
            FileName = fullfile( Fpath, FileName );
            %--------------------------------------------------------------
            % Find limits of data in excel spreadsheet
            %--------------------------------------------------------------
            [ Lrow, Lcol ] = obj.findLastRow( FileName );
            %--------------------------------------------------------------
            % Create range to read
            %--------------------------------------------------------------
            Finish = obj.makeRange( Lrow, Lcol );
            Start = obj.makeRange( 1, 1 );
            Range = strjoin( [ Start, Finish ], ":" );
            %--------------------------------------------------------------
            % Read the xlsx file
            %--------------------------------------------------------------
            [ ~, ~, Data ] = xlsread( FileName, 1, Range );
            obj.Variables_ = string( Data( 1, : ) );
            obj.Units = string( Data( 2, : ) );
            Data = Data( ( 3:end ), : );
            Data = cell2table( Data );
            Data.Properties.VariableNames = obj.Variables;
            T = string( Data.Temperature );
            T = double( T );
            Data.Temperature = T;
        end % importData            
        
        function Ok = chkFileFormat( obj, Fname )
            %--------------------------------------------------------------
            % Returns logical value to check file is of the expected type
            %
            % Ok = obj.chkFileFormat( Fname )
            %
            % Input Arguments:
            %
            % Fname     --> Name of the data import file
            %--------------------------------------------------------------
            [ ~, ~, Ext ] = fileparts( Fname );
            Ok = any( strcmpi( Ext, obj.FileFormats ) ); 
        end % fileFormat
    end % protected methods
    
    methods ( Access = private )
    end % private methods
    
    methods ( Static = true, Hidden = true )
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
        
        function missingChannels( Missing )
            %--------------------------------------------------------------
            % Write out list of missing channels to user
            %
            % obj.missingChannels( Missing, Source );
            %
            % Input Arguments:
            %
            % Missing   --> (string) list of missing channels
            %--------------------------------------------------------------
            fprintf( 2, "\n\nFollowing channels were missing from supplied list in DMS files:\n\n");
            Num = numel( Missing );
            for Q = 1:Num
                fprintf( 2, '\t"%s"\n', Missing( Q ) );
            end
            fprintf("\n\n");
        end % missingChannels
 
        function  Range = makeRange( R, C )
            %--------------------------------------------------------------
            % Convert row & column pointers to excel range
            %
            % Range = obj.makeRange( R, C );
            %
            % Input Arguments:
            %
            % R     --> Row number
            % C     --> Column number
            %--------------------------------------------------------------
            L = floor( ( C - 1 ) / 26 );
            if ( L > 0 )
                %----------------------------------------------------------
                % Define leading letter
                %----------------------------------------------------------
                LeadLetter = string( upper( char( 96 + L ) ) );
            else
                LeadLetter = string.empty;
            end
            Range = string( upper( char( 96 + C ) ) );
            Range = strjoin( [ LeadLetter, Range, string( R ) ], '' );
        end    
    end % static methods
end