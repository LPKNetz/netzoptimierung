#ifndef KRAFTWERK_LAST_SPEICHER_H
#define KRAFTWERK_LAST_SPEICHER_H

#include <QObject>
#include <QDateTime>
#include "trend.h"
#include "logger.h"

typedef enum {
    Festleistung = 1,
    Fremdregelung = 2,
    Klimabedingt = 3,
    Selbstregelung = 4
} Regelart;

class Kraftwerk_Last_Speicher : public QObject
{
    Q_OBJECT
public:
    explicit Kraftwerk_Last_Speicher(QObject *parent,
                                     quint32 Number = 0,
                                     quint32 k = 0,
                                     qreal PN = 0.0,
                                     qreal xNmin = 0.0,
                                     qreal xNmax = 0.0,
                                     qreal xN = 0.0,
                                     Regelart RN = Festleistung,
                                     qreal CN = 0.0,
                                     qreal cN = 0.0,
                                     bool oNP = false,
                                     qreal BN = 0.0,
                                     qreal bN = 0.0,
                                     qreal nN = 0.0,
                                     bool oNK = false,
                                     bool oNB = false,
                                     QString tq = QString());

    quint32 N;              // Nummer
    quint32 K;              // Netzverknüpfungspunkt
    qreal P_N;              // Nennleistung in kW
    qreal x_Nmin;           // Minimale Stellgröße
    qreal x_Nmax;           // Maximale Stellgröße
    qreal x_N;              // Aktuelle Stellgröße
    qreal x_N_store;        // Speicherwert der Stellgröße
    Regelart R_N;           // Regelart der Anlage
    qreal C_N;              // Fixkosten
    qreal c_N;              // Variabel Kosten
    bool o_NP;              // Erlaube Vorgabe Nennleistung durch Optimizer

    // Daten zusätzlich für Speicher
    qreal B_N;              // Bunkergröße
    qreal b_N;              // Bunkerfüllstand
    qreal n_N;              // Nachfüllrate
    bool o_NK;              // Erlaube Vorgabe Netzverknüpfungspunkt
    bool o_NB;              // Erlaube Vorgabe Bunkergröße
    QString TQ;             // Pfad Trendquelle
    Trend *trend;           // Trenddaten
    QDateTime t_alt;        // Letzter Zeitstempel
    quint64 delta_t_alt;    // Letzte Zeitschlitzdauer

    Logger *mLogger;

    void setLogger(Logger* logger);
    bool parseCSVline(QString line);

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
    quint32 Netzverknuepfungspunkt();
    bool gestoert();
    bool istSpeicher();
    bool SpeicherIstLeer();
    bool SpeicherIstVoll();
    qreal VerfuegbareLeistungBezug_kW();
    qreal VerfuegbareStellgroesseBezug();
    qreal VerfuegbareLeistungLieferung_kW();
    qreal VerfuegbareStellgroesseLieferung();
    void SollwertSpeichern();
    void SollwertWiederherstellen();

private:
    void Speicher_rechnen();


signals:
    void signalLog(QString category, QString text);

public slots:
};

#endif // KRAFTWERK_LAST_SPEICHER_H
