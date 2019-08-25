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
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_actionLastgang_rechnen_triggered()
{

}
