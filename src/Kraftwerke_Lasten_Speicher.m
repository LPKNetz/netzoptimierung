classdef Kraftwerke_Lasten_Speicher
    properties
                N           % Nummer
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
    end
    
    methods (Access = public)
        function obj = Kraftwerke_Lasten_Speicher (Number,PN,xNmin,xNmax,xN,RN,CN,cN,oNP,BN,bN,nN,oMK,oNB)
             obj.N = Number;
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


            if obj.o_NP == 1
             obj.P_N       
            end  
            
            %      if obj.o_MK == 1
              % ???       
            % end          
            if obj.o_NB == 1
             obj.B_N       
            end   
        end
		
		function [result] = keineAhnung ()	
			%do something
			%result = fancyMaths     => Return value	
        end   
    end    
end