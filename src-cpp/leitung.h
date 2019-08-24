#ifndef LEITUNG_H
#define LEITUNG_H

#include <QObject>
#include <QDateTime>

class Leitung : public QObject
{
    Q_OBJECT
public:
    explicit Leitung(QObject *parent,
                     quint32 l,
                     quint32 kL1,
                     quint32 kL2,
                     qreal PL,
                     qreal pL,
                     qreal RL,
                     qreal CL,
                     qreal cL,
                     bool oKL,
                     bool oPL);

    quint32 L;              // Leitungsnummer
    quint32 K_L1;           // Startknoten
    quint32 K_L2;           // Endknoten
    qreal P_L;              // Bemessungsleistung
    qreal p_L;              // Relative Auslastung der Leitung
    qreal R_L;              // Leitungswiderstand
    qreal C_L;              // Fixkosten
    qreal c_L;              // Variable Kosten
    bool o_KL;              // Erlaube Vorgabe Netzverknüpfungspunkt
    bool o_PL;              // Erlaube Vorgabe Bemessungsleistung
    QDateTime t_alt;        // Letzter Zeitstempel
    quint64 delta_t_alt;    // Letzte Zeitschlitzdauer

    qreal Transportleistung();
    qreal Leitungswiderstand();
    void Aktuelle_Leistung_setzen_in_kW(qreal leistung);
    quint32 Startknoten();
    quint32 Endknoten();
    void Zeit_setzen(QDateTime time);
    qreal Fixkosten();
    qreal Variablekosten();
    qreal Leistung_aktuell();
    qreal Bemessungsleistung();
    bool gestoert();

signals:

public slots:
};

#endif // LEITUNG_H
