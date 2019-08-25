#include "logger.h"

Logger::Logger(QObject *parent) : QObject(parent)
{

}

void Logger::slot_Log(QString category, QString text)
{
    printf("Log category: %s; Log Text: %s\n", category.toUtf8().data(), text.toUtf8().data());
}
