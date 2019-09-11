clc, clear, close all 
feature('DefaultCharacterSet','UTF-8');
warning('on','all');

%% Alte Grafikausgaben loeschen
delete('../log/Grafik/*');

%% Logfile anlegen:
global Logfile;
Logfile=fopen('../log/Logfile.txt', 'w');
if Logfile == -1
  error('Cannot open log file.');
end
%fprintf(Logfile, '%s: %s\n', datestr(now, 0), test);

% Folgende Zeile auskommentieren um auf die Konsole zu schreiben statt in
% das Logfile:

%Logfile=1; 
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global figureNum;
figureNum = 0;

global animationWriter;
animationWriter = initAnimation('../log/Grafik/animation.avi', 2);

global Knotenliste;
Knotenliste = Knoten_initialisieren();

global Leitungsliste;
Leitungsliste = Leitungen_initialisieren();

global Kraftwerksliste;
Kraftwerksliste = Kraftwerke_initialisieren();

global Tageskosten
global counter
global Anzahl_overflow
global Leistung_total_overflow
%% Programm
Netzmatrix_Leitungen_invers_berechnen();

% Folgendes aktivieren um NUR 1 Tag zu rechnen:

 Lastgang_rechnen();
 Anzahl_Leitungen = Anzahl_overflow
 Leistung_total_overflow 
 PoPL_ratio = Leistung_total_overflow / Netzeinspeiseleistung_aktuell() %
 PoPL_ratio_3 = Leistung_total_overflow / (Netzeinspeiseleistung_aktuell() - Netzausspeiseleistung_aktuell()) %

%bei tic einen STOPP-Point machen
%% Optimierer

%INPUT:


tic
k=length(Knotenliste);
n = 1;   % Maximale Anzahl an Speichern im Netz
f = k;  % Anzahl an Knoten im Netz, s.o. k=length(Knotenliste)


start = zeros(1, f);    % Startwert für jede FOR Schleife 
limit = [f+1,f+1,f+1];    % Endwert für jede FOR Schleife 
g=f+3;
Kombinationsmatrix(1,g)=0;
tmp=0;


index = start; 
ready = false; 
while ~ready 
   Knotenliste = Knoten_initialisieren();
   Leitungsliste = Leitungen_initialisieren();
   Kraftwerksliste = Kraftwerke_initialisieren();
   
   % Speicher an alten Knoten löschen und an aktuellen Knoten verschieben
   if index(1,1) == 0
       Kraftwerksliste(1,11).K = 4;
   else
   Kraftwerksliste(1,11).K = index(1,1);
   %Kraftwerksliste(1,12).K = index(1,2);
   %Kraftwerksliste(1,13).K = index(1,3);
   end
   
   % Aktuelle Kombination in Matrix schreiben
   tmp = tmp + 1;
   Kombinationsmatrix(tmp,4:g)=index;
   
   % Berechnen
   Lastgang_rechnen();
   
   % Kosten der aktuellen Kombination in Matrix abspeichern
   Kombinationsmatrix(tmp,1)= Tageskosten;
   
   % Leitungsinformationen der aktuellen Kombination in Matrix abspeichern
   Kombinationsmatrix(tmp,2) = Anzahl_overflow; % Anzahl Leitungen nicht im Arbeitsbereich
   Kombinationsmatrix(tmp,3) = Leistung_total_overflow; % Summe Bemessungsleistung nicht im Arbeitsbereich
   
   f = n; 
   while 1  % Quelle: https://www.gomatlab.de/variable-zahl-verschachtelter-for-schleifen-t14746.html
      index(f) = index(f) + 1; 
      if index(f) < limit(f) 
         break;   % k-ter Index um 1 erhöht 
      else 
         index(f) = start(f); 
         f = f - 1; 
         if f == 0  % All iterations are ready 
            ready = true;  % Stop outer WHILE loop 
            break;    % Break inner WHILE loop 
         end
      end 
   end 
end 

fprintf('Wert des Eintrages = Platzierungsort (Knotennummer):\n')
fprintf('\n')
fprintf('#overflow Poverflow T.kosten  S1    S2    S3    S4    S5    S6    S7    S8    S9 \n')

Kombinationsmatrix

%Die billigste Kombination aus der Kombinationsmatrix finden:
    [n,m]=size(Kombinationsmatrix);
    p = 10e30;  % p = Extrem große Zahl
    Kombination = zeros(1,g); 
    for i=1:n
        if Kombinationsmatrix(i,1) < p
            p = Kombinationsmatrix(i,1); 
            Kombination(1,:)= Kombinationsmatrix(i,:); % billigste Kombination aus Kombinationsmatrix extrahieren
            
        end
    end
fprintf('Kostengünstigste Speicher-Kombination:\n')
Kombination

pp=0;
Standort = zeros(k,2);
for i=4:m % Anzahl Speicher
    if Kombination(1,i) > 0
        pp = pp + 1;
        Standort(pp,1) = i - 3; % 1. Spalte = Speichernummer
        Standort(pp,2) = Kombination(1,i); % 2. Spalte = Knotennummer
    end
end  
Anzahl_Speicher = pp
Anzahl_Leitungen = Kombination(1,2)
Leistung_total_overflow = Kombination(1,3)

PoPL_ratio = Leistung_total_overflow / Netzeinspeiseleistung_aktuell()
PoPL_ratio_3 = Leistung_total_overflow / (Netzeinspeiseleistung_aktuell() - Netzausspeiseleistung_aktuell()) %



SL_ratio = Anzahl_Speicher / Anzahl_Leitungen;
fprintf('Kostengünstigstes Verhältnis aus Speichern und ausgebauten Leitungen:  %.2f \n' , SL_ratio )
    



    clear i
    clear n


toc
%% Animation beenden
finishAnimation(animationWriter);

%% Logfile schließen
if Logfile ~= 1
    fclose(Logfile);
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Funktionen:

%Initialisieren:
function result = Knoten_initialisieren()  %% 1. Knoten-Objekte initialisieren:
    Knotenmatrix = readmatrix('../data/Knotentabelle.xlsx');
    [m,~] = size(Knotenmatrix); %debug output
    %global Knotenliste
    Knotenliste = Knoten.empty;
    for i=1:m
        Knotenliste(i) = Knoten    (Knotenmatrix(i,1),...% k
            Knotenmatrix(i,2),...% longK
            Knotenmatrix(i,3),...% latK
            Knotenmatrix(i,4),...% PK
            Knotenmatrix(i,5),...% CK
            Knotenmatrix(i,6));  % oPK
    end
    result = Knotenliste;
    clear i
    clear m
    clear Knotenmatrix
end
function result = Leitungen_initialisieren() %% 2. Leitungs-Objekte initialisieren:
    Leitungsmatrix = readmatrix('../data/Leitungstabelle.xlsx');
    [m,~] = size(Leitungsmatrix);


    Leitungsliste = Leitungen.empty;

    for i=1:m
        Leitungsliste(i)=Leitungen     (Leitungsmatrix(i,1),...% l
                                        Leitungsmatrix(i,2),...% kL1
                                        Leitungsmatrix(i,3),...% kL2
                                        Leitungsmatrix(i,4),...% PL
                                        Leitungsmatrix(i,5),...% pL
                                        Leitungsmatrix(i,6),...% RL
                                        Leitungsmatrix(i,7),...% CL
                                        Leitungsmatrix(i,8),...% cL
                                        Leitungsmatrix(i,9),...% oKL  
                                        Leitungsmatrix(i,10)); % oPL
    end
    result = Leitungsliste;
    clear i
    clear m
    clear Leitungsmatrix 
end
function result = Kraftwerke_initialisieren() %% 3. Kraftwerke_Lasten_Speicher
    Kraftwerksmatrix = readtable('../data/Kraftwerke_Lasten_Speichertabelle.xlsx');
    [m,~] = size(Kraftwerksmatrix);
    Kraftwerksliste = Kraftwerke_Lasten_Speicher.empty;
    for i=1:m  
    Kraftwerksliste(i)=Kraftwerke_Lasten_Speicher  (Kraftwerksmatrix(i,1),... % Number
                                                    Kraftwerksmatrix(i,2),... % K    
                                                    Kraftwerksmatrix(i,3),... % PN
                                                    Kraftwerksmatrix(i,4),... % xNmin
                                                    Kraftwerksmatrix(i,5),... % xNmax
                                                    Kraftwerksmatrix(i,6),... % xN
                                                    Kraftwerksmatrix(i,7),... % RN
                                                    Kraftwerksmatrix(i,8),... % CN
                                                    Kraftwerksmatrix(i,9),... % cN
                                                    Kraftwerksmatrix(i,10),... % oNP
                                                    Kraftwerksmatrix(i,11),...% BN
                                                    Kraftwerksmatrix(i,12),...% bN
                                                    Kraftwerksmatrix(i,13),...% nN
                                                    Kraftwerksmatrix(i,14),...% oMK
                                                    Kraftwerksmatrix(i,15),...% oNB
                                                    Kraftwerksmatrix(i,16));  % TQ
    end
    result = Kraftwerksliste;
    clear i
    clear m
    clear Kraftwerksmatrix
end

%Lastgang rechnen (Netzregler)
function Lastgang_rechnen()
    %global Knotenliste;
    global Leitungsliste;
    %global Kraftwerksliste;
    global Tageskosten
    global counter
    global Anzahl_overflow
    global Leistung_total_overflow
    
    counter = 0;
    Anzahl_overflow = 0;
    Leistung_total_overflow = 0;
    
    
    Leitungsfluss_berechnen();
    Logfile_schreiben();
    if (Netz_anregeln() == false)
        fprintf("\nNetz in Grundkonfiguration nicht regelbar!\n");
        return
    end
    Grafik_plotten();
    Logfile_schreiben();
    zeitschlitze = 96;  % Anzahl zu berechnender Zeitschlitze
    dateStart = datetime('now');

    u=length(Leitungsliste);
    maxpowerflow=zeros(u,1);
    Tageskosten = 0;

    for t=1:zeitschlitze % 1 Tag berechnen mit 96 Zeitschlitzen a 15 min
        dateNow = datetime('now');
        laufzeit = dateNow - dateStart;
        gesamtzeit = laufzeit * zeitschlitze / t;
        restzeit = gesamtzeit - laufzeit;
        laufzeitstring = datestr(laufzeit, 'HH:MM:SS');
        restzeitstring = datestr(restzeit, 'HH:MM:SS');
        gesamtzeitstring = datestr(gesamtzeit, 'HH:MM:SS');
        fprintf("Berechne Schritt %i von %i. Laufzeit: %s Restzeit: %s Gesamtzeit: %s",...
            t, zeitschlitze, laufzeitstring, restzeitstring, gesamtzeitstring);
        clear laufzeit
        clear gesamtzeit
        clear restzeit
        clear restzeitstring


        d = datetime('04-Jul-2019 00:50:00');
        unixtimestart = posixtime(d)-7200; %  7200 abziehen um von +2h GMT zu UTC zu konvertieren
        time = unixtimestart + t*15*60;
        Zeit_setzen(time);
        if (Netz_anregeln() == false)
            fprintf("\nNetz im laufenden Betrieb nicht regelbar!\n");
            break;
        end
        
        Tageskosten = Tageskosten + Netzkosten_berechnen();
        Schrittkosten = Netzkosten_berechnen()
        
        Grafik_plotten();
        Logfile_schreiben();
        %clc;
        Tageskosten;
        
        for f=1:u  % Konstruktion von maxpowerflow 
            Leitung=Leitungsliste(1,f);
            if (abs(Leitung.p_L*Leitung.P_L)) > maxpowerflow(f,1)
                maxpowerflow(f,1)=abs(Leitung.p_L*Leitung.P_L);
            end
 

        end
        
        
        
        
        
    end
    
    

    
    %       Analyse und Testing:
    
    
    Bemessungsleistung=zeros(u,1);
    for i=1:u %Counter berechnen und Bemessungsleistung aus Originaltabelle / Liste holen
        Leitung=Leitungsliste(1,i);
        Bemessungsleistung(i,1) = Leitung.P_L;
            % um Gesamtanzahl aller in den 96 Zeitschlitzen überlasteten Leitungen herauszufinden:
            if (abs(maxpowerflow)) > Leitung.P_L
                counter = counter + 1;
            end
    end
    maxpowerflow %
    counter; % ist eigentlich auch die Anzahl von overflow-Leitungen
    delta_mpf_PL = (maxpowerflow./Bemessungsleistung)-1 %
    Leitungsauslastung_errechnet = maxpowerflow./Bemessungsleistung %
    Leistungsdifferenz = maxpowerflow - Bemessungsleistung %
    
    for i=1:u
        if Leitungsauslastung_errechnet(i,1) > 1
    Anzahl_overflow = Anzahl_overflow + 1; % Anzahl Leitungen nicht im Arbeitsbereich
    Leistung_total_overflow = Leistung_total_overflow + Leistungsdifferenz(i,1);  % Summe Bemessungsleistung nicht im Arbeitsbereich
        end
    end
    
    Anzahl_overflow %
    Leistung_total_overflow %
    
    clear time;
    % to do: mehr clear ...
end

function Netzmatrix_Leitungen_invers_berechnen()
    global Knotenliste;
    global Leitungsliste;
    global Netzmatrix_Leitungen_invers;
    k=length(Knotenliste);
    l=length(Leitungsliste);
    for i=1:k   %Netzmatrix_Leitungen erstellen
        for j=1:k
            if i == j
                G_Summe=0;
                for m=1:l
                    Leitung=Leitungsliste(1,m);
                    R=Leitung.Leitungswiderstand();
                    G=1/R;
                    if Leitung.Startknoten() == i || Leitung.Endknoten() == i
                        G_Summe=G_Summe+G;
                    end
                end
                Netzmatrix_Leitungen(i,j)=G_Summe;

            else
                G_Summe=0;
                for m=1:l
                    Leitung=Leitungsliste(1,m);
                    R=Leitung.Leitungswiderstand();
                    G=1/R;
                    if (Leitung.Startknoten() == i && Leitung.Endknoten() == j)||...
                            (Leitung.Startknoten() == j && Leitung.Endknoten() == i)
                        G_Summe=G_Summe+G;
                    end
                end
                Netzmatrix_Leitungen(i,j)=-G_Summe;  
            end
        end
    end
    
    % Knoten 1 als Referenzpunkt wählen, daher Zeile 1 und Spalte 1 löschen
    Netzmatrix_Leitungen(1,:)=[];
    Netzmatrix_Leitungen(:,1)=[];
    Netzmatrix_Leitungen_invers = inv(Netzmatrix_Leitungen);
    
    clear G_Summe
    clear i
    clear j
    clear k
    clear l
    clear m
    clear R
    clear G
    clear Netzmatrix_Leitungen
end

%Netz berechnen:
function Leitungsfluss_berechnen() %% 4. Netztabellen einlesen, Netzmatrizen erstellen, aktuellen Leitungsfluss berechnen:
    % Funktion ohne result! Trägt Ergebnisse direkt in die Leitungsliste ein.
    % Netzmatrix_Leitungen (=A im Sinne v. Ax=b) erstellen:
    global Knotenliste;
    global Leitungsliste;
    global Kraftwerksliste;
    global Netzmatrix_Leitungen_invers;

    % Leistungsvektor erstellen:
    k=length(Knotenliste);
    n=length(Kraftwerksliste);
    for i=1:k  
        P_Summe=0;
        for j=1:n
            Kraftwerk = Kraftwerksliste(1,j);
            if Kraftwerk.Netzverknuepfungspunkt() == i 
                P_Summe=P_Summe+Kraftwerk.Leistung_aktuell();
            end
        end
        Leistungsvektor(i,1)=P_Summe;
    end
    clear i
    clear k
    clear j
    clear n
    clear P_Summe
    clear Kraftwerk

    %Potentialvektor erstellen:
    % Leistungseintrag an Referenzpunkt (Knoten 1) löschen
    Leistungsvektor(1,:)=[];
    Potentialvektor = Netzmatrix_Leitungen_invers*Leistungsvektor;
    % Potentialvektoreintrag an Referenzpunkt (Knoten 1) hinzufügen und auf 0 setzen
    Potentialvektor = [zeros(1,1); Potentialvektor]; 

    clear Netzmatrix_Leitungen
    clear Leistungsvektor

    %Lastfluss auf Leitungen berechnen:
    l=length(Leitungsliste);
    for i=1:l
        Leitung=Leitungsliste(1,i);
        R=Leitung.Leitungswiderstand();
        s=Leitung.Startknoten();
        e=Leitung.Endknoten();
        Startpotential=Potentialvektor(s,1);
        Endpotential=Potentialvektor(e,1);
        Potentialdifferenz=Startpotential-Endpotential;
        p=Potentialdifferenz/R;
        Leitung.Aktuelle_Leistung_setzen_in_kW(p);
    %fprintf(Logfile, 'Leistung ueber Leitung %i:  %8.0f kW\n',i,p)
    end
    clear M
    clear b
    clear z
    clear s
    clear e
    clear R
    clear p
    clear Leitung
    clear l
    clear c
    clear Leitungsmatrix
    clear i
    clear Startpotential
    clear Endpotential
    clear Potentialvektor
    clear Potentialdifferenz
end

%Logfile schreiben:
function Logfile_schreiben() %% 5. Logfile schreiben
    global Logfile;
    global Knotenliste;
    global Leitungsliste;
    global Kraftwerksliste;
    %Anzahl geladener Einheiten:
    fprintf(Logfile, '           Daten laden...\n');
    fprintf(Logfile, '\n');

    [~,b]=size(Knotenliste);
    fprintf(Logfile, '%i Knoten geladen\n',b); 
    clear b

    [~,b]=size(Leitungsliste);
    fprintf(Logfile, '%i Leitungen geladen\n',b); 
    clear b

    [~,b]=size(Kraftwerksliste);
    fprintf(Logfile, '%i Kraftwerke geladen\n',b); 
    clear b

    fprintf(Logfile, '\n');
    fprintf(Logfile, '\n');



    %  Berechnung Netzdaten:

    fprintf(Logfile, '           Berechne Netzdaten...\n');
    fprintf(Logfile, '\n');
    %Kraftwerke / Lasten / Speicher:
    fprintf(Logfile, 'Kraftwerke / Lasten / Speicher:\n');
    fprintf(Logfile, '\n');
    fprintf(Logfile, 'Maximal verfuegbare Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_verfuegbar_max); 
    fprintf(Logfile, 'Minimal verfuegbare Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_verfuegbar_min);
    fprintf(Logfile, 'Maximal verfuegbare Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_verfuegbar_max);
    fprintf(Logfile, 'Minimal verfuegbare Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_verfuegbar_min);
    fprintf(Logfile, 'Aktuelle Netzeinspeiseleistung: %i kW\n',Netzeinspeiseleistung_aktuell);
    fprintf(Logfile, 'Aktuelle Netzausspeiseleistung: %i kW\n',Netzausspeiseleistung_aktuell);
    fprintf(Logfile, 'Aktuelle Netzunterdeckung: %i kW\n',Netzunterdeckung_aktuell);
    fprintf(Logfile, 'Aktuelle Kraftwerksreserve: %i kW\n',Kraftwerksreserve_aktuell);
    fprintf(Logfile, 'Nennleistung groesste Einheit: %i kW\n',Nennleistung_groesste_Einheit);
    fprintf(Logfile, 'Nennleistung zweitgroesste Einheit: %i kW\n',Nennleistung_zweitgroesste_Einheit);
    fprintf(Logfile, '\n');
    %Leitungen:
    fprintf(Logfile, 'Leitungen:\n');
    fprintf(Logfile, '\n');
    l=length(Leitungsliste);
    for i=1:l
        Leitung=Leitungsliste(1,i);
        p=Leitung.Transportleistung();
    fprintf(Logfile, 'Leistung ueber Leitung %i:  %8.0f kW\n',i,p);
    end
    fprintf(Logfile, '\n');
    clear p
    clear l
    clear i
    clear Leitung
    fprintf(Logfile, 'Maximal verfuegbare Bemessungsleistung in beide Richtungen : %i kW\n',Leitungen_Bemessungsleistung_verfuegbar_max);
    fprintf(Logfile, 'Aktuelle Leitungsleistung vorwaerts: %i kW\n',Leitungsleistung_vorwaerts_aktuell);
    fprintf(Logfile, 'Aktuelle Leitungsleistung rueckwaerts: %i kW\n',Leitungsleistung_rueckwaerts_aktuell);
       %?? fprintf(Logfile, 'Aktuelle Netzunterdeckung: %i kW\n',Netzunterdeckung_aktuell);
    %fprintf(Logfile, 'Aktuelle Leitungsreserve vorwaerts: %i kW\n',Leitungsreserve_vorwaerts_aktuell());
    %fprintf(Logfile, 'Aktuelle Leitungsreserve rueckwaerts: %i kW\n',Leitungsreserve_rueckwaerts_aktuell());
    fprintf(Logfile, 'Bemessungsleistung groesste Leitung: %i kW\n',Bemessungsleistung_groesste_Leitung);
    fprintf(Logfile, 'Bemessungsleistung zweitgroesste Leitung: %i kW\n',Bemessungsleistung_zweitgroesste_Leitung);
    fprintf(Logfile, '\n');
    fprintf(Logfile, '\n');



    %  Validierung Netzzustand:

    fprintf(Logfile, '           Validiere Netzzustand...\n');
    fprintf(Logfile, '\n');
    %Kraftwerke / Lasten / Speicher:
    fprintf(Logfile, 'Kraftwerke / Lasten / Speicher:\n');
    fprintf(Logfile, '\n');
    fprintf(Logfile, 'Anzahl Einheiten nicht im Regelbereich: %i \n',Anzahl_Kraftwerks_und_Last_Stoerfaelle());
    fprintf(Logfile, 'Summe Nennleistung nicht im Regelbereich: %i kW\n',Nennleistung_Kraftwerks_und_Last_Stoerfaelle());
    if Einfachredundanz_Kraftwerke_ok()
        fprintf(Logfile, 'Einfachredundanz Kraftwerke: OK\n');
    else
        fprintf(Logfile, 'Einfachredundanz Kraftwerke: NICHT OK\n');  
    end
    if Zweifachredundanz_Kraftwerke_ok()
        fprintf(Logfile, 'Zweifachredundanz Kraftwerke: OK\n');
    else
        fprintf(Logfile, 'Zweifachredundanz Kraftwerke: NICHT OK\n');  
    end
    fprintf(Logfile, '\n');
    %Leitungen:
    fprintf(Logfile, 'Leitungen:\n');
    fprintf(Logfile, '\n');
    fprintf(Logfile, 'Anzahl Leitungen nicht im Arbeitsbereich: %i \n',Anzahl_Leitungs_Stoerfaelle());
    fprintf(Logfile, 'Summe Bemessungsleistung nicht im Arbeitsbereich: %i kW\n',Bemessungsleistung_Leitungs_Stoerfaelle());
    fprintf(Logfile, '\n');
    fprintf(Logfile, '\n');


    fname = '../data/weather/wind/Bremerhaven_Juli_2019.json';
    val = jsondecode(fileread(fname));
    val.observations(1).wspd;
    time=val.observations(3).valid_time_gmt;

    datetime(time, 'convertfrom','posixtime');

    %Kraftwerksliste(1,11).Zeit_setzen(1.562265900000000e+09)   % TEST
    clear fname
    clear time
    clear val
end

%Grafik plotten:
function Grafik_plotten() %% 6. Grafik erstellen
    global Knotenliste;
    global Leitungsliste;
    global Kraftwerksliste;
    global figureNum;
    global animationWriter;
    figureNum = figureNum + 1;
    % Check version
    if verLessThan('matlab','8.6')
        error('digraph is available in R2015b or newer.')
    end

    % Create a directed graph object using the digraph function  
    fig = figure('Visible', 'off', 'units','normalized','position',[0,0,1,1]);
    hold on;
    axis ([30 60 20 30]);
    pbaspect([1 1 1])

    [~,k]=size(Knotenliste);
    G = digraph();
    G = G.addnode(k);

    [~,l]=size(Leitungsliste);
    [~,m]=size(Kraftwerksliste);
    c=cell([l 1]);
    title('Netzkarte');
    xlabel('Laengengrad [deg]') 
    ylabel('Breitengrad [deg]') 
    for i=1:l
        Leitung=Leitungsliste(1,i);
        p = Leitung.Transportleistung();
        p_norm = Leitung.p_L;

        if (p >= 0)
            s = Leitung.Startknoten();
            e = Leitung.Endknoten();
        else
            s = Leitung.Endknoten();
            e = Leitung.Startknoten();
        end


        c{i,1}=num2str(abs(p),'%6.0f kW');
        G = addedge(G,s,e,round(abs(p)));
        %fprintf("Leitung %i: von %i nach %i: %6.0f kW\n", i, s, e, abs(p));

        Startknoten = Knotenliste(1,s);
        Endknoten = Knotenliste(1,e);

        LineColor = [.1 .2 1];
        LineStyle = '-';
        if (Leitung.gestoert())
            LineColor = [1 .4 .4];
            LineStyle = ':';
        end

        plot([Startknoten.Long_K Endknoten.Long_K], [Startknoten.Lat_K Endknoten.Lat_K],...
            '',...
            'Color', LineColor, 'LineStyle', LineStyle, 'LineWidth', 0.5 + abs(p_norm));
            
        if (abs(p) > 10000)
            Istleistungstext = sprintf("%8.0f MW", abs(p) / 1000);
        else
            Istleistungstext = sprintf("%.0f kW", abs(p));
        end
        Leitungstext = sprintf("L%i: %s\n", i, Istleistungstext);

        Textwinkel = (atan(3*(Endknoten.Lat_K-Startknoten.Lat_K)/(Endknoten.Long_K-Startknoten.Long_K)))*360/2/3.1415;
        text((Startknoten.Long_K + Endknoten.Long_K) / 2,...
            (Startknoten.Lat_K + Endknoten.Lat_K) / 2, Leitungstext,...
            'FontSize',10, 'Rotation', Textwinkel,...
            'HorizontalAlignment', 'Center');
    end

    for i=1:k
        Knoten=Knotenliste(1,i);
        Long = Knoten.Long_K;
        Lat = Knoten.Lat_K;
        plot(Long, Lat,...
            '.', 'MarkerSize',20,'MarkerEdgeColor',[.2 .7 .6]);
        Knotentext = sprintf("K%i", i);
        text(Long + .5, Lat, Knotentext, 'FontSize',15, 'Color', [.2 .7 .6]);
    end

    for i=1:m
        Kraftwerk=Kraftwerksliste(1,i);
        k = Kraftwerk.K;
        Knoten=Knotenliste(1,k);
        x=Knoten.Long_K;
        y=Knoten.Lat_K;
        plotKraftwerk(x, y, Kraftwerk);
    end

    hold off;

    %G.Edges
    %plot(G,'EdgeLabel',c)
    %plot(G, 'EdgeLabel', G.Edges.Weight)

    % Visualize the graph
    %figure
    %plot(G,'EdgeLabel',G.Edges.Weight,'layout','layered')
    % Remove axes ticks
    %set(gca,'XTick',[],'YTick',[])
    % Add title
    %title('Leitungsfluss')
    frame = getframe(gcf);
    addFrame(animationWriter, frame);
    filename = sprintf('../log/Grafik/fig_%06i.png', figureNum);
    print(fig,'-dpng', filename);
    close all
    clear fig
    clear G
    clear p
    clear p_norm
    clear s
    clear e
    clear Long
    clear Lat
    clear Knotentext
    clear Knoten
    clear c
    clear l
    clear m
    clear k
    clear Kraftwerk
    clear x
    clear y
end

%Netzunterdeckung auf 0 regeln:
function result = Netzunterdeckung_regeln()
    global Kraftwerksliste;
    %Regelreserve nach oben/unten in Abhängigkeit von positiver/negativer NU berechnen:

    NU = Netzunterdeckung_aktuell(); %berechnet aktuelle Netzunterdeckung
    [~,m]=size(Kraftwerksliste);
    Sum_Reserve_KW = 0;
    if NU >= 0  % Kraftwerksverbund muss aufgeregelt werden, wenn die NU größer 0 ist (=Mangel)
        for i=1:m
            Kraftwerk = Kraftwerksliste(1,i);
            Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_auf_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmax für alle KW
        end
    else  % Kraftwerksverbund muss abgeregelt werden, wenn die NU kleiner 0 ist (=Überschuss)
        for i=1:m
            Kraftwerk = Kraftwerksliste(1,i);
            Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_ab_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmin für alle KW
        end
    end

    if (Sum_Reserve_KW < 1)
        fprintf("\nKeine Regelreserve mehr vorhanden!\n");
        result = false;
        return
    end

    Anteil_NU = NU/Sum_Reserve_KW; %berechnet das Verhältnis aus Netzunterdeckung und Gesamtreserve

    %AUF - / AB - Regelung der Stellwerte:
    [~,m]=size(Kraftwerksliste);
    for i=1:m
        Kraftwerk = Kraftwerksliste(1,i);
        if NU >= 0  % Kraftwerksverbund muss aufgeregelt werden
            RR = Kraftwerk.Regelreserve_auf();
        else  % Kraftwerksverbund muss abgeregelt werden
            RR = Kraftwerk.Regelreserve_ab();
        end
        Kraftwerk.Sollwert_setzen(Kraftwerk.x_N + RR * Anteil_NU); %Anteil auf Regelreserve aufschalten und um das den Stellwert verändern (für alle KW)
    end
    NU = Netzunterdeckung_aktuell();
    if (abs(NU) > 0.1)
        result = false;
    end
    result = true;
end

%Netz anregeln:
function result = Netz_anregeln() %% 7. Netz anregeln:   
    global Logfile;
    global Knotenliste;
    global Leitungsliste;
    global Kraftwerksliste;
    %1. Startwerte festlegen 
    %2. Umgebungswerte bilden  (Verfahren der finiten Differenzen)
    %3. Gradient bilden
    %4. Gradient entgegengesetzt "entlanggehen" mit Schrittweite (wird bestimmt durch Gauß-Newton) und dort neue Umgebungswerte bilden
    %   repeat zu 3.
    %5. STOPP bei Abbruchbedingung (=wenn Veränderung zum vorherigen Ergebnis
    %   0,0001 (z.B.) nicht mehr unterschreitet 

    
    
    
    %1. GROSSER TEIL: STELLWERTE UM DELTA VERÄNDERN

    %Einstellungen:
    format long
    a_k = 0.00001;      %Definieren der Schrittweite
    c = 0.0000001;      %Definieren der Finiten Differenz für die Gradientbildung

    for loop=1:20

        %1. pL0 - Start-vektor aus allen pLs der Leitungen machen:
%        [~,l]=size(Leitungsliste);
%        pL0=zeros(l,1);
%        for i=1:l 
%            Leitung=Leitungsliste(1,i);
%            pL0(i,1)=Leitung.p_L;
%        end
    
        %Speicher oder Kraftwerke entlasten, die nicht mehr ausreichend
        %liefern können
        [~,m]=size(Kraftwerksliste);
        for i=1:m
                Kraftwerk = Kraftwerksliste(1,i);
                Kraftwerk.Sollwert_setzen(Kraftwerk.x_N);
        end

        %1. Netzunterdeckung auf 0 bringen, falls kurz zuvor
        %Kraftwerksausfall

        if Netzunterdeckung_regeln() == false
            fprintf("\nUnterdeckungsausgleich vor Regelung nicht moeglich!\n");            
        end
        Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen
        %Logfile_schreiben();


        %2. Umgebungswerte und Gradient bilden:
        [~,m]=size(Kraftwerksliste);
        reset_xN = zeros(m,1);
        for i=1:m
            Kraftwerk = Kraftwerksliste(1,i);
            % FEHLER : x0 = Kraftwerk.x_N;  %x0 - Start-stellwert
            for z=1:m
                Kraftwerk = Kraftwerksliste(1,z);
                rest_xN(z,1) = Kraftwerk.x_N;
            end
            Kraftwerk.x_N = Kraftwerk.x_N + c; %auf x0 - Vektor die finite Differenz c aufaddieren
            Netzunterdeckung_regeln();
            sum0 = Leitungslastquadratsumme_berechnen(); %Funktion quadriert jede einzelne Leitungslast (die initialen) und summiert alle
            Leitungsfluss_berechnen(); %berechnet aktuellen Lastfluss durch Leitungen
            sum1 = Leitungslastquadratsumme_berechnen(); %quadriert die neu berechneten Leitungslasten und summiert alle
            % FEHLER : Kraftwerk.x_N = x0; %setzt x_N auf die ursprünglichen Werte (=Start-stellwert) zurück
            % FEHLER : Netzunterdeckung_regeln();
            for z=1:m
                Kraftwerk = Kraftwerksliste(1,z);
                Kraftwerk.x_N = rest_xN(z,1);
            end
            
            Gradient(i,1)= (sum1-sum0)/c ; % Differenz aus Fehlerquadratsumme vor und nach der Leistungsflussberechnung durch die finite Differenz
        end
        %Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen

        %3. Delta bilden:
        dx_N = -Gradient * a_k; %Delta-Vektor aus Gradient in entgegengesetzte Richtung um die Schrittweite a_k entlang gehen

        %4. Stellwert der regelbare KW um Delta-Vektoreintrag verstellen: 
        for i=1:m %Addiert auf alle regelbaren KW den jeweiligen Eintrag aus dem Delta-Vektor:
            Kraftwerk = Kraftwerksliste(1,i);
            if Kraftwerk.R_N == 2  %Alle KW durchgehen und wenn eins, ein konv. regelbares ist, dann jeweiligen Eintrag aus Delta-Vektor auf den Stellwert addieren
                Kraftwerk.Sollwert_setzen(Kraftwerk.x_N + dx_N(i,1)); %Funktion setzt x_N und limitet noch, falls das gegebene x_N größer oder kleiner ist als das zulässige x_Nmax oder x_Nmin
            end
        end
        %Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen

        %Zur Überprüfung:
        %Logfile_schreiben();
        %Grafik_plotten();

        %5. Netzunterdeckung nach Lastausgleich wieder auf 0 bringen

        if Netzunterdeckung_regeln() == false
            fprintf("\nUnterdeckungsausgleich vor Regelung nicht moeglich!\n");            
        end
        Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen
        %Logfile_schreiben();
    end
    clear sum0
    clear sum1
    clear x0
    clear pL0
    clear dx_N
    clear Kraftwerk
    clear Sum_Reserve_KW
    clear Anteil_NU
    clear RR
    clear m
    clear l
    clear Gradient
    clear NU
    clear a_k
    clear c
    
    result = true;
end

%Time Sequencer:
function Zeit_setzen(time)
    global Kraftwerksliste;
    m=length(Kraftwerksliste);
    for i=1:m
        Kraftwerk = Kraftwerksliste(1,i);
        Kraftwerk.Zeit_setzen(time);
    end
    
    clear m
    clear i
    clear Kraftwerk
end


%Grafik:
function plotKraftwerk(x, y, Kraftwerk)
    n = Kraftwerk.N;
    P = Kraftwerk.P_N;
    p_norm = Kraftwerk.x_N;
    Bunkergroesse = Kraftwerk.B_N;
    p = Kraftwerk.Leistung_aktuell();
    LineColor = [.4 .2 .10];
    LineStyle = '-';
    if (Kraftwerk.gestoert())
        LineColor = [1 .4 .4];
        LineStyle = ':';
    elseif (p>0)
        LineColor = [.24 .90 .0];
    elseif (abs(p_norm) < 0.001)
        LineColor = [.6 .6 .6];
    end
    
    typ = "";
    if (Bunkergroesse > 0.001) && (Kraftwerk.x_Nmin < -0.0001)  % Speicher
        typ = "Speicher";
    elseif (Kraftwerk.x_Nmin < -0.0001)  % Last
        typ = "Last";
    else    % Konventionelles Kraftwerk
        typ = "Kraftwerk";
    end
    
    y_offset = 0.3;
    
    switch (typ)
        case "Speicher"
            x_offset = 5*1.5;
        case "Last"
            x_offset = 2*1.5;
        case "Kraftwerk"
            x_offset = 0;
        otherwise
            x_offset = 0;
    end
    
    % Anschlusslinie zum Netzverknüpfungspunkt
    plot([x (x-x_offset) (x-x_offset)], [y (y-y_offset) (y-2*y_offset)],...
        '',...
        'Color', LineColor, 'LineStyle', LineStyle, 'LineWidth', 0.5 + abs(p_norm));
    
    % Box für Bargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
        '',...
        'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 12);
    % Stellgrößenbargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + abs(p_norm)*1.0)],...
        '',...
        'Color', LineColor, 'LineStyle', '-', 'LineWidth', 8);
    
    if (typ == "Speicher")
        % Box für Batteriesymbol
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 24);
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 12);
        % Füllstand Batterie
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9*Kraftwerk.b_N)],...
            '',...
            'Color', [.2 .2 1], 'LineStyle', '-', 'LineWidth', 20);
    end
    
    % Text des Kraftwerks
    if (P > 10000)
        Nennleistungstext = sprintf("%8.0f MW", P / 1000);
    else
        Nennleistungstext = sprintf("%8.0f kW", P);
    end
    
    if (abs(p) > 10000)
        Istleistungstext = sprintf("%8.0f MW", p / 1000);
    else
        Istleistungstext = sprintf("%8.0f kW", p);
    end
    
    Kraftwerkstext = sprintf("%s %03i\np=%s\nP=%s", typ, n, Istleistungstext, Nennleistungstext);
    text(x - x_offset ,y - 2*y_offset, Kraftwerkstext,...
        'FontSize',10, 'Rotation', 90,...
        'HorizontalAlignment', 'Right',...
        'VerticalAlignment', 'bottom',...
        'FontName', 'FixedWidth');
    
    clear n
    clear P
    clear p_norm
    clear Bunkergroesse
    clear p
    clear LineColor
    clear LineStyle
    clear typ
    clear y_offset
    clear x_offset
    clear Kraftwerkstext
end
function result = initAnimation(filename, framerate)
    [~,~,ext] = fileparts(filename);
    format = '';
    switch (ext)
        case '.mp4'
            format = 'MPEG-4';
        case '.avi'
            format = 'Motion JPEG AVI';
        case '.mj2'
            format = 'Motion JPEG 2000';
    end
    writer = VideoWriter(filename, format);
    writer.FrameRate = framerate;
    open(writer);
    result = writer;
    clear format
end
function addFrame(writer, image)
    writeVideo(writer, image);
end
function finishAnimation(writer)
    close(writer);
end


%Kraftwerke / Lasten / Speicher:
function power = Netzausspeiseleistung_verfuegbar_min()
    global Kraftwerksliste
    [~,n]=size(Kraftwerksliste);
    power=0;
    for i=1:n
        p = Kraftwerksliste(1,i).Nennleistung_min();
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
        p = Kraftwerksliste(1,i).Nennleistung_max();
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
        p = Kraftwerksliste(1,i).Nennleistung_min();
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
        p = Kraftwerksliste(1,i).Nennleistung_max();
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
        p = Kraftwerksliste(1,i).Leistung_aktuell();
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
        p = Kraftwerksliste(1,i).Leistung_aktuell();
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
    clear p
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
function power = Regelreserve_auf_KW()
    global Kraftwerksliste;
    [~,m]=size(Kraftwerksliste);
    Sum_Reserve_KW = 0;
    for i=1:m
        Kraftwerk = Kraftwerksliste(1,i);
        Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_auf_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmax für alle KW
    end
    power = Sum_Reserve_KW;
end
function power = Regelreserve_ab_KW()
    global Kraftwerksliste;
    [~,m]=size(Kraftwerksliste);
    Sum_Reserve_KW = 0;
    for i=1:m
        Kraftwerk = Kraftwerksliste(1,i);
        Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_ab_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmin für alle KW
    end
    power = Sum_Reserve_KW;
end

%Leitungen
function power = Leitungen_Bemessungsleistung_verfuegbar_max()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    power=0;
    for i=1:n
        p = Leitungsliste(1,i).Bemessungsleistung_gesamt();
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
        p = Leitungsliste(1,i).Transportleistung();
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
        p = Leitungsliste(1,i).Transportleistung();
        if (p < 0)
            power= power + p;
        end
        clear p
    end
    clear i
    clear n
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
    clear p
end

%Kosten
function cost = Netzkosten_berechnen()
    global Leitungsliste
    [~,n]=size(Leitungsliste);
    ck=0;
    cv=0;
    for i=1:n
        Leitung = Leitungsliste(1,i);
        ck = ck + Leitung.Fixkosten();
        cv = cv + Leitung.VariableKosten();
    end
    CL = ck + cv;
    global Kraftwerksliste
    [~,m]=size(Kraftwerksliste);
    ck=0;
    cv=0;
    for i=1:m
        Kraftwerk = Kraftwerksliste(1,i);
        ck = ck + Kraftwerk.Fixkosten();
        cv = cv + Kraftwerk.VariableKosten();
    end
    CN = ck + cv;
    global Knotenliste
    [~,u]=size(Knotenliste);
    ck=0;
    cv=0;
    for i=1:u
        Knoten = Knotenliste(1,i);
        ck = ck + Knoten.Fixkosten();
        cv = cv + Knoten.VariableKosten();
    end
    CK = ck + cv;
    cost = CL + CN + CK;
end

% Funktionen für den Netzregler:
function result = Leitungslastquadratsumme_berechnen() %sum_p_L berechnen (= Summe der quadrierten pL-Werte)
    global Leitungsliste;
    [~,l]=size(Leitungsliste);
    sum=0;
    for i=1:l 
        Leitung=Leitungsliste(1,i);
        sum=sum+(Leitung.p_L^2); 
        clear Leitung
    end
    result = sum;
    clear sum
end