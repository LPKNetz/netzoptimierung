#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "netzberechnung.h"
#include "logger.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_actionLastgang_rechnen_triggered();

    void on_actionOptimizer_Rechnen_triggered();

    void slot_finished();

    void slotResult(QList<bool> kombinationsListe, double Tageskosten);

private:
    Ui::MainWindow *ui;
    Netzberechnung *mNetzberechnung;
    Logger mLogger;

    QList<QList<bool>> threadfahrplan;
};

#endif // MAINWINDOW_H
