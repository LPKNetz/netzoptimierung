#include "knoten.h"

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

void Knoten::Zeit_setzen(QDateTime time)
{
    if (t_alt.isNull())
    {
        t_alt = time;
        return;
    }

    this->delta_t_alt = (quint64)this->t_alt.secsTo(time);
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
