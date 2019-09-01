#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    mNetzberechnung = ui->widget_Netzberechnung;
    mNetzberechnung->setLogger(&mLogger);
    mNetzberechnung->Netz_initialisieren();

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
