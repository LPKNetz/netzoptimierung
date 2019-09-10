#include "logger.h"

Logger::Logger(QObject *parent) : QObject(parent)
{

}

void Logger::slot_Log(QString category, QString text)
{
    QString str;
    str.sprintf("Log category: %s; Log Text: %s\n", category.toUtf8().data(), text.toUtf8().data());
    //printf("%s", str.toUtf8().data());
    emit signalStringOutput(str);
}
