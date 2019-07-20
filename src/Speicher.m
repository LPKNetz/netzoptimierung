classdef Speicher < Kraftwerke_Lasten_Speicher
    
    properties
        
% Zusätzlich bei Speicher:
    B_N  		% Bunkergröße [kWh]   ,   (const.)
    b_N  		% Bunkerfüllstand [1]  ,  b aus [0;1]
	n_N  		% Nachfüllrate (bzw. Selbstentladung) [kW]
    
    o_MK  		% Erlaube Vorgabe Netzverknüpfungspunkt  [bool]
    o_NB  		% Erlaube Vorgabe Bunkergröße  [bool]
    end
    
    methods (Access = public)
        function obj = Speicher (BN,bN,nN,oMK,oNB)
             obj.B_N = BN;
             obj.b_N = bN;
             obj.n_N = nN;
             
             obj.o_MK = oMK;
             obj.o_NB = oNB;
             
      %      if obj.o_MK == 1
              % ???       
      %      end          
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