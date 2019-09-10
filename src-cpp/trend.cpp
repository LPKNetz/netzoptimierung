#include "trend.h"
#include <QFile>
#include <QByteArray>
#include <QList>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>

Trend::Trend(QObject *parent) : QObject(parent)
{

}

void Trend::TrendLaden(QString filename)
{
    emit signalLog("Trend", "Versuche " + filename + " zu laden...");
    if (filename.endsWith(".json"))
    {
        vonJSONladen(filename);
    }
    else if (filename.endsWith(".csv"))
    {
        vonCSVladen(filename);
    }
    else
    {
        emit signalLog("Error", "Trenddatei hat ungültige Dateiendung!");
        return;
    }
}

void Trend::vonJSONladen(QString filename)
{
    QFile file(filename);

    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Kann JSON Trend nicht öffnen!");
        return;
    }

    QByteArray ba = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(ba);
    if (doc.isNull())
    {
        emit signalLog("Error", "Kann JSON Trend nicht laden!");
        return;
    }

    QJsonArray array = doc.object()["observations"].toArray();
    if (array.isEmpty())
    {
        emit signalLog("Error", "JSON Trend Array ist leer!");
        return;
    }

    foreach (QJsonValue jsonVal, array)
    {
        QJsonObject obj = jsonVal.toObject();
        int unixtime = obj["valid_time_gmt"].toInt();
        double windSpeed = obj["wspd"].toDouble();
        double power = windSpeed / 25.0;

        T_Datenpunkt dp;
        dp.timestamp = QDateTime::fromSecsSinceEpoch(unixtime);
        dp.power = power;

        m_trend.append(dp);
    }
    emit signalLog("Trend", QString().setNum(m_trend.length()) + " Datenpunkte aus JSON geleaden");
}

void Trend::vonCSVladen(QString filename)
{
    QFile file(filename);

    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Kann CSV Trend nicht öffnen!");
        return;
    }

    QString str = QString::fromUtf8(file.readAll());
    file.close();

    QStringList lines = str.split("\n");

    foreach (QString line, lines)
    {
        line.replace(',', '.');
        QStringList fields = line.split(";", QString::SkipEmptyParts);
        if (fields.length() < 2)
            continue;

        qint64 unixtime = fields.at(0).toInt();
        double power = fields.at(1).toDouble();

        T_Datenpunkt dp;
        dp.timestamp = QDateTime::fromSecsSinceEpoch(unixtime);
        dp.power = power;

        m_trend.append(dp);
    }
    //emit signalLog("Trend", QString().setNum(m_trend.length()) + " Datenpunkte aus CSV geleaden");
}

qreal Trend::StellwertBeiZeit(QDateTime time)
{
    qreal power = 1.1;
    int unixtime = 0;

    if (m_trend.length() < 2)
        return power;

    int i = 0;
    bool found = false;
    foreach (T_Datenpunkt dp, m_trend)
    {
        if (dp.timestamp > time)
        {
            power = m_trend.at(i-1).power;
            unixtime = m_trend.at(i-1).timestamp.toSecsSinceEpoch();
            found = true;
            break;
        }
        i++;
    }

    if (!found)
    {
        unixtime = time.toSecsSinceEpoch();
        emit signalLog("Trend", QString().sprintf("Zeitstempel t=%i nicht gefunden!", unixtime));
    }
//    else
//        emit signalLog("Trend", QString().sprintf("Datenpunkt t=%i gefunden. Leistung: %6.4lf", unixtime, power));

    return power;
}

bool Trend::isNull()
{
    if (m_trend.length() <= 2)
        return true;
    else
        return false;
}
