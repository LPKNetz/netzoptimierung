#ifndef KNOTEN_H
#define KNOTEN_H

#include <QObject>
#include <QDateTime>

class Knoten : public QObject
{
    Q_OBJECT
public:
    explicit Knoten(QObject *parent, quint32 k, qreal longK, qreal latK, qreal PK, qreal CK, bool oPK);

    quint32 K;              // Knotenindex
    qreal Long_K;           // Längengrad Position des Knoten
    qreal Lat_K;            // Breitengrad Porisiton des Knoten
    qreal P_K;              // Bemessunngsleistung des Knoten in kW
    qreal C_K;              // Fixkosten des Knoten
    bool o_PK;              // Erlaube Vorgabe Bemessungsleistung durch Optimizer
    QDateTime t_alt;        // Letzter Zeitstempel
    quint64 delta_t_alt;    // Letzte Zeitschlitzdauer

    void Zeit_setzen(QDateTime time);
    qreal Fixkosten();
    qreal Variablekosten();

signals:

public slots:
};

#endif // KNOTEN_H
