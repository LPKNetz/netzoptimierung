classdef Kraftwerke_Lasten_Speicher < handle
    properties
                N           % Nummer 
                K           % Netzverkn�pfungspunkt
                P_N  		% Nennleistung [kW]          (const.)
                x_Nmin  	% Min. Stellgr��e [1]        x aus [-1;1]
                x_Nmax  	% Max. Stellgr��e [1]        x aus [-1;1]  ,  x_Nmax  >=  x_Nmin  
                x_N  		% Aktuelle Stellgr��e [1]    x aus [x_Nmin ; x_Nmax]  
                    % assume(x_N>=x_Nmin | x_N<=x_Nmax)
                R_N  		% Regelart [enam]   ,   R aus {Festleistung, Fremd, Klima, Selbst}
                    % R_N={Festleistung, Fremd, Klima, Selbst};
                C_N  		% Fixkosten [?/s]   	
                c_N  		% Variable Kosten [?/kWh]  
                o_NP  		% Erlaube Vorgabe Nennleistung  [bool]
% Zus�tzlich bei Speicher:
                B_N  		% Bunkergr��e [kWh]   ,   (const.)
                b_N  		% Bunkerf�llstand [1]  ,  b aus [0;1]
                n_N  		% Nachf�llrate (bzw. Selbstentladung) [kW]
                o_MK  		% Erlaube Vorgabe Netzverkn�pfungspunkt  [bool]
                o_NB  		% Erlaube Vorgabe Bunkergr��e  [bool]
                TQ          % Pfad Trendquelle (Kurven)
                Trend       % Trend (=Windgeschwindigkeit oder Solare Strahlung oder hydro etc.)
                t_alt       % Letzer Zeitstempel
                delta_t_alt % Letzte Zeitschlitzdauer
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
             
             obj.t_alt = 0;
             obj.delta_t_alt = 15*60; %Variable Zeitschlitzl�nge
              
             if obj.R_N == 3 %|| obj.R_N == 4
                 obj.Trend=obj.Trend_laden();
             end
             
             if obj.R_N == 4 
                 obj.Trend=obj.Trend_laden_2();
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
        function result = Trend_laden_2(obj)
            D = importdata(fullfile('../data/',obj.TQ{1,1}));
                result = D;
        end
        function result = Fixkosten(obj)
            result = obj.delta_t_alt * (obj.C_N/(8760*3600));  % liefert ?/Zeitschlitz
        end
        function result = VariableKosten(obj)
            result = obj.delta_t_alt * abs(obj.Leistung_aktuell()) * obj.c_N/3600; % liefert ?/Zeitschlitz
        end
        % Bei Speichern ist grunds�tzlich zuerst die Zeit zu setzen, bevor die Leistung verstellt wird.
        function result = Zeit_setzen(obj,time)
            if obj.istSpeicher()
                obj.Speicher_rechnen(time);
            end
            
            [m,~]=size(obj.Trend);
            if m < 2
                return;
            end
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
            min = obj.VerfuegbareStellgroesseBezug();
            max = obj.VerfuegbareStellgroesseLieferung();
            if x_N >= max
                obj.x_N = max;
            elseif x_N <= min
                obj.x_N = min;
            else
                obj.x_N = x_N;
            end
            
            if obj.SpeicherIstVoll() && obj.x_N <= 0
                obj.x_N = 0;
            elseif obj.SpeicherIstLeer && obj.x_N >= 0
                obj.x_N = 0;
            end
        end
        function result = Regelreserve_auf(obj)
            if obj.R_N == 2
                max = obj.VerfuegbareStellgroesseLieferung();
                result = max - obj.x_N;
                if (result < 0)
                    result = 0;
                end
                if obj.istSpeicher() && obj.b_N <= 0
                    result = 0;
                end
            else
                result = 0;
            end
        end
        function result = Regelreserve_auf_KW(obj) % ENTLADEN
            result = obj.P_N * obj.Regelreserve_auf();
        end
        function result = Regelreserve_ab(obj) % LADEN
            if obj.R_N == 2
                min = obj.VerfuegbareStellgroesseBezug();
                result = obj.x_N - min;
                if (result < 0)
                    result = 0;
                end
                if obj.istSpeicher() && obj.b_N >= 1
                    result = 0;
                end
            else
                result = 0;
            end
        end
        function result = Regelreserve_ab_KW(obj)
            result = obj.P_N * obj.Regelreserve_ab();
        end
        function result = Nennleistung_min(obj)
            result = obj.P_N*obj.x_Nmin;
        end   
        function result = Nennleistung_max(obj)
            result = obj.P_N*obj.x_Nmax;
        end   
        function result = Leistung_aktuell(obj)
            result = obj.P_N*obj.x_N;
            if obj.istSpeicher() && obj.b_N >= 1 && obj.x_N <= 0
                result = 0;
            elseif obj.istSpeicher() && obj.b_N <= 0 && obj.x_N >= 0
                result = 0;
            end
        end
        function result = Netzverknuepfungspunkt(obj)
            result = obj.K;
        end
        function result = gestoert(obj)
            result = false;
            if (obj.x_N < obj.x_Nmin) || (obj.x_N > obj.x_Nmax)
                result = true;
            elseif ((obj.b_N < 0) || (obj.b_N > 1))
                result = true;
            end


        %hier kann man alle m�glichen St�rf�lle einbauen
        end 
        function result = istSpeicher(obj)
            if obj.x_Nmin < -0.001 && obj.B_N > 0.001 % "-" (das Minus) nachtr�glich hinzugef�gt
                result = true;
            else
                result = false;
            end
        end
%        function result = SpeicherDarfEntladen(obj)
%            if (obj.x_N > 0 && (obj.istSpeicher() && (obj.x_N * obj.P_N * obj.delta_t_alt / 3600) > (obj.b_N * obj.B_N)))
%                result = false; 
%            else
%                result = true;
%            end end
%        function result = SpeicherDarfLaden(obj)
%            if (obj.x_N < 0 && (obj.istSpeicher() && (-obj.x_N * obj.P_N) * (obj.delta_t_alt / 3600) > (obj.B_N - obj.b_N * obj.B_N)))
%                result = false;
%            else
%                result = true;
%            end end
        function result = SpeicherIstLeer(obj)
            result = (obj.istSpeicher() && obj.b_N <= 0);
        end
        function result = SpeicherIstVoll(obj)
            result = (obj.istSpeicher() && obj.b_N >= 1);
        end
        function result = VerfuegbareLeistungBezug_kW(obj)
            result = obj.P_N * obj.x_Nmin;
            if (obj.istSpeicher())  % Ladebetrieb
                Restenergie = (1 - obj.b_N) * obj.B_N;  % kWh noch ladbar
                power = -Restenergie / (obj.delta_t_alt / 3600);
                if (power > result)
                    result = power;
                end
            elseif (obj.gestoert())
                result = 0;
            end
        end
        function result = VerfuegbareStellgroesseBezug(obj)
            result = obj.VerfuegbareLeistungBezug_kW() / obj.P_N;
        end
        function result = VerfuegbareLeistungLieferung_kW(obj)
            result = obj.P_N * obj.x_Nmax;
            if (obj.istSpeicher())  % Entladebetrieb
                Restenergie = obj.b_N * obj.B_N;  % kWh noch entladbar
                power = Restenergie / (obj.delta_t_alt / 3600);
                if (power < result)
                    result = power;
                end
            elseif (obj.gestoert())
                result = 0;
            end
        end
        function result = VerfuegbareStellgroesseLieferung(obj)
            result = obj.VerfuegbareLeistungLieferung_kW() / obj.P_N;
        end  
    end
    methods (Access = private)
        function Speicher_rechnen(obj, time)
            if (obj.t_alt == 0)
                obj.t_alt = time;
                return;
            end
            
            Zeitschlitzdauer = time - obj.t_alt;    % Sekunden
            obj.delta_t_alt = Zeitschlitzdauer;
            delta_kWh = -obj.Leistung_aktuell() * Zeitschlitzdauer / 3600;
            
            obj.b_N = obj.b_N + (delta_kWh / obj.B_N);
            
            obj.t_alt = time;
        end
    end
end