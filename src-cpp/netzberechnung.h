#ifndef NETZBERECHNUNG_H
#define NETZBERECHNUNG_H

#include <QWidget>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QKeyEvent>
#include <QPaintEvent>
#include <QPainter>
#include <QList>

#include "kraftwerk_last_speicher.h"
#include "leitung.h"
#include "knoten.h"
#include "logger.h"

class Netzberechnung : public QWidget
{
    Q_OBJECT
public:
    explicit Netzberechnung(QWidget *parent = nullptr);

    QList<Kraftwerk_Last_Speicher*> mKraftwerksliste;
    QList<Leitung*> mLeitungliste;
    QList<Knoten*> mKnotenliste;

    void setLogger(Logger* logger);

    void Netz_initialisieren();
    void Knoten_initialisieren(QString filename);
    void Leitungen_initialisieren(QString filename);
    void Kraftwerke_initialisieren(QString filename);

    Knoten* sucheKnotenIndex(quint32 knotenNr);
    Leitung* sucheLeitungIndex(quint32 LeitungNr);
    Kraftwerk_Last_Speicher* sucheKraftwerkIndex(quint32 KraftwerkNr);
    QList<Kraftwerk_Last_Speicher*> sucheKraftwerkeAnKnoten(quint32 KnotenNr);

protected:
    void mouseMoveEvent(QMouseEvent *event);
    void mousePressEvent(QMouseEvent *event);
    void mouseReleaseEvent(QMouseEvent *event);
    void wheelEvent(QWheelEvent* event);
    void keyPressEvent(QKeyEvent *event);
    void paintEvent(QPaintEvent *event);

private:
    Logger *mLogger;

    void paintNetz(QPaintDevice *paintDevice);
    void paintKraftwerk(QPainter *painter, Kraftwerk_Last_Speicher *kraftwerk);
    void paintLeitung(QPainter *painter, Leitung *leitung);
    void paintKnoten(QPainter *painter, Knoten *knoten);


signals:
    void signalLog(QString category, QString text);

public slots:
};

#endif // NETZBERECHNUNG_H
