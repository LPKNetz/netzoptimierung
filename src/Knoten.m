classdef Knoten < handle
    
    properties
        K
        Long_K
        Lat_K
        P_K
        C_K
        o_PK          % Erlaube Vorgabe Bemessungsleistung, muss bei der Objektgenerierung =1 gesetzt werden
        t_alt       % Letzer Zeitstempel
        delta_t_alt % Letzte Zeitschlitzdauer
    end
    
    methods (Access = public)
        
        function obj = Knoten (k,longK,latK,PK,CK,oPK)
            obj.K = k;            % erstelle Variable "Knotennummer"
            obj.Long_K = longK;   % erstelle Variable "Longitude"
            obj.Lat_K = latK;     % erstelle Variable "Latitude"
            obj.P_K = PK;
            obj.C_K = CK;
            obj.o_PK = oPK;
            obj.t_alt = 0;
        end
        
        
        function Zeit_setzen(obj,time)
            if (obj.t_alt == 0)
                obj.t_alt = time;
                return;
            end
            Zeitschlitzdauer = time - obj.t_alt;    % Sekunden
            obj.delta_t_alt = Zeitschlitzdauer;
            obj.t_alt = time;
        end
        function result = Fixkosten(obj)
            result = obj.delta_t_alt * (obj.C_K/(8760*3600));  % liefert ?/Zeitschlitz
        end
        function result = VariableKosten(obj)
            result = 0;
        end
        
        
    end
    
    
    
    methods (Static)
        
        
        
    end
end

