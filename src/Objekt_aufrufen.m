clc, clear, close all
%% 0. Arbeitstabelle einlesen, workingmatrix WM erstellen, WM in Arbeitstabelle speichern
%Einlesen und Erstellen
%WM = readmatrix('../data/arbeitstabelle.xlsx');   % WM = workingmatrix  ,,,  man könnte auch readtable() benutzen ! besser?

%WM=2*WM; %zum Verändern für Speicher-Test

%Speichern
%writematrix(WM,'../data/arbeitstabelle.xlsx','Sheet',1,'Range','A2');   %bei 'A2:BT8' würde nur der Bereich von A2 nach rechts bis BT und nach unten bis Zeile 8 beschrieben werden

%% 1. Knoten-Objekte initialisieren:
Knotenmatrix = readmatrix('../data/Knotentabelle.xlsx');
[m,~] = size(Knotenmatrix); %debug output
global Knotenliste
Knotenliste = Knoten.empty;
for i=1:m 
    Knotenliste(i) = Knoten    (Knotenmatrix(i,1),...% k
                                Knotenmatrix(i,2),...% longK
                                Knotenmatrix(i,3),...% latK
                                Knotenmatrix(i,4),...% PK
                                Knotenmatrix(i,5),...% CK
                                Knotenmatrix(i,6));  % oPK
end
clear i
clear m
clear Knotenmatrix

%% 2. Leitungs-Objekte initialisieren:
Leitungsmatrix = readmatrix('../data/Leitungstabelle.xlsx');
[m,~] = size(Leitungsmatrix);
global Leitungsliste
Leitungsliste = Leitungen.empty;
for i=1:m
    Leitungsliste(i)=Leitungen     (Leitungsmatrix(i,1),...% l
                                    Leitungsmatrix(i,2),...% kL1
                                    Leitungsmatrix(i,3),...% kL2
                                    Leitungsmatrix(i,4),...% PL
                                    Leitungsmatrix(i,5),...% pL
                                    Leitungsmatrix(i,6),...% CL
                                    Leitungsmatrix(i,7),...% cL
                                    Leitungsmatrix(i,8),...% oKL
                                    Leitungsmatrix(i,9));  % oPL
end
clear i
clear m
clear Leitungsmatrix

%% 3. Kraftwerke_Lasten_Speicher
Kraftwerksmatrix = readmatrix('../data/Kraftwerke_Lasten_Speichertabelle.xlsx');
[m,~] = size(Kraftwerksmatrix);
global Kraftwerksliste 
Kraftwerksliste = Kraftwerke_Lasten_Speicher.empty;
for i=1:m  
Kraftwerksliste(i)=Kraftwerke_Lasten_Speicher  (Kraftwerksmatrix(i,1),... % Number
                                                Kraftwerksmatrix(i,2),... % PN
                                                Kraftwerksmatrix(i,3),... % xNmin
                                                Kraftwerksmatrix(i,4),... % xNmax
                                                Kraftwerksmatrix(i,5),... % xN
                                                Kraftwerksmatrix(i,6),... % RN
                                                Kraftwerksmatrix(i,7),... % CN
                                                Kraftwerksmatrix(i,8),... % cN
                                                Kraftwerksmatrix(i,9),... % oNP
                                                Kraftwerksmatrix(i,10),...% BN
                                                Kraftwerksmatrix(i,11),...% bN
                                                Kraftwerksmatrix(i,12),...% nN
                                                Kraftwerksmatrix(i,13),...% oMK
                                                Kraftwerksmatrix(i,14));  % oNB
end
clear i
clear m
clear Kraftwerksmatrix

%% 4. Aufruf und Print
%Anzahl geladener Einheiten:
fprintf('           Daten laden...\n')
fprintf('\n')

[~,b]=size(Knotenliste);
fprintf('%i Knoten geladen\n',b) 
clear b

[~,b]=size(Leitungsliste);
fprintf('%i Leitungen geladen\n',b) 
clear b

[~,b]=size(Kraftwerksliste);
fprintf('%i Kraftwerke geladen\n',b) 
clear b

fprintf('\n')
fprintf('\n')


%  Berechnung Netzdaten:
fprintf('           Berechne Netzdaten...\n')
fprintf('\n')
%Kraftwerke / Lasten / Speicher:
fprintf('Kraftwerke / Lasten / Speicher:\n')
fprintf('\n')
fprintf('Maximal verfügbare Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_verfuegbar_max) 
fprintf('Minimal verfügbare Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_verfuegbar_min)
fprintf('Maximal verfügbare Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_verfuegbar_max)
fprintf('Minimal verfügbare Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_verfuegbar_min)
fprintf('Aktuelle Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_aktuell)
fprintf('Aktuelle Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_aktuell)
fprintf('Aktuelle Netzunterdeckung: %i kW\n',Netzunterdeckung_aktuell)
fprintf('Aktuelle Kraftwerksreserve: %i kW\n',Kraftwerksreserve_aktuell)
fprintf('Nennleistung größte Einheit: %i kW\n',Nennleistung_groesste_Einheit)
fprintf('Nennleistung zweitgrößte Einheit: %i kW\n',Nennleistung_zweitgroesste_Einheit)
fprintf('\n')

%Leitungen:
fprintf('Leitungen:\n')
fprintf('\n')
fprintf('Maximal verfügbare Bemessungsleistung in beide Richtungen : %i kW\n',Bemessungsleistung_verfuegbar_max)
fprintf('Aktuelle Leitungsleistung vorwärts: %i kW\n',Leitungsleistung_vorwaerts_aktuell)
fprintf('Aktuelle Leitungsleistung rückwärts: %i kW\n',Leitungsleistung_rueckwaerts_aktuell)
   %fprintf('Aktuelle Netzunterdeckung: %i kW\n',Netzunterdeckung_aktuell)
fprintf('Aktuelle Leitungsreserve vorwärts: %i kW\n',Leitungsreserve_vorwaerts_aktuell())
fprintf('Aktuelle Leitungsreserve rückwärts: %i kW\n',Leitungsreserve_rueckwaerts_aktuell())
fprintf('Bemessungsleistung größte Leitung: %i kW\n',Bemessungsleistung_groesste_Leitung)
fprintf('Bemessungsleistung zweitgrößte Leitung: %i kW\n',Bemessungsleistung_zweitgroesste_Leitung)
fprintf('\n')
fprintf('\n')


%  Validierung Netzzustand:
fprintf('           Validiere Netzzustand...\n')
fprintf('\n')
%Kraftwerke / Lasten / Speicher:
fprintf('Kraftwerke / Lasten / Speicher:\n')
fprintf('\n')
fprintf('Anzahl Einheiten nicht im Regelbereich: %i \n',Anzahl_Kraftwerks_und_Last_Stoerfaelle())
fprintf('Summe Nennleistung nicht im Regelbereich: %i kW\n',Nennleistung_Kraftwerks_und_Last_Stoerfaelle())
if Einfachredundanz_Kraftwerke_ok()
    fprintf('Einfachredundanz Kraftwerke: OK\n')
else
    fprintf('Einfachredundanz Kraftwerke: NICHT OK\n')  
end
if Zweifachredundanz_Kraftwerke_ok()
    fprintf('Zweifachredundanz Kraftwerke: OK\n')
else
    fprintf('Zweifachredundanz Kraftwerke: NICHT OK\n')  
end
fprintf('\n')
%Leitungen:
fprintf('Leitungen:\n')
fprintf('\n')
fprintf('Anzahl Leitungen nicht im Regelbereich: %i \n',Anzahl_Leitungs_Stoerfaelle())
fprintf('Summe Bemessungsleistung nicht im Regelbereich: %i kW\n',Bemessungsleistung_Leitungs_Stoerfaelle())
if Einfachredundanz_Leitungen_ok()
    fprintf('Einfachredundanz Leitungen: OK\n')
else
    fprintf('Einfachredundanz Leitungen: NICHT OK\n')  
end
if Zweifachredundanz_Leitungen_ok()
    fprintf('Zweifachredundanz Leitungen: OK\n')
else
    fprintf('Zweifachredundanz Leitungen: NICHT OK\n')  
end



%Funktionen:

%Kraftwerke / Lasten / Speicher:
function power = Netzausspeiseleistung_verfuegbar_min()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Nennleistung_min;
        if (p < 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzausspeiseleistung_verfuegbar_max()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Nennleistung_max;
        if (p < 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzeinspeiseleistung_verfuegbar_min()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Nennleistung_min;
        if (p > 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzeinspeiseleistung_verfuegbar_max()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Nennleistung_max;
        if (p > 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzeinspeiseleistung_aktuell()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Leistung_aktuell;
        if (p > 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzausspeiseleistung_aktuell()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Leistung_aktuell;
        if (p < 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
function power = Netzunterdeckung_aktuell()
    power = -(Netzeinspeiseleistung_aktuell() + Netzausspeiseleistung_aktuell());
end
function power = Kraftwerksreserve_aktuell()
    power = Netzeinspeiseleistung_verfuegbar_max() - Netzeinspeiseleistung_aktuell();
end
function s = Anzahl_Kraftwerks_und_Last_Stoerfaelle()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    s = 0;
    for i=1:n
        if Kraftwerksliste(1,i).gestoert()
            s = s + 1;
        end
    end
    clear i
    clear n
end
function p = Nennleistung_Kraftwerks_und_Last_Stoerfaelle()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    p = 0;
    for i=1:n
        if Kraftwerksliste(1,i).gestoert() == true
            p = p + Kraftwerksliste(1,i).P_N;
        end
    end
    clear i
    clear n
end
function p = Nennleistung_groesste_Einheit()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    p = 0;
    for i=1:n
        if Kraftwerksliste(1,i).P_N > p
            p = Kraftwerksliste(1,i).P_N;
        end
    end
    clear i
    clear n
end
function pp = Nennleistung_zweitgroesste_Einheit()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    p = 0;
    pp = 0;
    for i=1:n
        if p < Kraftwerksliste(1,i).P_N
            if p > pp
                pp = p;
            end
            p = Kraftwerksliste(1,i).P_N;
        elseif pp < Kraftwerksliste(1,i).P_N
            pp = Kraftwerksliste(1,i).P_N;
        end
    end
    clear i
    clear n
end
function ok = Einfachredundanz_Kraftwerke_ok
   if Kraftwerksreserve_aktuell() > Nennleistung_groesste_Einheit()
        ok = true;
   else
       ok = false;
   end
end
function ok = Zweifachredundanz_Kraftwerke_ok
   if Kraftwerksreserve_aktuell() > (Nennleistung_groesste_Einheit() + Nennleistung_zweitgroesste_Einheit())
        ok = true;
   else
       ok = false;
   end
end

%Leitungen
function power = Bemessungsleistung_verfuegbar_max()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    power=0;
    for i=1:n
        p = Leitungsliste(1,i).Bemessungsleistung_gesamt;
        if (p > 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n     
end
function power = Leitungsleistung_vorwaerts_aktuell()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    power=0;
    for i=1:n
                                                        %if (Leitungsliste(1,i).Transportleistung > 0)
        p = Leitungsliste(1,i).Transportleistung;
                                                        %end
        if (p > 0)
            power= power + p;
        end
        
    end
    clear p
    clear i
    clear n
end
function power = Leitungsleistung_rueckwaerts_aktuell()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    power=0;
    for i=1:n
        p = Leitungsliste(1,i).Transportleistung;
        if (p < 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
end
 %  !!  Netzunterdeckung  ??
function power = Leitungsreserve_vorwaerts_aktuell()
    power = Bemessungsleistung_verfuegbar_max() - Leitungsleistung_vorwaerts_aktuell();
end
function power = Leitungsreserve_rueckwaerts_aktuell()
    power = Bemessungsleistung_verfuegbar_max() + Leitungsleistung_rueckwaerts_aktuell();
end
function s = Anzahl_Leitungs_Stoerfaelle()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    s = 0;
    for i=1:n
        if Leitungsliste(1,i).gestoert()
            s = s + 1;
        end
    end
    clear i
    clear n
end
function p = Bemessungsleistung_Leitungs_Stoerfaelle()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    p = 0;
    for i=1:n
        if Leitungsliste(1,i).gestoert() == true
            p = p + Leitungsliste(1,i).P_L;
        end
    end
    clear i
    clear n
end
function p = Bemessungsleistung_groesste_Leitung()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    p = 0;
    for i=1:n
        if Leitungsliste(1,i).P_L > p
            p = Leitungsliste(1,i).P_L;
        end
    end
    clear i
    clear n
end
function pp = Bemessungsleistung_zweitgroesste_Leitung()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    p = 0;
    pp = 0;
    for i=1:n
        if p < Leitungsliste(1,i).P_L
            if p > pp
                pp = p;
            end
            p = Leitungsliste(1,i).P_L;
        elseif pp < Leitungsliste(1,i).P_L
            pp = Leitungsliste(1,i).P_L;
        end
    end
    clear i
    clear n
end
function ok = Einfachredundanz_Leitungen_ok
   if (Leitungsreserve_vorwaerts_aktuell() > Bemessungsleistung_groesste_Leitung() && Leitungsreserve_rueckwaerts_aktuell() > Bemessungsleistung_groesste_Leitung())
        ok = true;
   else
       ok = false;
   end
end
function ok = Zweifachredundanz_Leitungen_ok
   if Leitungsreserve_vorwaerts_aktuell() > (Bemessungsleistung_groesste_Leitung() + Bemessungsleistung_zweitgroesste_Leitung()) && Leitungsreserve_rueckwaerts_aktuell() > (Bemessungsleistung_groesste_Leitung() + Bemessungsleistung_zweitgroesste_Leitung())
        ok = true;
   else
       ok = false;
   end
end
