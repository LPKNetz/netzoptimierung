clc, clear, close all 
feature('DefaultCharacterSet','UTF-8');
warning('off','all');
%% 0. Logfile anlegen:
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


%% 1. Programm
Leitungsfluss_berechnen();
Logfile_schreiben();
Netz_anregeln()
Grafik_plotten();
Logfile_schreiben();
zeitschlitze = 96;  % Anzahl zu berechnender Zeitschlitze
dateStart = datetime('now');

    u=length(Leitungsliste);
    maxpowerflow=zeros(u,1);

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
    

    for f=1:u
        Leitung=Leitungsliste(1,f);
        %Leitung.p_L*Leitung.P_L;
        %maxpower;
        if (abs(Leitung.p_L*Leitung.P_L)) > maxpowerflow(f,1)
            maxpowerflow(f,1)=abs(Leitung.p_L*Leitung.P_L);
        end
    end
    
    d = datetime('04-Jul-2019 00:50:00');
    unixtimestart = posixtime(d)-7200; %  7200 abziehen um von +2h GMT zu UTC zu konvertieren
    time = unixtimestart + t*15*60;
    Zeit_setzen(time);
    Netz_anregeln();
    Grafik_plotten();
    Logfile_schreiben();
    clc;
    
    
end

Bemessungsleistung=zeros(u,1);
for i=1:u %Bemessungsleistung aus Originaltabelle / Liste holen
    Leitung=Leitungsliste(1,i);
    Bemessungsleistung(i,1)=Leitung.P_L;
end

maxpowerflow = round(maxpowerflow.*100)/100
delta_mpf_PL = round(((maxpowerflow./Bemessungsleistung)-1).*100)/100
Leitungsauslastung_errechnet = round((maxpowerflow./Bemessungsleistung).*100)/100



clear time;


%% Animation beenden
finishAnimation(animationWriter);

%% Logfile schließen
if Logfile ~= 1
    fclose(Logfile);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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

%Netz berechnen:
function Leitungsfluss_berechnen() %% 4. Netztabellen einlesen, Netzmatrizen erstellen, aktuellen Leitungsfluss berechnen:
    % Funktion ohne result! Trägt Ergebnisse direkt in die Leitungsliste ein.
    % Netzmatrix_Leitungen (=A im Sinne v. Ax=b) erstellen:
    global Knotenliste;
    global Leitungsliste;
    global Kraftwerksliste;
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


            %Netzmatrix_Leitungen(i,j)= 1/Leitungsliste(1,i).Leitungswiderstand();

        end
    end
    clear G_Summe
    clear i
    clear j
    clear k
    clear l
    clear m
    clear R
    clear G

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
    Potentialvektor = linsolve(Netzmatrix_Leitungen,Leistungsvektor);
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
        Leitungstext = sprintf("L%i: %.0f kW\n", i, abs(p));

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

%Netz anregeln:
function Netz_anregeln() %% 7. Netz anregeln:   
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
    
        %1. Netzunterdeckung auf 0 bringen, falls kurz zuvor
        %Kraftwerksausfall
                %Regelreserve nach oben/unten in Abhängigkeit von positiver/negativer NU berechnen:
        NU = Netzunterdeckung_aktuell(); %berechnet aktuelle Netzunterdeckung
        [~,m]=size(Kraftwerksliste);
        Sum_Reserve_KW = 0;
        if NU >= 0  % Kraftwerksverbund muss aufgeregelt werden, wenn die NU größer 0 ist (=Mangel)
            for i=1:m
                Kraftwerk = Kraftwerksliste(1,i);
                Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_auf_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmax für alle KW
            % to do: Reserve muss für Speicher korrigiert werden
            end
        else  % Kraftwerksverbund muss abgeregelt werden, wenn die NU kleiner 0 ist (=Überschuss)
            for i=1:m
                Kraftwerk = Kraftwerksliste(1,i);
                Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_ab_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmin für alle KW
            end
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
        Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen
        %Logfile_schreiben();


        %2. Umgebungswerte und Gradient bilden:
        [~,m]=size(Kraftwerksliste);
        for i=1:m
            Kraftwerk = Kraftwerksliste(1,i);
            x0 = Kraftwerk.x_N;  %x0 - Start-stellwert 
            Kraftwerk.x_N = Kraftwerk.x_N + c; %auf x0 - Vektor die finite Differenz c aufaddieren 
            sum0 = Leitungslastquadratsumme_berechnen(); %Funktion quadriert jede einzelne Leitungslast (die initialen) und summiert alle
            Leitungsfluss_berechnen(); %berechnet aktuellen Lastfluss durch Leitungen
            sum1 = Leitungslastquadratsumme_berechnen(); %quadriert die neu berechneten Leitungslasten und summiert alle
            Kraftwerk.x_N = x0; %setzt x_N auf die ursprünglichen Werte (=Start-stellwert) zurück
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

        %Regelreserve nach oben/unten in Abhängigkeit von positiver/negativer NU berechnen:
        NU = Netzunterdeckung_aktuell(); %berechnet aktuelle Netzunterdeckung
        [~,m]=size(Kraftwerksliste);
        Sum_Reserve_KW = 0;
        if NU >= 0  % Kraftwerksverbund muss aufgeregelt werden, wenn die NU größer 0 ist (=Mangel)
            for i=1:m
                Kraftwerk = Kraftwerksliste(1,i);
                Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_auf_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmax für alle KW
            % to do: Reserve muss für Speicher korrigiert werden
            end
        else  % Kraftwerksverbund muss abgeregelt werden, wenn die NU kleiner 0 ist (=Überschuss)
            for i=1:m
                Kraftwerk = Kraftwerksliste(1,i);
                Sum_Reserve_KW = Sum_Reserve_KW + Kraftwerk.Regelreserve_ab_KW(); %summiert die Differenz vom aktuellen x_N bis zum x_Nmin für alle KW
            end
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
    Kraftwerkstext = sprintf("%s %03i\np=%8.0f kW\nP=%8.0f kW", typ, n, p, P);
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

%Rest:

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