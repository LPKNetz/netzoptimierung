classdef Leitungen 
    properties
    L
    K_L1
    K_L2
    P_L
    p_L
    C_L
    c_L
    o_KL  		% Erlaube Vorgabe Netzverkn�pfungspunkt  [bool]
    o_PL  		% Erlaube Vorgabe Bemessungsleistung  [bool]
    end
    
    methods (Access = public)
        function obj = Leitungen (l,kL1, kL2, PL, pL, CL, cL, oKL, oPL)
             obj.L = l;              % Leitungsnummer 
             obj.K_L1 = kL1; 		% Netzverkn�pfungspunkt 1 [1]
             obj.K_L2 = kL2; 		% Netzverkn�pfungspunkt 2 [1]    ,    K_L1 ist nicht K_L2
                   % !!!   K_L1 ist nicht K_L2    --> wie formulieren ??
             obj.P_L = PL;           % Bemessungsleistung [kW]   ,   (const.)
             obj.p_L = pL;           % Aktuelle Leistung [1] von K_L1 zu K_L2   ,   p aus [-1;1]
                   % !!!   assume(p_L>=-1 | p_L<=1)
             obj.C_L = CL;           % Fixkosten [?/s]   		  (Realit�t)
             obj.c_L = cL;           % Variable Kosten [?/kWh]   	(B�rse)
			 obj.o_KL = oKL;
             obj.o_PL = oPL;
             

            if obj.o_PL == 1
             obj.P_L;                 % erstelle Variable "Bemessungsleistung" 
            end             
          
            
        end
             function result =  Transportleistung(obj)
                result = obj.p_L*obj.P_L;
             end   
             function result =  Bemessungsleistung_gesamt(obj)
                result = 1*obj.P_L;
             end  
             function result =  gestoert(obj)
                result = false;

                if (obj.p_L*obj.P_L < -obj.P_L) || (obj.p_L*obj.P_L > obj.P_L)
                    result = true;
                end


                %hier kann man alle m�glichen St�rf�lle einbauen
             end
         %    function result = Transportleistung_min(obj)
        %        result = obj.P_N*obj.x_N;
         %    end 
         %    function result =  gestoert(obj)
         %       result = false;
            
         %   if (obj.x_N < obj.x_Nmin) || (obj.x_N > obj.x_Nmax)
         %       result = true;
         %   end
            
            
            %hier kann man alle m�glichen St�rf�lle einbauen
        % end 
    end   
end