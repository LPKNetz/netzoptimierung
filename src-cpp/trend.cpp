#include "trend.h"

Trend::Trend(QObject *parent) : QObject(parent)
{

}

void Trend::TrendLaden(QString filename)
{
    Q_UNUSED(filename)
}

qreal Trend::StellwertBeiZeit(QDateTime time)
{
    return -0.3;
}

bool Trend::isNull()
{
    return false;   // tbd
}
