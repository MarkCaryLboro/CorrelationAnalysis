classdef rateData < correlationDataStore
    
    properties ( Constant = true )
        TestName            allowableTestTypes       = "Rate"              
    end % constant properties
    
    properties ( SetAccess = protected )
        DataTable           table
    end % protected properties    
    
    methods  
    end % constructor and ordinary methods
end % rateData