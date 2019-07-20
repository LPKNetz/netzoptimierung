classdef Knoten 
    
    properties
    K
    Long_K
    Lat_K
    P_K
    C_K
    o_PK          % Erlaube Vorgabe Bemessungsleistung, muss bei der Objektgenerierung =1 gesetzt werden
    end
    
    methods (Access = public)
    
        function obj = Knoten (k,longK,latK,PK,CK,oPK)
             obj.K = k;            % erstelle Variable "Knotennummer" 
             obj.Long_K = longK;   % erstelle Variable "Longitude"
             obj.Lat_K = latK;     % erstelle Variable "Latitude"
             obj.C_K = CK; 		
			 obj.o_PK = oPK;
             
            if obj.o_PK == 1
             obj.P_K = PK;       % erstelle Variable "Bemessungsleistung Sammelschiene" 
            end   
        end

         function result = kosten (spezifischerKnoten)
			
			%do something
			%result = fancyMaths     => Return value
			
            % Rückgabewert %
            result = 1*spezifischerKnoten.C_K*spezifischerKnoten.P_K;
         end
       
    end   
    
    
    
     methods (Static)


         
     end
end

