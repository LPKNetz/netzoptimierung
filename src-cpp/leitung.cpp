#include "leitung.h"

Leitung::Leitung(QObject *parent,
                 quint32 l,
                 quint32 kL1,
                 quint32 kL2,
                 qreal PL,
                 qreal pL,
                 qreal RL,
                 qreal CL,
                 qreal cL,
                 bool oKL,
                 bool oPL) : QObject(parent)
{
    L = l;
    K_L1 = kL1;
    K_L2 = kL2;
    P_L = PL;
    p_L = pL;
    R_L = RL;
    C_L = CL;
    c_L = cL;
    o_KL = oKL;
    o_PL = oPL;
    t_alt = QDateTime();
    delta_t_alt = 15 * 60;
}

void Leitung::setLogger(Logger *logger)
{
    mLogger = logger;
    connect(this, SIGNAL(signalLog(QString, QString)), logger, SLOT(slot_Log(QString, QString)));
}

bool Leitung::parseCSVline(QString line)
{
    line.replace(',', '.');
    QList<QString> fields = line.split(';');

    if (fields.length() < 10)
    {
        emit signalLog("Error", "Leitung: Kann fields nicht parsen");
        return false;
    }

    if (fields.at(0).isEmpty())
        return false;

    L = quint32(fields.at(0).toInt());
    K_L1 = quint32(fields.at(1).toInt());
    K_L2 = quint32(fields.at(2).toInt());
    P_L = fields.at(3).toDouble();
    p_L = fields.at(4).toDouble();
    R_L = fields.at(5).toDouble();
    C_L = fields.at(6).toDouble();
    c_L = fields.at(7).toDouble();
    o_KL = bool(fields.at(8).toInt());
    o_PL = bool(fields.at(9).toInt());

    return true;
}

QString Leitung::print()
{
    QString text;

    text += QString().sprintf("Leitung L=%i K_L1=%i K_L2=%i P_L=%.3lf p_L=%.3lf R_L=%.3lf C_L=%.3lf c_L=%.3lf o_KL=%i o_PL=%i",
                              L, K_L1, K_L2, P_L, p_L, R_L, C_L, c_L, o_KL, o_PL);

    return text;
}

qreal Leitung::Transportleistung()
{
    return (this->p_L * this->P_L);
}

qreal Leitung::Leitungswiderstand()
{
    return (this->R_L);
}

void Leitung::Aktuelle_Leistung_setzen_in_kW(qreal leistung)
{
    this->p_L = leistung / this->P_L;
}

quint32 Leitung::Startknoten()
{
    return this->K_L1;
}

quint32 Leitung::Endknoten()
{
    return  this->K_L2;
}

void Leitung::Zeit_setzen(QDateTime time)
{
    if (t_alt.isNull())
    {
        t_alt = time;
        return;
    }

    this->delta_t_alt = (quint64)this->t_alt.secsTo(time);
    this->t_alt = time;
}

qreal Leitung::Fixkosten()
{
    return (this->C_L / 8760.0 / 3600.0 * this->delta_t_alt);
}

qreal Leitung::Variablekosten()
{
    return (qAbs(this->Leistung_aktuell()) * this->c_L / 3600.0 * this->delta_t_alt);
}

qreal Leitung::Leistung_aktuell()
{
    return (this->p_L * this->P_L);
}

qreal Leitung::Bemessungsleistung()
{
    return (this->P_L);
}

bool Leitung::gestoert()
{
    if (((this->p_L * this->P_L) < -this->P_L) || ((this->p_L * this->P_L) > this->P_L))
        return true;
    else
        return false;
}
