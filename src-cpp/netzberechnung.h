#ifndef NETZBERECHNUNG_H
#define NETZBERECHNUNG_H

#include <QThread>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QKeyEvent>
#include <QPaintEvent>
#include <QPainter>
#include <QImage>
#include <QList>

#include "kraftwerk_last_speicher.h"
#include "leitung.h"
#include "knoten.h"
#include "logger.h"
#include "math/matrix.h"

class Netzberechnung : public QThread
{
    Q_OBJECT
public:
    explicit Netzberechnung(QObject *parent = nullptr);
    ~Netzberechnung();

    QList<Kraftwerk_Last_Speicher*> mKraftwerksliste;
    QList<Leitung*> mLeitungliste;
    QList<Knoten*> mKnotenliste;

    Matrix mNetzmatrix_Leitungen_invers;

    void setLogger(Logger* logger);

    void Netz_initialisieren();
    void Knoten_initialisieren(QString filename);
    void Leitungen_initialisieren(QString filename);
    void Kraftwerke_initialisieren(QString filename);

    void SetzeSpeicherkombination(QList<bool> kombinationsListe, double P_N, double CN, double cN, double BN, double bN);

    double Lastgang_rechnen();
    void Netzmatrix_Leitungen_invers_berechnen();
    void Leitungsfluss_berechnen();
    bool Netzunterdeckung_regeln();
    bool Netz_anregeln();
    void Logfile_schreiben();
    void Zeit_setzen(QDateTime time);
    void initAnimation(QString filename, int framerate);
    void addFrame(QImage image);
    void finishAnimation();

    double Netzausspeiseleistung_verfuegbar_min();
    double Netzausspeiseleistung_verfuegbar_max();
    double Netzeinspeiseleistung_verfuegbar_min();
    double Netzeinspeiseleistung_verfuegbar_max();
    double Netzeinspeiseleistung_aktuell();
    double Netzausspeiseleistung_aktuell();
    double Netzunterdeckung_aktuell();
    double Kraftwerksreserve_aktuell();
    int Anzahl_Kraftwerks_und_Last_Stoerfaelle();
    double Nennleistung_Kraftwerks_und_Last_Stoerfaelle();
    double Nennleistung_groesste_Einheit();
    double Nennleistung_zweitgroesste_Einheit();
    bool Einfachredundanz_Kraftwerke_ok();
    bool Zweifachredundanz_Kraftwerke_ok();
    double Regelreserve_auf_kW();
    double Regelreserve_ab_kW();
    int Anzahl_Leitungs_Stoerfaelle();
    double Bemessungsleistung_Leitungs_Stoerfaelle();
    double Bemessungsleistung_groesste_Leitung();
    double Bemessungsleistung_zweitgroesste_Leitung();
    double Netzkosten_berechnen();
    double Leitungslastquadratsumme_berechnen();



    Knoten* sucheKnotenIndex(quint32 knotenNr);
    Leitung* sucheLeitungIndex(quint32 LeitungNr);
    Kraftwerk_Last_Speicher* sucheKraftwerkIndex(quint32 KraftwerkNr);
    QList<Kraftwerk_Last_Speicher*> sucheKraftwerkeAnKnoten(quint32 KnotenNr);

protected:
//    void mouseMoveEvent(QMouseEvent *event);
//    void mousePressEvent(QMouseEvent *event);
//    void mouseReleaseEvent(QMouseEvent *event);
//    void wheelEvent(QWheelEvent* event);
//    void keyPressEvent(QKeyEvent *event);
//    void paintEvent(QPaintEvent *event);

private:
    Logger *mLogger;
    QList<bool> mKombinationsListe;

    void update();
    int height();
    void paintNetz(QPaintDevice *paintDevice);
    void paintKraftwerk(QPainter *painter, Kraftwerk_Last_Speicher *kraftwerk);
    void paintLeitung(QPainter *painter, Leitung *leitung);
    void paintKnoten(QPainter *painter, Knoten *knoten);
    void log(QString category, QString text);

    // Multithreading
    void run();


signals:
    void signalLog(QString category, QString text);
    void signalResult(QList<bool> kombinationsListe, double Tageskosten);

public slots:
};

#endif // NETZBERECHNUNG_H
