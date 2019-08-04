clc, clear, close all 
feature('DefaultCharacterSet','UTF-8');
%% 0. Logfile anlegen:
Logfile=fopen('../log/Logfile.txt', 'w');
if Logfile == -1
  error('Cannot open log file.');
end
%fprintf(Logfile, '%s: %s\n', datestr(now, 0), test);



% Folgende Zeile auskommentieren um auf die Konsole zu schreiben statt in
% das Logfile:

%Logfile=1; 
        
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
                                    Leitungsmatrix(i,6),...% RL
                                    Leitungsmatrix(i,7),...% CL
                                    Leitungsmatrix(i,8),...% cL
                                    Leitungsmatrix(i,9),...% oKL  
                                    Leitungsmatrix(i,10)); % oPL
end
clear i
clear m
%clear Leitungsmatrix   NEGATIV ! wird in Kapitel 4 noch gebraucht


%% 3. Kraftwerke_Lasten_Speicher
Kraftwerksmatrix = readtable('../data/Kraftwerke_Lasten_Speichertabelle.xlsx');
[m,~] = size(Kraftwerksmatrix);
global Kraftwerksliste 
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
clear i
clear m
clear Kraftwerksmatrix


%% 4. Netztabellen einlesen, Netzmatrizen erstellen, aktuellen Leitungsfluss berechnen:
% Netzmatrix_Leitungen (=A im Sinne v. Ax=b) erstellen:

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
        Kraftwerk = Kraftwerksliste(1,i);
        if Kraftwerk.Netzverknuepfungspunkt() == j 
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


        %fprintf('Leitung %i: %4d kW\n', permute(cat(3,B,PL), [3 2 1]));


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


%% 5. Aufruf und Print
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

%Kraftwerksliste(1,10).Zeit_setzen(1562224805)   % TEST


%% 6. Time Sequencer



%% 7. Grafik erstellen

% Check version
if verLessThan('matlab','8.6')
    error('digraph is available in R2015b or newer.')
end

% Create a directed graph object using the digraph function
figure('units','normalized','position',[0,0,1,1]);
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
    fprintf("Leitung %i: von %i nach %i: %6.0f kW\n", i, s, e, abs(p));
    
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
%% Logfile schlie�en
if Logfile ~= 1
    fclose(Logfile);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






%% Funktionen:

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
    
    % Anschlusslinie zum Netzverkn�pfungspunkt
    plot([x (x-x_offset) (x-x_offset)], [y (y-y_offset) (y-2*y_offset)],...
        '',...
        'Color', LineColor, 'LineStyle', LineStyle, 'LineWidth', 0.5 + abs(p_norm));
    
    % Box f�r Bargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
        '',...
        'Color', [.6 .6 .6], 'LineStyle', LineStyle, 'LineWidth', 12);
    % Stellgr��enbargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + abs(p_norm)*1.0)],...
        '',...
        'Color', LineColor, 'LineStyle', LineStyle, 'LineWidth', 8);
    
    if (typ == "Speicher")
        % Box f�r Batteriesymbol
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', LineStyle, 'LineWidth', 24);
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', LineStyle, 'LineWidth', 12);
        % F�llstand Batterie
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9*Kraftwerk.b_N)],...
            '',...
            'Color', [.2 .2 1], 'LineStyle', LineStyle, 'LineWidth', 20);
    end
    
    % Text des Kraftwerks
    Kraftwerkstext = sprintf("%s %03i\np=%8.0f kW\nP=%8.0f kW", typ, n, p, P);
    text(x - x_offset ,y - 2*y_offset, Kraftwerkstext,...
        'FontSize',10, 'Rotation', 90,...
        'HorizontalAlignment', 'Right',...
        'VerticalAlignment', 'bottom',...
        'FontName', 'FixedWidth');
end

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
function power = Leitungen_Bemessungsleistung_verfuegbar_max()
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

