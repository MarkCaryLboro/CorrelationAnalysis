classdef rateData < correlationDataStore
    
    properties ( Constant = true )
        TestName            allowableTestTypes      = "Rate"     
        FileFormats         string                  = ".xlsx"
    end % constant properties
    
    properties ( SetAccess = protected )
        DataTable           table
    end % protected properties    
    
    methods  
        function T = importData( obj, FileName )
            %--------------------------------------------------------------
            % Import the data from a *.mat file and output to a table
            %
            % T = obj.importData( FileName );
            %
            % Input Arguments:
            %
            % FileName  --> (string) Name of excel file to import 
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
                [ Fpath, FileName, Ext ] = fileparts( which( FileName ) );
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
%             Range = 
            %--------------------------------------------------------------
            % Read the xlsx file
            %--------------------------------------------------------------
            [ Num, Txt, Data ] = xlsread( FileName, 1 );
        end % importData
    end % constructor and ordinary methods
    
    
end % rateData