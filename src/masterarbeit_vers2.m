clc, clear, close all

%% 1.DESCRIPTION:
%% 1.1 Knoten
% K          % Knotennummer [Netzverknüpfungspunkt]
% Long_K     % Longitude
% Lat_K      % Latitude
% P_K  		% Bemessungsleistung Sammelschiene [kW]


% Optimizer Einstellungen:
% o_PK=1;          % Erlaube Vorgabe Bemessungsleistung


% Kosten:
% C_K  		% Fixkosten [?/s]




%% 1.2 Leitungen
% L          % Leitungsnummer 
% K_L1 		% Netzverknüpfungspunkt 1 [1]
% K_L2 		% Netzverknüpfungspunkt 2 [1]    ,    K_L1 ist nicht K_L2
      % !!!   K_L1 ist nicht K_L2    --> wie formulieren ??
% P_L 		% Bemessungsleistung [kW]   ,   (const.)
% p_L 		% Aktuelle Leistung [1] von K_L1 zu K_L2   ,   p aus [-1;1]
%   assume(p_L>=-1 | p_L<=1)


% Optimizer Einstellungen:
% o_KL=0;  		% Erlaube Vorgabe Netzverknüpfungspunkt  [bool]
% o_PL=1;  		% Erlaube Vorgabe Bemessungsleistung  [bool]


% Kosten:
% C_L  		% Fixkosten [?/s]   		  (Realität)
% c_L  		% Variable Kosten [?/kWh]   	(Börse)


%% 1.3 Kraftwerk / Last / Speicher
% N         % Nummer
% K_N  		% Netzverknüpfungspunkt [1]  (const.)
% P_N  		% Nennleistung [kW]          (const.)
% x_Nmin  	% Min. Stellgröße [1]        x aus [-1;1]
% x_Nmax  	% Max. Stellgröße [1]        x aus [-1;1]  ,  x_Nmax  >=  x_Nmin  
% x_N  		% Aktuelle Stellgröße [1]    x aus [x_Nmin ; x_Nmax]  
% assume(x_N>=x_Nmin | x_N<=x_Nmax)

% R_N  		% Regelart [enam]   ,   R aus {Festleistung, Fremd, Klima, Selbst}
%    R_N={Festleistung, Fremd, Klima, Selbst};

% Zusätzlich bei Speicher:
% B_N  		% Bunkergröße [kWh]   ,   (const.)
% b_N  		% Bunkerfüllstand [1]  ,  b aus [0;1]
% assume(b_N>=0 | b_N<=1)

% n_N  		% Nachfüllrate (bzw. Selbstentladung) [kW] 


% Optimizer Einstellungen:
% o_MK=1;  		% Erlaube Vorgabe Netzverknüpfungspunkt  [bool]
        %!!! ABER EIGENTLICH NUR FÜR SPEICHER ERLAUBT ?!
% o_NP=1;  		% Erlaube Vorgabe Nennleistung  [bool]

% o_NB=1;  		% Erlaube Vorgabe Bunkergröße  [bool]
        %!!! ABER EIGENTLICH NUR FÜR SPEICHER ERLAUBT ?!

        
% Kosten:
% C_N  		% Fixkosten [?/s]   	
% c_N  		% Variable Kosten [?/kWh]  







%% 2.CONSTRAINTS:

% Knotengleichung für Knoten K als if-Test mit 1/0 - Entscheidungsvariable:
if q1 == 0
    K_Gleichung = 1;
elseif q1 ~= 0
    K_Gleichung = 0;
end    


% Gleichung des KW als if-Test mit 1/0 - Entscheidungsvariable:
fun = @(t) -n_N+x_N*P_N
q2 = integral(fun,0,96)
syms KW_Gleichung

if q2 == -b_N*B_N
    KW_Gleichung = 1;
elseif q2 ~= -b_N*B_N
    KW_Gleichung = 0;
end
    
%% 3. PROBLEM:
% siehe Word-Dokument: ma-modell.docx

%% 4. PROGRAMM:

% NETZREGLER:   (nicht sicher ob das stimmt...)
%Regel: ?langsamstes (regelbares) Kraftwerk ist wichtigstes Kraftwerk? 
% -einachst möglicher Regler = Staffelplan (ist nicht der optimalste) ->  für 15 min - Zeitschlitze
% -die passenden Ns (=Kraftwerke) müssen ausgewählt werden
% -erzeugte Leistung ist zu jedem Zeitpunkt = verbrauchter Leistung

syms power_tminus1  %Leistung zum letzten Zeitpunkt (also 15 min davor)  
syms power_t0       %Leistung zum aktuellen Zeitpunkt 
syms power(prio1)   %aktuelle Gesamt-Leistung aller Groß-Kohlekraftwerke
syms power(prio2)   %aktuelle Gesamt-Leistung aller Wasserkraftwerke
syms power(prio3)   %aktuelle Gesamt-Leistung aller Gaskraftwerke
syms power(prio4)   %aktuelle Gesamt-Leistung aller Energie-Speicher



if sum(x_Nfest,klima,selbst) ~= -sum(x_Nfremd)  %Test auf Ungleichheit
 
   if power_tminus1 < power_t0 && power(prio1) < x_Nmax
       
       x_N+1;
   end
end

% OPTIMIERER:   (??  selber programmieren oder versuchen das Modell so zu
%                formulieren, dass es ein interner Matlab-Optimierer löst ?)