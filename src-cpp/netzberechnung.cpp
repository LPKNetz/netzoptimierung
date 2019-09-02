#include "netzberechnung.h"
#include <QFile>
#include <QtMath>

Netzberechnung::Netzberechnung(QWidget *parent) : QWidget(parent)
{

}

void Netzberechnung::setLogger(Logger *logger)
{
    mLogger = logger;
    connect(this, SIGNAL(signalLog(QString, QString)), logger, SLOT(slot_Log(QString, QString)));
}

void Netzberechnung::Netz_initialisieren()
{
    Knoten_initialisieren("../data/Knotentabelle.csv");
    Leitungen_initialisieren("../data/Leitungstabelle.csv");
    Kraftwerke_initialisieren("../data/Kraftwerke_Lasten_Speichertabelle.csv");
    emit signalLog("Info", "Netz ist initialisiert");
}

void Netzberechnung::Knoten_initialisieren(QString filename)
{
    mKnotenliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;
        QString lineStr = QString::fromUtf8(line).trimmed();

        Knoten* knoten = new Knoten(this);
        if (knoten->parseCSVline(lineStr))
        {
            knoten->setLogger(mLogger);
            mKnotenliste.append(knoten);
        }
        else
            delete knoten;
    }

    emit signalLog("Info", QString().sprintf("%i Knoten geladen", mKnotenliste.length()));

    file.close();
}

void Netzberechnung::Leitungen_initialisieren(QString filename)
{
    mLeitungliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;

        QString lineStr = QString::fromUtf8(line).trimmed();

        Leitung* leitung = new Leitung(this);
        if (leitung->parseCSVline(lineStr))
        {
            leitung->setLogger(mLogger);
            mLeitungliste.append(leitung);
        }
        else
            delete leitung;
    }

    emit signalLog("Info", QString().sprintf("%i Leitungen geladen", mLeitungliste.length()));

    file.close();
}

void Netzberechnung::Kraftwerke_initialisieren(QString filename)
{
    mKraftwerksliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;
        QString lineStr = QString::fromUtf8(line).trimmed();

        Kraftwerk_Last_Speicher* kraftwerk = new Kraftwerk_Last_Speicher(this);
        if (kraftwerk->parseCSVline(lineStr))
        {
            kraftwerk->setLogger(mLogger);
            mKraftwerksliste.append(kraftwerk);
        }
        else
            delete kraftwerk;
    }

    emit signalLog("Info", QString().sprintf("%i Kraftwerke geladen", mKraftwerksliste.length()));

    file.close();
}

void Netzberechnung::Lastgang_rechnen()
{
    // To do: Später Inverse nur einmal zentral berechnen
    Netzmatrix_Leitungen_invers_berechnen();

    Leitungsfluss_berechnen();
    Logfile_schreiben();
    if (Netz_anregeln() == false)
    {
        emit signalLog("Error", "Netz in Grundkonfiguration nicht regelbar!");
        return;
    }

    update();   // Grafik plotten

    Logfile_schreiben();
    int zeitschlitze = 96;  // Anzahl zu berechnender Zeitschlitze
    QDateTime dateStart = QDateTime::currentDateTime();

    double Tageskosten = 0.0;

    // 1 Tag berechnen mit 96 Zeitschlitzen a 15 min
    for (int t=1; t <=zeitschlitze; t++)
    {
        QDateTime dateNow = QDateTime::currentDateTime();
        qint64 laufzeit = dateStart.secsTo(dateNow);
        qint64 gesamtzeit = laufzeit * zeitschlitze / t;
        qint64 restzeit = gesamtzeit - laufzeit;
//        QString laufzeitstring = QDateTime::fromSecsSinceEpoch(laufzeit).toString("hh:mm:ss");
//        QString restzeitstring = QDateTime::fromSecsSinceEpoch(restzeit).toString("hh:mm:ss");
//        QString gesamtzeitstring = QDateTime::fromSecsSinceEpoch(gesamtzeit).toString("hh:mm:ss");

        QString laufzeitstring = QString().sprintf("%i s", int(laufzeit));
        QString restzeitstring = QString().sprintf("%i s", int(restzeit));
        QString gesamtzeitstring = QString().sprintf("%i s", int(gesamtzeit));

        emit signalLog("Time", QString().sprintf("Berechne Schritt %i von %i. Laufzeit: %s Restzeit: %s Gesamtzeit: %s",
                                                 t, zeitschlitze, laufzeitstring.toUtf8().data(),
                                                 restzeitstring.toUtf8().data(),
                                                 gesamtzeitstring.toUtf8().data()));

        QDateTime d = QDateTime::fromString("2019-07-04T00:50:00+02:00", Qt::ISODate);
        Zeit_setzen(d.addSecs(t*15*60));

        if (!Netz_anregeln())
        {
            emit signalLog("Error", "Netz im laufenden Betrieb nicht regelbar!");
            break;
        }
        Tageskosten += Netzkosten_berechnen();

        update();   // Grafik plotten
        Logfile_schreiben();
    }
}

void Netzberechnung::Netzmatrix_Leitungen_invers_berechnen()
{
    int k = mKnotenliste.length();
    double G_Summe = 0.0;
    Matrix Netzmatrix_Leitungen(k, k);

    for (int i=1; i <= k; i++)
    {
        for (int j=1; j <= k; j++)
        {
            if (i == j)
            {
                G_Summe = 0.0;
                foreach (Leitung* lt, mLeitungliste) {
                    double G = 1.0 / lt->Leitungswiderstand();
                    if (int(lt->Startknoten()) == i || (int(lt->Endknoten()) == i))
                        G_Summe += G;
                }
                Netzmatrix_Leitungen.fill(i-1, j-1, G_Summe);
            }
            else
            {
                G_Summe = 0.0;
                foreach (Leitung* lt, mLeitungliste) {
                    double G = 1.0 / lt->Leitungswiderstand();
                    if (((int(lt->Startknoten()) == i) && (int(lt->Endknoten()) == j)) ||
                            ((int(lt->Startknoten()) == j) && (int(lt->Endknoten()) == i)))
                        G_Summe += G;
                }
                Netzmatrix_Leitungen.fill(i-1, j-1, -G_Summe);
            }
        }
    }

    emit signalLog("Netzmatrix_Leitungen", Netzmatrix_Leitungen.toString());

    Matrix vec(3,3);

    vec.fill(0, 0, 3.0);
    vec.fill(0, 1, -2.0);
    vec.fill(0, 2, 0.0);
    vec.fill(1, 0, -2.0);
    vec.fill(1, 1, 9.0);
    vec.fill(1, 2, -4.0);
    vec.fill(2, 0, 0.0);
    vec.fill(2, 1, -4.0);
    vec.fill(2, 2, 9.0);

    Matrix tmp = vec.invert();
    emit signalLog("tmp", tmp.toString());

    mNetzmatrix_Leitungen_invers = Netzmatrix_Leitungen.invert();
}

void Netzberechnung::Leitungsfluss_berechnen()
{
    // Leistungsvektor erstellen:
    //k=length(Knotenliste);
    //n=length(Kraftwerksliste);

    Matrix Leistungsvektor(mKnotenliste.length(), 1);

    foreach (Knoten* kt, mKnotenliste)
    {
        double P_Summe = 0.0;
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            if (kw->Netzverknuepfungspunkt() == kt->K)
                P_Summe += kw->Leistung_aktuell();
        }
        Leistungsvektor.fill(int(kt->K -1), 0, P_Summe);
    }

    emit signalLog("Leistungsvektor", Leistungsvektor.toString());
    emit signalLog("mNetzmatrix_Leitungen_invers", mNetzmatrix_Leitungen_invers.toString());

    // Potentialvektor erstellen:
    // Potentialvektor = linsolve(Netzmatrix_Leitungen,Leistungsvektor);
    Matrix Potentialvektor(mNetzmatrix_Leitungen_invers*Leistungsvektor);

    emit signalLog("Potentialvektor", Potentialvektor.toString());

    // Lastfluss auf Leitungen berechnen:
    foreach (Leitung* lt, mLeitungliste)
    {
        double R = lt->Leitungswiderstand();
        quint32 s = lt->Startknoten();
        quint32 e = lt->Endknoten();
        double Startpotential = Potentialvektor.at(int(s -1), 0);
        double Endpotential = Potentialvektor.at(int(e -1), 0);
        double Potentialdifferenz = Startpotential - Endpotential;
        double p = Potentialdifferenz / R;
        lt->Aktuelle_Leistung_setzen_in_kW(p);
        //emit signalLog("Logfile", QString().sprintf("Leistung ueber Leitung %i:  %8.0lf kW\n", lt->L, p));
    }
}

bool Netzberechnung::Netzunterdeckung_regeln()
{
    double NU = Netzunterdeckung_aktuell();
    double Sum_Reserve_KW = 0.0;

    if (NU >= 1.0)  // Kraftwerksverbund muss aufgeregelt werden, wenn die NU größer 0 ist (=Mangel)
    {
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            // summiert die Differenz vom aktuellen x_N bis zum x_Nmax für alle KW
            Sum_Reserve_KW += kw->Regelreserve_auf_kW();
        }
    }
    else
    {
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            // summiert die Differenz vom aktuellen x_N bis zum x_Nmin für alle KW
            Sum_Reserve_KW += kw->Regelreserve_ab_kW();
        }
    }

    if (Sum_Reserve_KW < 1.0)
    {
        emit signalLog("Error", "Keine Regelreserve mehr vorhanden!");
        return false;
    }

    double Anteil_NU = NU / Sum_Reserve_KW; //berechnet das Verhältnis aus Netzunterdeckung und Gesamtreserve

    // AUF - / AB - Regelung der Stellwerte:
    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        double RR;
        if (NU >= 0.0)  // Kraftwerksverbund muss aufgeregelt werden
            RR = kw->Regelreserve_auf();
        else            // Kraftwerksverbund muss abgeregelt werden
            RR = kw->Regelreserve_ab();
        kw->SollwertSetzen(kw->x_N + (RR * Anteil_NU)); // Anteil auf Regelreserve aufschalten und um das den Stellwert verändern (für alle KW)
    }

    NU = Netzunterdeckung_aktuell();
    if (qAbs(NU) > 0.1)
        return false;

    return true;
}

bool Netzberechnung::Netz_anregeln()
{
    // 1. Startwerte festlegen
    // 2. Umgebungswerte bilden  (Verfahren der finiten Differenzen)
    // 3. Gradient bilden
    // 4. Gradient entgegengesetzt "entlanggehen" mit Schrittweite (wird bestimmt durch Gauß-Newton) und dort neue Umgebungswerte bilden
    //    repeat zu 3.
    // 5. STOPP bei Abbruchbedingung (=wenn Veränderung zum vorherigen Ergebnis
    //    0,0001 (z.B.) nicht mehr unterschreitet

    // 1. GROSSER TEIL: STELLWERTE UM DELTA VERÄNDERN

    // Einstellungen:
    double a_k = 0.00001;      // Definieren der Schrittweite
    double c = 0.0000001;      // Definieren der Finiten Differenz für die Gradientbildung

    for (int loop=1; loop <= 20; loop++)
    {
        // 1. pL0 - Start-vektor aus allen pLs der Leitungen machen:

        // Speicher oder Kraftwerke entlasten, die nicht mehr ausreichend liefern können
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            kw->SollwertSetzen(kw->x_N);
        }

        // 1. Netzunterdeckung auf 0 bringen, falls kurz zuvor
        // Kraftwerksausfall
        // Regelreserve nach oben/unten in Abhängigkeit von positiver/negativer NU berechnen:

        if (!Netzunterdeckung_regeln())
        {
            emit signalLog("Error", "Unterdeckungsausgleich vor Regelung nicht moeglich!");
            return false;
        }

        Leitungsfluss_berechnen();  // abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen


        //Logfile_schreiben();

        // 2. Umgebungswerte und Gradient bilden:
        Matrix Gradient(mKraftwerksliste.length(), 1);
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            double x0 = kw->x_N;    // x0 - Start-stellwert
            kw->x_N += c;           // auf x0 die finite Differenz c aufaddieren
            double sum0 = Leitungslastquadratsumme_berechnen(); // Funktion quadriert jede einzelne Leitungslast (die initialen) und summiert alle
            Leitungsfluss_berechnen();  // berechnet aktuellen Lastfluss durch Leitungen
            double sum1 = Leitungslastquadratsumme_berechnen(); // quadriert die neu berechneten Leitungslasten und summiert alle
            kw->x_N = x0;           // setzt x_N auf die ursprünglichen Werte (=Start-stellwert) zurück
            Gradient.fill(int(kw->N - 1), 0, ((sum1 - sum0)/c));     // Differenz aus Fehlerquadratsumme vor und nach der Leistungsflussberechnung durch die finite Differenz
        }
        // Leitungsfluss_berechnen(); %abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen

        // 3. Delta bilden und
        // 4. Stellwert der regelbare KW um Delta-Vektoreintrag verstellen:
        foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
        {
            // 3. Delta bilden
            if (kw->R_N == Fremdregelung)
            {
                double dx_N = -Gradient.at(int(kw->N -1), 0) * a_k; // Delta-Vektor aus Gradient in entgegengesetzte Richtung um die Schrittweite a_k entlang gehen
                kw->SollwertSetzen(kw->x_N + dx_N);
            }
        }
        // Leitungsfluss_berechnen(); // abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen

        // Zur Überprüfung:
        // Logfile_schreiben();
        // Grafik_plotten();

        // 5. Netzunterdeckung nach Lastausgleich wieder auf 0 bringen
        if (!Netzunterdeckung_regeln())
        {
            emit signalLog("Error", "Unterdeckungsausgleich nach Regelung nicht moeglich!");
            return false;
        }

        Leitungsfluss_berechnen(); //abschließend wieder aktuellen Lastfluss nach Veränderung der x_N berechnen
        // Logfile_schreiben();
    }

    return true;
}

void Netzberechnung::Logfile_schreiben()
{
    QString text;

    text += QString().sprintf("           Daten laden...\n");
    text += QString().sprintf("\n");

    text += QString().sprintf("%i Knoten geladen\n",mKnotenliste.length());
    text += QString().sprintf("%i Leitungen geladen\n",mLeitungliste.length());
    text += QString().sprintf("%i Kraftwerke geladen\n",mKraftwerksliste.length());

    text += QString().sprintf("\n");
    text += QString().sprintf("\n");

    //  Berechnung Netzdaten:
    text += QString().sprintf("           Berechne Netzdaten...\n");
    text += QString().sprintf("\n");
    // Kraftwerke / Lasten / Speicher:
    text += QString().sprintf("Kraftwerke / Lasten / Speicher:\n");
    text += QString().sprintf("\n");
    text += QString().sprintf("Maximal verfuegbare Netzeinspeiseleistung: %lf kW\n", Netzeinspeiseleistung_verfuegbar_max());
    text += QString().sprintf("Minimal verfuegbare Netzeinspeiseleistung: %lf kW\n", Netzeinspeiseleistung_verfuegbar_min());
    text += QString().sprintf("Maximal verfuegbare Netzausspeiseleistung: %lf kW\n",Netzausspeiseleistung_verfuegbar_max());
    text += QString().sprintf("Minimal verfuegbare Netzausspeiseleistung: %lf kW\n",Netzausspeiseleistung_verfuegbar_min());
    text += QString().sprintf("Aktuelle Netzeinspeiseleistung: %lf kW\n",Netzeinspeiseleistung_aktuell());
    text += QString().sprintf("Aktuelle Netzausspeiseleistung: %lf kW\n",Netzausspeiseleistung_aktuell());
    text += QString().sprintf("Aktuelle Netzunterdeckung: %lf kW\n",Netzunterdeckung_aktuell());
    text += QString().sprintf("Aktuelle Kraftwerksreserve: %lf kW\n",Kraftwerksreserve_aktuell());
    text += QString().sprintf("Nennleistung groesste Einheit: %lf kW\n",Nennleistung_groesste_Einheit());
    text += QString().sprintf("Nennleistung zweitgroesste Einheit: %lf kW\n",Nennleistung_zweitgroesste_Einheit());
    text += QString().sprintf("\n");
    // Leitungen:
    text += QString().sprintf("Leitungen:\n");
    text += QString().sprintf("\n");

    foreach (Leitung* lt, mLeitungliste)
    {
        text += QString().sprintf("Leistung ueber Leitung %i:  %8.0f kW\n", lt->L, lt->Transportleistung());
    }
    text += QString().sprintf("\n");


//    text += QString().sprintf("Maximal verfuegbare Bemessungsleistung in beide Richtungen : %lf kW\n",Leitungen_Bemessungsleistung_verfuegbar_max());
//    text += QString().sprintf("Aktuelle Leitungsleistung vorwaerts: %lf kW\n",Leitungsleistung_vorwaerts_aktuell());
//    text += QString().sprintf("Aktuelle Leitungsleistung rueckwaerts: %lf kW\n",Leitungsleistung_rueckwaerts_aktuell());
    text += QString().sprintf("Bemessungsleistung groesste Leitung: %lf kW\n",Bemessungsleistung_groesste_Leitung());
    text += QString().sprintf("Bemessungsleistung zweitgroesste Leitung: %lf kW\n",Bemessungsleistung_zweitgroesste_Leitung());
    text += QString().sprintf("\n");
    text += QString().sprintf("\n");

    // Validierung Netzzustand:
    text += QString().sprintf("           Validiere Netzzustand...\n");
    text += QString().sprintf("\n");

    // Kraftwerke / Lasten / Speicher:
    text += QString().sprintf("Kraftwerke / Lasten / Speicher:\n");
    text += QString().sprintf("\n");
    text += QString().sprintf("Anzahl Einheiten nicht im Regelbereich: %i \n", Anzahl_Kraftwerks_und_Last_Stoerfaelle());
    text += QString().sprintf("Summe Nennleistung nicht im Regelbereich: %lf kW\n", Nennleistung_Kraftwerks_und_Last_Stoerfaelle());
    if (Einfachredundanz_Kraftwerke_ok())
        text += QString().sprintf("Einfachredundanz Kraftwerke: OK\n");
    else
        text += QString().sprintf("Einfachredundanz Kraftwerke: NICHT OK\n");

    if (Zweifachredundanz_Kraftwerke_ok())
        text += QString().sprintf("Zweifachredundanz Kraftwerke: OK\n");
    else
        text += QString().sprintf("Zweifachredundanz Kraftwerke: NICHT OK\n");

    text += QString().sprintf("\n");

    // Leitungen:
    text += QString().sprintf("Leitungen:\n");
    text += QString().sprintf("\n");
    text += QString().sprintf("Anzahl Leitungen nicht im Arbeitsbereich: %i \n",Anzahl_Leitungs_Stoerfaelle());
    text += QString().sprintf("Summe Bemessungsleistung nicht im Arbeitsbereich: %lf kW\n",Bemessungsleistung_Leitungs_Stoerfaelle());
    text += QString().sprintf("\n");
    text += QString().sprintf("\n");

    emit signalLog("Logfile", text);
}

void Netzberechnung::Zeit_setzen(QDateTime time)
{
    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        kw->Zeit_setzen(time);
    }
}

void Netzberechnung::initAnimation(QString filename, int framerate)
{
    Q_UNUSED(filename)
    Q_UNUSED(framerate)
}

void Netzberechnung::addFrame(QImage image)
{
    Q_UNUSED(image)
}

void Netzberechnung::finishAnimation()
{

}

double Netzberechnung::Netzausspeiseleistung_verfuegbar_min()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Nennleistung_min() < 0.0)
            power += kw->Nennleistung_min();
    }

    return power;
}

double Netzberechnung::Netzausspeiseleistung_verfuegbar_max()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Nennleistung_max() < 0.0)
            power += kw->Nennleistung_max();
    }

    return power;
}

double Netzberechnung::Netzeinspeiseleistung_verfuegbar_min()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Nennleistung_min() > 0.0)
            power += kw->Nennleistung_min();
    }

    return power;
}

double Netzberechnung::Netzeinspeiseleistung_verfuegbar_max()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Nennleistung_max() > 0.0)
            power += kw->Nennleistung_max();
    }

    return power;
}

double Netzberechnung::Netzeinspeiseleistung_aktuell()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Leistung_aktuell() > 0.0)
            power += kw->Leistung_aktuell();
    }

    return power;
}

double Netzberechnung::Netzausspeiseleistung_aktuell()
{
    double power = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->Leistung_aktuell() < 0.0)
            power += kw->Leistung_aktuell();
    }

    return power;
}

double Netzberechnung::Netzunterdeckung_aktuell()
{
    return (-Netzeinspeiseleistung_aktuell() - Netzausspeiseleistung_aktuell());
}

double Netzberechnung::Kraftwerksreserve_aktuell()
{
    return (Netzeinspeiseleistung_verfuegbar_max() - Netzeinspeiseleistung_aktuell());
}

int Netzberechnung::Anzahl_Kraftwerks_und_Last_Stoerfaelle()
{
    int s = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->gestoert())
            s++;
    }

    return s;
}

double Netzberechnung::Nennleistung_Kraftwerks_und_Last_Stoerfaelle()
{
    double p = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->gestoert())
            p += kw->P_N;
    }

    return p;
}

double Netzberechnung::Nennleistung_groesste_Einheit()
{
    double p = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (kw->P_N > p)
            p = kw->P_N;
    }

    return p;
}

double Netzberechnung::Nennleistung_zweitgroesste_Einheit()
{
    double p = 0.0;
    double pp = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        if (p < kw->P_N)
        {
            if (p > pp)
                pp = 0;
            p = kw->P_N;
        }
        else if (pp < kw->P_N)
            pp = kw->P_N;
    }

    return pp;
}

bool Netzberechnung::Einfachredundanz_Kraftwerke_ok()
{
    if (Kraftwerksreserve_aktuell() > Nennleistung_groesste_Einheit())
        return true;
    else
        return false;
}

bool Netzberechnung::Zweifachredundanz_Kraftwerke_ok()
{
    if (Kraftwerksreserve_aktuell() > (Nennleistung_groesste_Einheit() + Nennleistung_zweitgroesste_Einheit()))
        return true;
    else
        return false;
}

double Netzberechnung::Regelreserve_auf_kW()
{
    double sum_Reserve_kW = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        sum_Reserve_kW += kw->Regelreserve_auf_kW();
    }

    return sum_Reserve_kW;
}

double Netzberechnung::Regelreserve_ab_kW()
{
    double sum_Reserve_kW = 0.0;

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        sum_Reserve_kW += kw->Regelreserve_ab_kW();
    }

    return sum_Reserve_kW;
}

int Netzberechnung::Anzahl_Leitungs_Stoerfaelle()
{
    int s = 0.0;

    foreach (Leitung* lt, mLeitungliste)
    {
        if (lt->gestoert())
            s++;
    }

    return s;
}

double Netzberechnung::Bemessungsleistung_Leitungs_Stoerfaelle()
{
    double p = 0.0;

    foreach (Leitung* lt, mLeitungliste)
    {
        if (lt->gestoert())
            p += lt->P_L;
    }

    return p;
}

double Netzberechnung::Bemessungsleistung_groesste_Leitung()
{
    double p = 0.0;

    foreach (Leitung* lt, mLeitungliste)
    {
        if (lt->P_L > p)
            p = lt->P_L;
    }

    return p;
}

double Netzberechnung::Bemessungsleistung_zweitgroesste_Leitung()
{
    double p = 0.0;
    double pp = 0.0;

    foreach (Leitung* lt, mLeitungliste)
    {
        if (p < lt->P_L)
        {
            if (p > pp)
            {
                pp = p;

            }
            p = lt->P_L;
        }
        else if (pp < lt->P_L)
            pp = lt->P_L;
    }

    return pp;
}

double Netzberechnung::Netzkosten_berechnen()
{
    double cost = 0.0;

    foreach (Leitung* lt, mLeitungliste)
    {
        cost += lt->Fixkosten() + lt->Variablekosten();
    }

    foreach (Kraftwerk_Last_Speicher* kw, mKraftwerksliste)
    {
        cost += kw->Fixkosten() + kw->Variablekosten();
    }

    foreach (Knoten* kt, mKnotenliste)
    {
        cost += kt->Fixkosten();
    }

    return cost;
}

double Netzberechnung::Leitungslastquadratsumme_berechnen()
{
    double sum = 0.0;

    foreach(Leitung* lt, mLeitungliste)
    {
        sum += qPow(lt->p_L, 2.0);
    }

    return sum;
}

QList<Kraftwerk_Last_Speicher *> Netzberechnung::sucheKraftwerkeAnKnoten(quint32 KnotenNr)
{
    QList<Kraftwerk_Last_Speicher *> list;

    foreach(Kraftwerk_Last_Speicher* kraftwerk, mKraftwerksliste)
    {
        if (kraftwerk->K == KnotenNr)
            list.append(kraftwerk);
    }

    return list;
}

Knoten *Netzberechnung::sucheKnotenIndex(quint32 knotenNr)
{
    foreach(Knoten* knoten, mKnotenliste)
    {
        if (knoten->K == knotenNr)
            return knoten;
    }

    return nullptr;
}

Leitung *Netzberechnung::sucheLeitungIndex(quint32 LeitungNr)
{
    foreach(Leitung* leitung, mLeitungliste)
    {
        if(leitung->L == LeitungNr)
            return leitung;
    }

    return nullptr;
}

Kraftwerk_Last_Speicher *Netzberechnung::sucheKraftwerkIndex(quint32 KraftwerkNr)
{
    foreach(Kraftwerk_Last_Speicher* kraftwerk, mKraftwerksliste)
    {
        if(kraftwerk->N == KraftwerkNr)
            return  kraftwerk;
    }

    return nullptr;
}

void Netzberechnung::mouseMoveEvent(QMouseEvent *event)
{
    Q_UNUSED(event)
}

void Netzberechnung::mousePressEvent(QMouseEvent *event)
{
    Q_UNUSED(event)
}

void Netzberechnung::mouseReleaseEvent(QMouseEvent *event)
{
    Q_UNUSED(event)
}

void Netzberechnung::wheelEvent(QWheelEvent *event)
{
    Q_UNUSED(event)
}

void Netzberechnung::keyPressEvent(QKeyEvent *event)
{
    Q_UNUSED(event)
}

void Netzberechnung::paintEvent(QPaintEvent *event)
{
//    QPainter painter;
//    painter.begin(this);
//    painter.setRenderHint(QPainter::Antialiasing);

//    painter.setBrush(QBrush(Qt::yellow));
//    painter.setPen(Qt::black);
//    painter.drawRect(10, 10, 50, 50);

//    painter.end();

    paintNetz(this);

    event->accept();
}

void Netzberechnung::paintNetz(QPaintDevice *paintDevice)
{
    QPainter painter;
    painter.begin(paintDevice);
    painter.setRenderHint(QPainter::Antialiasing);

    painter.translate(-400.0, 0.0);
    painter.scale(1.0, 1.0);

    foreach(Kraftwerk_Last_Speicher *kraftwerk, mKraftwerksliste)
    {
        paintKraftwerk(&painter, kraftwerk);
    }

    foreach(Leitung *leitung, mLeitungliste)
    {
        paintLeitung(&painter, leitung);
    }

    foreach(Knoten *knoten, mKnotenliste)
    {
        paintKnoten(&painter, knoten);
    }

    painter.end();
}

void Netzberechnung::paintKraftwerk(QPainter *painter, Kraftwerk_Last_Speicher *kraftwerk)
{
    QColor lineColor = QColor(int(255*0.4), int(255*0.2), int(255*0.1));
    if (kraftwerk->gestoert())
    {
        lineColor = QColor(int(255*1.0), int(255*0.4), int(255*0.4));
    }
    else if (kraftwerk->Leistung_aktuell() > 0.0)
    {
        lineColor = QColor(int(255*0.24), int(255*0.7), int(255*0.2));
    }
    else if (qAbs(kraftwerk->x_N) < 0.001)
    {
        lineColor = QColor(int(255*0.6), int(255*0.6), int(255*0.6));
    }

    qreal x_offset = 0.0;
    qreal y_offset = 0.5;

    if (kraftwerk->istSpeicher())
        x_offset = -5.0*1.5;
    else if (kraftwerk->x_Nmin < -0.0001)   // Last
        x_offset = -2*1.5;

    x_offset *= 20.0;   // Skalierung
    y_offset *= 20.0;   // Skalierung

    QBrush brush;
    QPen pen;

    brush.setColor(QColor(255, 255, 0, 100));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(lineColor);
    pen.setWidthF(qAbs(kraftwerk->x_N) + 0.5);

    painter->setBrush(brush);
    painter->setPen(pen);
    QFont font;
    font.setPointSizeF(6.0);
    painter->setFont(font);

    // Anschlusslinie zum Netzverknüpfungspunkt
    Knoten *knoten = sucheKnotenIndex(kraftwerk->K);
    QPointF posNVP = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    QPointF posKW = posNVP + QPointF(x_offset, y_offset);

    painter->drawLine(posNVP, posKW);

    QRectF bgRect;  // Background rect behind power plant
    bgRect.setWidth(50.0);
    if (kraftwerk->istSpeicher())
        bgRect.setHeight(55.0);
    else
        bgRect.setHeight(40.0);
    bgRect.moveTopRight(QPointF(0.0, -bgRect.height()/2.0));


    painter->save();
    painter->translate(posKW);
    painter->rotate(-90.0);



    QString kraftwerkstext;
    QString typ;
    QString Istleistungstext;
    QString Nennleistungstext;

    if (kraftwerk->istSpeicher())
        typ = "Speicher";
    else if (kraftwerk->x_Nmin < -0.0001)
        typ = "Last";
    else
        typ = "Kraftwerk";

    if (kraftwerk->P_N > 10000.0)
        Nennleistungstext.sprintf("%8.0f MW", kraftwerk->P_N / 1000.0);
    else
        Nennleistungstext.sprintf("%8.0f kW", kraftwerk->P_N);

    if (qAbs(kraftwerk->Leistung_aktuell()) > 10000.0)
        Istleistungstext.sprintf("%8.0f MW", kraftwerk->Leistung_aktuell() / 1000.0);
    else
        Istleistungstext.sprintf("%8.0f kW", kraftwerk->Leistung_aktuell());


    kraftwerkstext.sprintf("%s %03i\np=%s\nP=%s", typ.toUtf8().data(), kraftwerk->N, Istleistungstext.toUtf8().data(), Nennleistungstext.toUtf8().data());
    painter->drawRoundedRect(bgRect, 3.0, 3.0);

    painter->setPen(Qt::black);
    painter->drawText(bgRect.adjusted(2.0, 2.0, -2.0, -2.0), Qt::AlignHCenter | Qt::AlignTop, kraftwerkstext);

    brush.setColor(QColor(int(255*0.4), int(255*0.4), int(255*0.4)));
    painter->setBrush(brush);
    painter->setPen(Qt::NoPen);

    // Leistungsanzeige
    QRectF bargraph_bg;
    bargraph_bg.setWidth(40.0);
    bargraph_bg.setHeight(6.0);
    bargraph_bg.moveBottomLeft(bgRect.bottomLeft() + QPointF(2.0, -2.0));

    painter->drawRect(bargraph_bg);
    painter->setBrush(lineColor);
    QRectF bargraph = bargraph_bg.adjusted(1.0, 1.0, -1.0, -1.0);
    bargraph.setWidth(bargraph.width() * qAbs(kraftwerk->x_N));

    painter->drawRect(bargraph);

    // Bunkerfüllstandsanzeige
    if (kraftwerk->istSpeicher())
    {
        bargraph_bg.moveTop(bargraph_bg.top() - 18.0);
        bargraph_bg.adjust(0.0, 0.0, -5.0, 0.0);
        bargraph_bg.setHeight(14);
        painter->setBrush(brush);
        painter->drawRect(bargraph_bg);
        bargraph = bargraph_bg.adjusted(1.0, 1.0, -1.0, -1.0);
        painter->drawRect(bargraph_bg.adjusted(0.0, 4.0, 5.0, -4.0));

        painter->setBrush(QColor(int(255*0.2), int(255*0.2), int(255*1.0)));
        bargraph.setWidth(bargraph.width() * qAbs(kraftwerk->b_N));

        painter->drawRect(bargraph);
    }

    painter->restore();
}

void Netzberechnung::paintLeitung(QPainter *painter, Leitung *leitung)
{
    qreal lineWidth;
    QColor lineColor_lineOK(int(255*0.1), int(255*0.2), int(255*1.0));
    QColor lineColor_lineNotOK(int(255*1.0), int(255*0.4), int(255*0.4));

    Knoten* startKnoten = sucheKnotenIndex(leitung->Startknoten());
    Knoten* endKnoten = sucheKnotenIndex(leitung->Endknoten());
    lineWidth = qAbs(leitung->p_L) + 0.5;
    qreal power = qAbs(leitung->Leistung_aktuell());
    bool reversePower = (leitung->Leistung_aktuell() < 0.0);

    QBrush brush;
    QPen pen;
    QFont font;
    font.setPointSizeF(7.5);
    painter->setFont(font);

    brush.setColor(QColor(0, 0, 0, 0));
    brush.setStyle(Qt::SolidPattern);
    pen.setWidthF(lineWidth);

    if (leitung->gestoert())
        pen.setColor(lineColor_lineNotOK);
    else
        pen.setColor(lineColor_lineOK);

    painter->setBrush(brush);
    painter->setPen(pen);

    QPointF startPoint = QPointF(startKnoten->Long_K, this->height() / 20.0 - startKnoten->Lat_K) * 20.0;
    QPointF endPoint = QPointF(endKnoten->Long_K, this->height() / 20.0 - endKnoten->Lat_K) * 20.0;
    if (reversePower)
    {
        QPointF tmp = endPoint;
        endPoint = startPoint;
        startPoint = tmp;
    }
    painter->drawLine(startPoint, endPoint);

    // Leistungsflussrichtung mit Pfeil zeigen
    QPointF pfeilPoint = endPoint - 0.1 * (endPoint - startPoint);
    painter->save();
    painter->translate(pfeilPoint);
    painter->rotate(10);
    painter->drawLine(QPointF(0.0, 0.0), - 0.1 * (endPoint - startPoint));
    painter->rotate(-20);
    painter->drawLine(QPointF(0.0, 0.0), - 0.1 * (endPoint - startPoint));
    painter->restore();


    pen.setColor(Qt::black);
    QRectF textRect;
    textRect.setWidth(150.0);
    textRect.setHeight(15.0);
    textRect.moveCenter((startPoint + endPoint) / 2.0);

    QString text;
    if (power < 10000.0)
        text.sprintf("L%i: %.0lf kW", leitung->L, power);
    else
        text.sprintf("L%i: %8.0lf MW", leitung->L, power / 1000.0);

    QRectF br;
    painter->drawText(textRect, Qt::AlignCenter, text, &br);
    painter->setBrush(QColor(170, 245, 200, 190));
    painter->setPen(Qt::NoPen);
    br.adjust(-2.0, -2.0, 2.0, 2.0);
    painter->drawRect(br);
    painter->setPen(Qt::blue);
    painter->drawText(textRect, Qt::AlignCenter, text);
}

void Netzberechnung::paintKnoten(QPainter *painter, Knoten *knoten)
{
    QBrush brush;
    QPen pen;

    brush.setColor(QColor(int(255*0.2), int(255*0.7), int(255*0.6), 255));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(QColor(0, 0, 0, 255));

    painter->setBrush(brush);
    painter->setPen(pen);

    QPointF point = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    painter->drawEllipse(point, 4.0, 4.0);

    QString text;
    text.sprintf("K%i", knoten->K);
    painter->drawText(point + QPointF(10.0, 0.0), text);
}
