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
    end
    
    methods (Access = public)
        function obj = Kraftwerke_Lasten_Speicher (Number,k, PN,xNmin,xNmax,xN,RN,CN,cN,oNP,BN,bN,nN,oMK,oNB)
             obj.N = Number;
             obj.K = k;
             obj.P_N = PN;            
             obj.x_Nmin = xNmin;  
             obj.x_Nmax = xNmax;  
             obj.x_N = xN;
             obj.R_N = RN; 		
             obj.C_N = CN;
             obj.c_N = cN;
             obj.o_NP = oNP;

             obj.B_N = BN;
             obj.b_N = bN;
             obj.n_N = nN;
             obj.o_MK = oMK;
             obj.o_NB = oNB;  
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