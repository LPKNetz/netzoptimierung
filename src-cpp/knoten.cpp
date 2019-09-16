#include "knoten.h"
#include <QList>

Knoten::Knoten(QObject *parent, quint32 k, qreal longK, qreal latK, qreal PK, qreal CK, bool oPK) : QObject(parent)
{
    this->K = k;                    // Knotenindex
    this->Long_K = longK;           // Längengrad Position des Knoten
    this->Lat_K = latK;             // Breitengrad Porisiton des Knoten
    this->P_K = PK;                 // Bemessunngsleistung des Knoten in kW
    this->C_K = CK;                 // Fixkosten des Knoten
    this->o_PK = oPK;               // Erlaube Vorgabe Bemessungsleistung durch Optimizer
    this->t_alt = QDateTime();      // Letzter Zeitstempel
    this->delta_t_alt = 15*60;      // Letzte Zeitschlitzdauer
}

void Knoten::setLogger(Logger *logger)
{
    mLogger = logger;
    connect(this, SIGNAL(signalLog(QString, QString)), logger, SLOT(slot_Log(QString, QString)));
}

bool Knoten::parseCSVline(QString line)
{
    line.replace(',', '.');
    QList<QString> fields = line.split(';');

    if (fields.length() < 6)
    {
        emit signalLog("Error", "Knoten: Kann fields nicht parsen");
        return false;
    }

    if (fields.at(0).isEmpty())
        return false;

    this->K = quint32(fields.at(0).toInt());          // Knotenindex
    this->Long_K = fields.at(1).toDouble();           // Längengrad Position des Knoten
    this->Lat_K = fields.at(2).toDouble();            // Breitengrad Porisiton des Knoten
    this->P_K = fields.at(3).toDouble();              // Bemessunngsleistung des Knoten in kW
    this->C_K = fields.at(4).toDouble();              // Fixkosten des Knoten
    this->o_PK = bool(fields.at(5).toInt());          // Erlaube Vorgabe Bemessungsleistung durch Optimizer

    return true;
}

QString Knoten::print()
{
    QString text;

    text += QString().sprintf("Knoten K=%i Long_K=%.3lf Lat_K=%.3lf P_K=%.0lf C_K=%.3lf o_PK=%i",
                              K, Long_K, Lat_K, P_K, C_K, o_PK);

    return text;
}

void Knoten::Zeit_setzen(QDateTime time)
{
    if (t_alt.isNull())
    {
        t_alt = time;
        return;
    }

    this->delta_t_alt = quint64(this->t_alt.secsTo(time));
    this->t_alt = time;
}

qreal Knoten::Fixkosten()
{
    return (this->C_K / 8760.0 / 3600.0 * this->delta_t_alt);
}

qreal Knoten::Variablekosten()
{
    return 0.0;
}
