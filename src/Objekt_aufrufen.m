clc, clear, close all
%% 0. Arbeitstabelle einlesen, workingmatrix WM erstellen, WM in Arbeitstabelle speichern
%Einlesen und Erstellen
WM = readmatrix('arbeitstabelle.xlsx');   % WM = workingmatrix  ,,,  man könnte auch readtable() benutzen ! besser?
[c,d] = size(WM); size(WM);

WM=2*WM; %zum Verändern für Speicher-Test

%Speichern
writematrix(WM,'arbeitstabelle.xlsx','Sheet',1,'Range','A2');   %bei 'A2:BT8' würde nur der Bereich von A2 nach rechts bis BT und nach unten bis Zeile 8 beschrieben werden

%% 1. Knoten-Objekte initialisieren:
M = readmatrix('Knotentabelle.xlsx');
[m,n] = size(M);


Knotenliste = Knoten.empty;


for i=1:m 
%Knoten (k,longK,latK,PK,CK,oPK)
Knotenliste(i) = Knoten (M(i,1),M(i,2),M(i,3),M(i,4),M(i,5),M(i,6));
Knotenliste (i); %zeigt Knoteneigenschaften + Werte
end

Knotenliste(2); %Eigenschaften + Werte von Knoten 2 anzeigen
Knotenliste(2).kosten(); %Kosten von Knoten 2 berechnen

%% 2. Leitungs-Objekte initialisieren:
O = readmatrix('Leitungstabelle.xlsx');
[u,v] = size(O);

for j=1:u
%Leitungen (l,kL1, kL2, PL, pL, CL, cL, oKL, oPL)
j=Leitungen (O(j,1),O(j,2), O(j,3),O(j,4),O(j,5),O(j,6),O(j,7),O(j,8),O(j,9));
end    

%% 3. Kraftwerke_Lasten_Speicher
X = readmatrix('Kraftwerke_Lasten_Speichertabelle.xlsx');
[e,g] = size(X);

for w=1:e
% Kraftwerke_Lasten_Speicher (Number,PN,xNmin,xNmax,xN,RN,CN,cN,oNP,BN,bN,nN,oMK,oNB)
w=Kraftwerke_Lasten_Speicher (X(w,1),X(w,2), X(w,3),X(w,4),X(w,5),X(w,6),X(w,7),X(w,8),X(w,9),X(w,10),X(w,11),X(w,12),X(w,13),X(w,14))
end

