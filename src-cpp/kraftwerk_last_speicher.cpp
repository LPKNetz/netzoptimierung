#include "kraftwerk_last_speicher.h"

Kraftwerk_Last_Speicher::Kraftwerk_Last_Speicher(QObject *parent,
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
                                                 QString tq) : QObject(parent)
{
    this->N = Number;
    this->K = k;
    this->P_N = PN;
    this->x_Nmin = xNmin;
    this->x_Nmax = xNmax;
    this->x_N = xN;
    this->R_N = RN;
    this->C_N = CN;
    this->c_N = cN;
    this->o_NP = oNP;

    // Daten zusätzlich bei Speichern
    this->B_N = BN;
    this->b_N = bN;
    this->n_N = nN;
    this->o_MK = oMK;
    this->o_NB = oNB;
    this->TQ = tq;
    this->trend = new Trend(this);
    this->t_alt = QDateTime();
    this->delta_t_alt = 15 * 60;
}

void Kraftwerk_Last_Speicher::setLogger(Logger *logger)
{
    mLogger = logger;
    connect(this, SIGNAL(signalLog(QString, QString)), logger, SLOT(slot_Log(QString, QString)));
}

bool Kraftwerk_Last_Speicher::parseCSVline(QString line)
{
    line.replace(',', '.');
    QList<QString> fields = line.split(';');

    if (fields.length() < 15)
    {
        emit signalLog("Error", "Kraftwerk: Kann fields nicht parsen");
        return false;
    }

    if (fields.at(0).isEmpty())
        return false;

    this->N = quint32(fields.at(0).toInt());
    this->K = quint32(fields.at(1).toInt());
    this->P_N = fields.at(2).toDouble();
    this->x_Nmin = fields.at(3).toDouble();
    this->x_Nmax = fields.at(4).toDouble();
    this->x_N = fields.at(5).toDouble();
    this->R_N = Regelart(fields.at(6).toInt());
    this->C_N = fields.at(7).toDouble();
    this->c_N = fields.at(8).toDouble();
    this->o_NP = bool(fields.at(9).toInt());

    // Daten zusätzlich bei Speichern
    this->B_N = fields.at(10).toDouble();
    this->b_N = fields.at(11).toDouble();
    this->n_N = fields.at(12).toDouble();
    this->o_MK = bool(fields.at(13).toInt());
    this->o_NB = bool(fields.at(14).toInt());
    this->TQ = fields.at(15);

    return true;
}

void Kraftwerk_Last_Speicher::Zeit_setzen(QDateTime time)
{
    if (t_alt.isNull())
    {
        t_alt = time;
        return;
    }

    this->delta_t_alt = (quint64)this->t_alt.secsTo(time);
    this->t_alt = time;

    if (this->istSpeicher())
        this->Speicher_rechnen();

    if (this->trend->isNull())
        return;

    this->SollwertSetzen(this->trend->StellwertBeiZeit(time));
}

qreal Kraftwerk_Last_Speicher::Fixkosten()
{
    return (this->C_N / 8760.0 / 3600.0 * this->delta_t_alt);
}

qreal Kraftwerk_Last_Speicher::Variablekosten()
{
    return (qAbs(this->Leistung_aktuell()) * this->c_N / 3600.0 * this->delta_t_alt);
}

void Kraftwerk_Last_Speicher::SollwertSetzen(qreal Sollwert)
{
    qreal min = this->VerfuegbareStellgroesseBezug();
    qreal max = this->VerfuegbareStellgroesseLieferung();

    if (Sollwert >= max)
        this->x_N = max;
    else if (Sollwert <= min)
        this->x_N = min;
    else
        this->x_N = Sollwert;

    if (this->SpeicherIstVoll() && (this->x_N <= 0.0))
        this->x_N = 0.0;
    else if (this->SpeicherIstLeer() && (this->x_N >= 0.0))
        this->x_N = 0.0;
}

qreal Kraftwerk_Last_Speicher::Regelreserve_auf()
{
    if (this->R_N != Fremdregelung)
        return 0.0;

    qreal max = this->VerfuegbareStellgroesseLieferung();
    qreal result = max - this->x_N;
    if (result <= 0)
        result = 0.0;

    if (this->istSpeicher() && (this->b_N <= 0.0))
        result = 0.0;

    return result;
}

qreal Kraftwerk_Last_Speicher::Regelreserve_auf_kW()
{
    return (this->Regelreserve_auf() * this->P_N);
}

qreal Kraftwerk_Last_Speicher::Regelreserve_ab()
{
    if (this->R_N != Fremdregelung)
        return 0.0;

    qreal min = this->VerfuegbareStellgroesseBezug();
    qreal result = this->x_N - min;

    if (result <= 0)
        result = 0.0;

    if (this->istSpeicher() && (this->b_N >= 1.0))
        result = 0.0;

    return result;
}

qreal Kraftwerk_Last_Speicher::Regelreserve_ab_kW()
{
    return (this->Regelreserve_ab() * this->P_N);
}

qreal Kraftwerk_Last_Speicher::Nennleistung_min()
{
    return (this->P_N * this->x_Nmin);
}

qreal Kraftwerk_Last_Speicher::Nennleistung_max()
{
    return (this->P_N * this->x_Nmax);
}

qreal Kraftwerk_Last_Speicher::Leistung_aktuell()
{
    if (this->istSpeicher() && (this->b_N >= 1.0) && (this->x_N <= 0.0))
        return 0.0;
    if (this->istSpeicher() && (this->b_N <= 0.0) && (this->x_N >= 0.0))
        return 0.0;

    return (this->P_N * this->x_N);
}

quint32 Kraftwerk_Last_Speicher::Netzverknuepfungspunkt()
{
    return (this->K);
}

bool Kraftwerk_Last_Speicher::gestoert()
{
    if ((this->x_N < this->x_Nmin) || (this->x_N > this->x_Nmax))
        return true;
    if ((this->b_N < 0.0) || (this->b_N > 1.0))
        return true;

    return false;
}

bool Kraftwerk_Last_Speicher::istSpeicher()
{
    if ((this->x_Nmin < 0.001) && (this->B_N > 0.001))
        return true;
    else
        return false;
}

bool Kraftwerk_Last_Speicher::SpeicherIstLeer()
{
    return (this->istSpeicher() && (this->b_N <= 0.0));
}

bool Kraftwerk_Last_Speicher::SpeicherIstVoll()
{
    return (this->istSpeicher() && (this->b_N >= 1.0));
}

qreal Kraftwerk_Last_Speicher::VerfuegbareLeistungBezug_kW()
{
    if (this->gestoert())
        return 0.0;

    qreal result = this->P_N * this->x_Nmin;

    if (this->istSpeicher())    // Ladebetrieb
    {
        qreal restenergie = (1.0 - this->b_N) * this->B_N;
        qreal power = -restenergie / (this->delta_t_alt / 3600.0);
        if (power > result)
            result = power;
    }

    return result;
}

qreal Kraftwerk_Last_Speicher::VerfuegbareStellgroesseBezug()
{
    return (this->VerfuegbareLeistungBezug_kW() / this->P_N);
}

qreal Kraftwerk_Last_Speicher::VerfuegbareLeistungLieferung_kW()
{
    if (this->gestoert())
        return 0.0;

    qreal result = this->P_N * this->x_Nmax;

    if (this->istSpeicher())    // Entladebetrieb
    {
        qreal restenergie = this->b_N * this->B_N;
        qreal power = restenergie / (this->delta_t_alt / 3600.0);
        if (power < result)
            result = power;
    }

    return (result);
}

qreal Kraftwerk_Last_Speicher::VerfuegbareStellgroesseLieferung()
{
    return (this->VerfuegbareLeistungLieferung_kW() / this->P_N);
}

void Kraftwerk_Last_Speicher::Speicher_rechnen()
{
    qreal delta_kWh = -this->Leistung_aktuell() * this->delta_t_alt / 3600.0;

    this->b_N += delta_kWh / this->B_N;
}
