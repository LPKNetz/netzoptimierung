#ifndef KNOTEN_H
#define KNOTEN_H

#include <QObject>
#include <QDateTime>
#include "logger.h"

class Knoten : public QObject
{
    Q_OBJECT
public:
    explicit Knoten(QObject *parent,
                    quint32 k = 0,
                    qreal longK = 0.0,
                    qreal latK = 0.0,
                    qreal PK = 0.0,
                    qreal CK = 0.0,
                    bool oPK = false);

    quint32 K;              // Knotenindex
    qreal Long_K;           // Längengrad Position des Knoten
    qreal Lat_K;            // Breitengrad Porisiton des Knoten
    qreal P_K;              // Bemessunngsleistung des Knoten in kW
    qreal C_K;              // Fixkosten des Knoten
    bool o_PK;              // Erlaube Vorgabe Bemessungsleistung durch Optimizer
    QDateTime t_alt;        // Letzter Zeitstempel
    quint64 delta_t_alt;    // Letzte Zeitschlitzdauer

    Logger *mLogger;

    void setLogger(Logger* logger);
    bool parseCSVline(QString line);
    QString print();

    void Zeit_setzen(QDateTime time);
    qreal Fixkosten();
    qreal Variablekosten();

signals:
    void signalLog(QString category, QString text);

public slots:
};

#endif // KNOTEN_H
