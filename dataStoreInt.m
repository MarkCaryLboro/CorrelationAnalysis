classdef  dataStoreInt < handle
    % Abstract strategy interface for battery test facility correlation 
    % analysis datastores
    properties ( SetAccess = immutable )
        Source          correlationDataStore    = correlationDataStore.empty
    end % protected and abstract properties
    
    properties ( SetAccess = protected )
        DataObj                                                             % Datastore object, switches as state changes
        State     
    end % protected properties
    
    properties ( SetAccess = private )
        Listener                                                            % Pointer to listener object
    end % private properties
    
    methods
    end % ordinary methods
    
    methods ( Access = protected )
        function switchState( obj, ~, EventData )
            %--------------------------------------------------------------
            % Switch the desired state on demand
            %
            % obj.switchState( ~, EventData )
            %
            % Input Arguments:
            %
            % EventData     --> event.EventData object
            %--------------------------------------------------------------
            obj.State = EventData.AffectedObject.InjectionState;
        end % switchState
    end % protected methods
end % dataStoreInt