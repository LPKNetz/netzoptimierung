#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QtMath>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    mNetzberechnung = new Netzberechnung();
    mNetzberechnung->setLogger(&mLogger);
    mNetzberechnung->Netz_initialisieren();
    lowestCost = qInf();

    connect(&mLogger, SIGNAL(signalStringOutput(QString)), ui->plainTextEdit_log, SLOT(appendPlainText(QString)));
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_actionLastgang_rechnen_triggered()
{
    mNetzberechnung->Lastgang_rechnen();
}

void MainWindow::on_actionOptimizer_Rechnen_triggered()
{
    QString text;

    foreach (Knoten* kt, mNetzberechnung->mKnotenliste)
    {
        text += QString().sprintf("K%02i ", kt->K);
    }

    text += "  Kosten";
    text += "\n";

    quint32 AnzahlKnoten = quint32(mNetzberechnung->mKnotenliste.length());

    quint64 kombination = 0;

    while (kombination < qPow(2.0, AnzahlKnoten))
    {
        QList<bool> kombinationsListe;
        for (quint32 i=0; i<AnzahlKnoten; i++)
        {
            if (kombination & (1 << i))
            {
                kombinationsListe.prepend(true);
            }
            else
            {
                kombinationsListe.prepend(false);
            }
        }
        kombination++;

        // Verwendung der kombinationsListe
        threadfahrplan.append(kombinationsListe);
    }

     mLogger.slot_Log("Result", text);

    int numThreads = 4;

    for (int i=0; i<numThreads; i++)
    {
        if (threadfahrplan.isEmpty())
            continue;
        Netzberechnung* nb = new Netzberechnung(this);
//        nb->setLogger(&mLogger);
        nb->Netz_initialisieren();
        nb->SetzeSpeicherkombination(threadfahrplan.takeFirst(), 50000.0, 1250000.0, 0.11792, 53000.0, 0.5);
        connect(nb, SIGNAL(signalResult(QList<bool>, double)), this, SLOT(slotResult(QList<bool>, double)));
        connect(nb, SIGNAL(finished()), this, SLOT(slot_finished()));
        connect(nb, SIGNAL(finished()), nb, SLOT(quit()));
        //connect(nb, SIGNAL(finished()), nb, SLOT(deleteLater()));

        nb->start();
    }
}

void MainWindow::slot_finished()
{
    if (threadfahrplan.isEmpty())
        return;

    Netzberechnung* nb = new Netzberechnung(this);
//        nb->setLogger(&mLogger);
    nb->Netz_initialisieren();
    nb->SetzeSpeicherkombination(threadfahrplan.takeFirst(), 50000.0, 1250000.0, 0.11792, 48.0 * 50000.0, 0.5);
    connect(nb, SIGNAL(signalResult(QList<bool>, double)), this, SLOT(slotResult(QList<bool>, double)));
    connect(nb, SIGNAL(finished()), this, SLOT(slot_finished()));
    connect(nb, SIGNAL(finished()), nb, SLOT(quit()));
    nb->start();
}

void MainWindow::slotResult(QList<bool> kombinationsListe, double Tageskosten)
{
    QString text;

    foreach (bool NVPmitSpeicher, kombinationsListe)
    {
        if (NVPmitSpeicher)
        {
            text += "1   ";
        }
        else
        {
            text += "0   ";
        }
    }

    text += QString().sprintf("  %6.5e", Tageskosten);

    if (Tageskosten < lowestCost)
    {
        lowestCost = Tageskosten;
        ui->label_result->setText(text);
    }

    mLogger.slot_Log("Result", text);
}
