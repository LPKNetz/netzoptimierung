classdef Leitungen < handle
    properties
        L
        K_L1
        K_L2
        P_L
        p_L
        R_L
        C_L
        c_L
        o_KL  		% Erlaube Vorgabe Netzverknüpfungspunkt  [bool]
        o_PL  		% Erlaube Vorgabe Bemessungsleistung  [bool]
        t_alt       % Letzer Zeitstempel
        delta_t_alt % Letzte Zeitschlitzdauer
    end
    
    methods (Access = public)
        function obj = Leitungen (l,kL1, kL2, PL, pL, RL, CL, cL, oKL, oPL)
            obj.L = l;              % Leitungsnummer
            obj.K_L1 = kL1; 		% Netzverknüpfungspunkt 1 [1]
            obj.K_L2 = kL2; 		% Netzverknüpfungspunkt 2 [1]    ,    K_L1 ist nicht K_L2
            % !!!   K_L1 ist nicht K_L2    --> wie formulieren ??
            obj.P_L = PL;           % Bemessungsleistung [kW]   ,   (const.)
            obj.p_L = pL;           % Aktuelle Leistung [1] von K_L1 zu K_L2   ,   p aus [-1;1]
            % !!!   assume(p_L>=-1 | p_L<=1)
            obj.R_L = RL;
            obj.C_L = CL;           % Fixkosten [?/s]   		  (Realität)
            obj.c_L = cL;           % Variable Kosten [?/kWh]   	(Börse)
            obj.o_KL = oKL;
            obj.o_PL = oPL;
            obj.t_alt = 0;
            obj.delta_t_alt = 15*60;
        end
        function result =  Transportleistung(obj)
            result = obj.p_L*obj.P_L;
        end
        
        function result =  Leitungswiderstand(obj)
            result = obj.R_L;
        end
        function result = Aktuelle_Leistung_setzen_in_kW(obj,p)
            obj.p_L=p/obj.P_L;
            result = obj;
        end
        
        
        
        
        
        
        
        function result =  Startknoten(obj)
            result = obj.K_L1;
        end
        function result =  Endknoten(obj)
            result = obj.K_L2;
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
            result = obj.delta_t_alt * (obj.C_L/(8760*3600));  % liefert ?/Zeitschlitz
        end
        function result = VariableKosten(obj)
            result = obj.delta_t_alt * abs(obj.Leistung_aktuell()) * obj.c_L/3600; % liefert ?/Zeitschlitz
        end
        
        function result = Leistung_aktuell(obj)
            result = obj.p_L * obj.P_L;
        end
        function result =  Bemessungsleistung_gesamt(obj)
            result = obj.P_L;
        end
        function result =  gestoert(obj)
            result = false;
            
            if (obj.p_L*obj.P_L < -obj.P_L) || (obj.p_L*obj.P_L > obj.P_L)
                result = true;
            end
            
            
            %hier kann man alle möglichen Störfälle einbauen
        end
        %    function result = Transportleistung_min(obj)
        %        result = obj.P_N*obj.x_N;
        %    end
        %    function result =  gestoert(obj)
        %       result = false;
        
        %   if (obj.x_N < obj.x_Nmin) || (obj.x_N > obj.x_Nmax)
        %       result = true;
        %   end
        
        
        %hier kann man alle möglichen Störfälle einbauen
        % end
    end
end