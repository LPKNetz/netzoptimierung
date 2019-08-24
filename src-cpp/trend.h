#ifndef TREND_H
#define TREND_H

#include <QObject>
#include <QDateTime>
#include <QList>

class Trend : public QObject
{
    Q_OBJECT
public:
    explicit Trend(QObject *parent);

    typedef struct
    {
        QDateTime timestamp;
        qreal power;
    } T_Datenpunkt;

    QList<T_Datenpunkt> m_trend;

    void TrendLaden(QString filename);
    qreal StellwertBeiZeit(QDateTime time);
    bool isNull();

signals:

public slots:
};

#endif // TREND_H
