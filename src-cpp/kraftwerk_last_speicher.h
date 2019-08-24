#ifndef KRAFTWERK_LAST_SPEICHER_H
#define KRAFTWERK_LAST_SPEICHER_H

#include <QObject>
#include <QDateTime>
#include "trend.h"

typedef enum {
    Festleistung,
    Fremdregelung,
    Klimabedingt,
    Selbstregelung
} Regelart;

class Kraftwerk_Last_Speicher : public QObject
{
    Q_OBJECT
public:
    explicit Kraftwerk_Last_Speicher(QObject *parent,
                                     quint32 Number,
                                     quint32 k,
                                     qreal PN,
                                     qreal xNmin,
                                     qreal xNmax,
                                     qreal xN,
                                     Regelart RN,
                                     qreal CN,
                                     qreal cN,
                                     bool oNP,
                                     qreal BN,
                                     qreal bN,
                                     qreal nN,
                                     bool oMK,
                                     bool oNB,
                                     QString tq);

    quint32 N;              // Nummer
    quint32 K;              // Netzverknüpfungspunkt
    qreal P_N;              // Nennleistung in kW
    qreal x_Nmin;           // Minimale Stellgröße
    qreal x_Nmax;           // Maximale Stellgröße
    qreal x_N;              // Aktuelle Stellgröße
    Regelart R_N;           // Regelart der Anlage
    qreal C_N;              // Fixkosten
    qreal c_N;              // Variabel Kosten
    bool o_NP;              // Erlaube Vorgabe Nennleistung durch Optimizer

    // Daten zusätzlich für Speicher
    qreal B_N;              // Bunkergröße
    qreal b_N;              // Bunkerfüllstand
    qreal n_N;              // Nachfüllrate
    bool o_MK;              // Erlaube Vorgabe Netzverknüpfungspunkt
    bool o_NB;              // Erlaube Vorgabe Bunkergröße
    QString TQ;             // Pfad Trendquelle
    Trend *trend;           // Trenddaten
    QDateTime t_alt;        // Letzter Zeitstempel
    quint64 delta_t_alt;    // Letzte Zeitschlitzdauer

    void Zeit_setzen(QDateTime time);
    qreal Fixkosten();
    qreal Variablekosten();
    void SollwertSetzen(qreal Sollwert);
    qreal Regelreserve_auf();
    qreal Regelreserve_auf_kW();
    qreal Regelreserve_ab();
    qreal Regelreserve_ab_kW();
    qreal Nennleistung_min();
    qreal Nennleistung_max();
    qreal Leistung_aktuell();
    quint32 Netzverknuepfungspunt();
    bool gestoert();
    bool istSpeicher();
    bool SpeicherIstLeer();
    bool SpeicherIstVoll();
    qreal VerfuegbareLeistungBezug_kW();
    qreal VerfuegbareStellgroesseBezug();
    qreal VerfuegbareLeistungLieferung_kW();
    qreal VerfuegbareStellgroesseLieferung();

private:
    void Speicher_rechnen(QDateTime time);


signals:

public slots:
};

#endif // KRAFTWERK_LAST_SPEICHER_H
