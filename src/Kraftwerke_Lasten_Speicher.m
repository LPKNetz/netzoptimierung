classdef Kraftwerke_Lasten_Speicher < handle
    properties
                N           % Nummer 
                K           % Netzverknüpfungspunkt
                P_N  		% Nennleistung [kW]          (const.)
                x_Nmin  	% Min. Stellgröße [1]        x aus [-1;1]
                x_Nmax  	% Max. Stellgröße [1]        x aus [-1;1]  ,  x_Nmax  >=  x_Nmin  
                x_N  		% Aktuelle Stellgröße [1]    x aus [x_Nmin ; x_Nmax]  
                    % assume(x_N>=x_Nmin | x_N<=x_Nmax)

                R_N  		% Regelart [enam]   ,   R aus {Festleistung, Fremd, Klima, Selbst}
                    % R_N={Festleistung, Fremd, Klima, Selbst};

                C_N  		% Fixkosten [?/s]   	
                c_N  		% Variable Kosten [?/kWh]  

                o_NP  		% Erlaube Vorgabe Nennleistung  [bool]
    
% Zusätzlich bei Speicher:
                B_N  		% Bunkergröße [kWh]   ,   (const.)
                b_N  		% Bunkerfüllstand [1]  ,  b aus [0;1]
                n_N  		% Nachfüllrate (bzw. Selbstentladung) [kW]

                o_MK  		% Erlaube Vorgabe Netzverknüpfungspunkt  [bool]
                o_NB  		% Erlaube Vorgabe Bunkergröße  [bool]
                TQ          % Pfad Trendquelle (Kurven)
                Trend       % Trend (=Windgeschwindigkeit oder Solare Strahlung oder hydro etc.)
    end
    
    methods (Access = public)
        function obj = Kraftwerke_Lasten_Speicher (Number,k, PN,xNmin,xNmax,xN,RN,CN,cN,oNP,BN,bN,nN,oMK,oNB,tq)
             obj.N = Number{1,1};
             obj.K = k{1,1};
             obj.P_N = PN{1,1};            
             obj.x_Nmin = xNmin{1,1};  
             obj.x_Nmax = xNmax{1,1};  
             obj.x_N = xN{1,1};
             obj.R_N = RN{1,1};	
             obj.C_N = CN{1,1};
             obj.c_N = cN{1,1};
             obj.o_NP = oNP{1,1};

             obj.B_N = BN{1,1};
             obj.b_N = bN{1,1};
             obj.n_N = nN{1,1};
             obj.o_MK = oMK{1,1};
             obj.o_NB = oNB{1,1};  
             obj.TQ = tq{1,1};
              
             if obj.R_N == 3 || obj.R_N == 4
                 obj.Trend=obj.Trend_laden();
             end
        end
        function result = Trend_laden(obj)
            val = jsondecode(fileread(fullfile('../data/',obj.TQ{1,1})));
            [m,~]=size(val.observations);
            C=zeros([m,2]);
            for i=1:m
                C(i,1) = val.observations(i).valid_time_gmt;
                C(i,2) = val.observations(i).wspd/25;     % teilen durch 25, da Volllast bei 25 km/h
                result = C;
            end
        end
        function result = Zeit_setzen(obj,time)
            [m,~]=size(obj.Trend);
            for i=2:m
                if obj.Trend(i,1) > time
                    x = obj.Trend(i-1,2);
                    obj.Sollwert_setzen(x);
                    break
                end
            end
            
            result = obj;
        end
        
        function Sollwert_setzen(obj,x_N)
            if x_N >= obj.x_Nmax
                obj.x_N = obj.x_Nmax;
            elseif x_N <= obj.x_Nmin
                obj.x_N = obj.x_Nmin;
            else
                obj.x_N = x_N;
            end
            %result = obj;
        end
        function result = Regelreserve_auf(obj)
            if obj.R_N == 2
                result = obj.x_Nmax - obj.x_N;
            else
                result = 0;
            end
        end
        function result = Regelreserve_auf_KW(obj)
            if obj.R_N == 2
                result = obj.P_N * (obj.x_Nmax - obj.x_N);
            else
                result = 0;
            end
        end
        function result = Regelreserve_ab(obj)
            if obj.R_N == 2
                result = obj.x_N - obj.x_Nmin;
            else
                result = 0;
            end
        end
        function result = Regelreserve_ab_KW(obj)
            if obj.R_N == 2
                result = obj.P_N * (obj.x_N - obj.x_Nmin);
            else
                result = 0;
            end
        end
        function result =  Nennleistung_min(obj)
            result = obj.P_N*obj.x_Nmin;
        end   
        function result =  Nennleistung_max(obj)
            result = obj.P_N*obj.x_Nmax;
        end   
        function result =  Leistung_aktuell(obj)
            result = obj.P_N*obj.x_N;
        end
        function result = Netzverknuepfungspunkt(obj)
            result = obj.K;
        end
        function result =  gestoert(obj)
            result = false;
            if (obj.x_N < obj.x_Nmin) || (obj.x_N > obj.x_Nmax)
                result = true;
            end


        %hier kann man alle möglichen Störfälle einbauen
        end 
    end    
end