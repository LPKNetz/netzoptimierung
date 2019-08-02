classdef Kraftwerke_Lasten_Speicher
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
                 obj.Trend_laden()
             end
        end
        
        
        
        function Trend_laden(obj)
            %val = jsondecode(fileread(fullfile('../data/',obj.TQ{1,1})));
            val = jsondecode(fileread('../data/weather/wind/Bremerhaven_Juli_2019.json'));
            [m,~]=size(val.observations);
            for i=1:m
                dates(i)= val.observations(i).valid_time_gmt;
                values(i) = val.observations(i).wspd;
            end
            obj.Trend = containers.Map(dates,values);
            %view=obj.Trend('1')
            
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


        %hier kann man alle m�glichen St�rf�lle einbauen
        end 
    end    
end