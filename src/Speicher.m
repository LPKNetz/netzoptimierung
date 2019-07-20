classdef Speicher < Kraftwerke_Lasten_Speicher
    
    properties
        
% Zus�tzlich bei Speicher:
    B_N  		% Bunkergr��e [kWh]   ,   (const.)
    b_N  		% Bunkerf�llstand [1]  ,  b aus [0;1]
	n_N  		% Nachf�llrate (bzw. Selbstentladung) [kW]
    
    o_MK  		% Erlaube Vorgabe Netzverkn�pfungspunkt  [bool]
    o_NB  		% Erlaube Vorgabe Bunkergr��e  [bool]
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