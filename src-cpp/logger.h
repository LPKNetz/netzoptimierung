#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>

class Logger : public QObject
{
    Q_OBJECT
public:
    explicit Logger(QObject *parent = nullptr);



signals:
    void signalStringOutput(QString str);

public slots:
    void slot_Log(QString category, QString text);
};

#endif // LOGGER_H
