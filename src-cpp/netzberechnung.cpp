#include "netzberechnung.h"
#include <QFile>

Netzberechnung::Netzberechnung(QWidget *parent) : QWidget(parent)
{

}

void Netzberechnung::setLogger(Logger *logger)
{
    mLogger = logger;
    connect(this, SIGNAL(signalLog(QString, QString)), logger, SLOT(slot_Log(QString, QString)));
}

void Netzberechnung::Netz_initialisieren()
{
    Knoten_initialisieren("../data/Knotentabelle.csv");
    Leitungen_initialisieren("../data/Leitungstabelle.csv");
    Kraftwerke_initialisieren("../data/Kraftwerke_Lasten_Speichertabelle.csv");
    emit signalLog("Info", "Netz ist initialisiert");
}

void Netzberechnung::Knoten_initialisieren(QString filename)
{
    mKnotenliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;
        QString lineStr = QString::fromUtf8(line).trimmed();

        Knoten* knoten = new Knoten(this);
        if (knoten->parseCSVline(lineStr))
        {
            knoten->setLogger(mLogger);
            mKnotenliste.append(knoten);
        }
        else
            delete knoten;
    }

    emit signalLog("Info", QString().sprintf("%i Knoten geladen", mKnotenliste.length()));

    file.close();
}

void Netzberechnung::Leitungen_initialisieren(QString filename)
{
    mLeitungliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;

        QString lineStr = QString::fromUtf8(line).trimmed();

        Leitung* leitung = new Leitung(this);
        if (leitung->parseCSVline(lineStr))
        {
            leitung->setLogger(mLogger);
            mLeitungliste.append(leitung);
        }
        else
            delete leitung;
    }

    emit signalLog("Info", QString().sprintf("%i Leitungen geladen", mLeitungliste.length()));

    file.close();
}

void Netzberechnung::Kraftwerke_initialisieren(QString filename)
{
    mKraftwerksliste.clear();

    QFile file;
    file.setFileName(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        emit signalLog("Error", "Knoten_initialisieren: Kann Datei nicht öffnen");
        return;
    }

    QByteArray data = file.readAll();

    QList<QByteArray> lines = data.split('\n');

    int lineNr = 0;
    foreach (QByteArray line, lines)
    {
        if (lineNr++ == 0)
            continue;
        QString lineStr = QString::fromUtf8(line).trimmed();

        Kraftwerk_Last_Speicher* kraftwerk = new Kraftwerk_Last_Speicher(this);
        if (kraftwerk->parseCSVline(lineStr))
        {
            kraftwerk->setLogger(mLogger);
            mKraftwerksliste.append(kraftwerk);
        }
        else
            delete kraftwerk;
    }

    emit signalLog("Info", QString().sprintf("%i Kraftwerke geladen", mKraftwerksliste.length()));

    file.close();
}

QList<Kraftwerk_Last_Speicher *> Netzberechnung::sucheKraftwerkeAnKnoten(quint32 KnotenNr)
{
    QList<Kraftwerk_Last_Speicher *> list;

    foreach(Kraftwerk_Last_Speicher* kraftwerk, mKraftwerksliste)
    {
        if (kraftwerk->K == KnotenNr)
            list.append(kraftwerk);
    }

    return list;
}

Knoten *Netzberechnung::sucheKnotenIndex(quint32 knotenNr)
{
    foreach(Knoten* knoten, mKnotenliste)
    {
        if (knoten->K == knotenNr)
            return knoten;
    }

    return nullptr;
}

Leitung *Netzberechnung::sucheLeitungIndex(quint32 LeitungNr)
{
    foreach(Leitung* leitung, mLeitungliste)
    {
        if(leitung->L == LeitungNr)
            return leitung;
    }

    return nullptr;
}

Kraftwerk_Last_Speicher *Netzberechnung::sucheKraftwerkIndex(quint32 KraftwerkNr)
{
    foreach(Kraftwerk_Last_Speicher* kraftwerk, mKraftwerksliste)
    {
        if(kraftwerk->N == KraftwerkNr)
            return  kraftwerk;
    }

    return nullptr;
}

void Netzberechnung::mouseMoveEvent(QMouseEvent *event)
{

}

void Netzberechnung::mousePressEvent(QMouseEvent *event)
{

}

void Netzberechnung::mouseReleaseEvent(QMouseEvent *event)
{

}

void Netzberechnung::wheelEvent(QWheelEvent *event)
{

}

void Netzberechnung::keyPressEvent(QKeyEvent *event)
{

}

void Netzberechnung::paintEvent(QPaintEvent *event)
{
//    QPainter painter;
//    painter.begin(this);
//    painter.setRenderHint(QPainter::Antialiasing);

//    painter.setBrush(QBrush(Qt::yellow));
//    painter.setPen(Qt::black);
//    painter.drawRect(10, 10, 50, 50);

//    painter.end();

    paintNetz(this);

    event->accept();
}

void Netzberechnung::paintNetz(QPaintDevice *paintDevice)
{
    foreach(Kraftwerk_Last_Speicher *kraftwerk, mKraftwerksliste)
    {
        paintKraftwerk(paintDevice, kraftwerk);
    }

    foreach(Leitung *leitung, mLeitungliste)
    {
        paintLeitung(paintDevice, leitung);
    }

    foreach(Knoten *knoten, mKnotenliste)
    {
        paintKnoten(paintDevice, knoten);
    }
}

void Netzberechnung::paintKraftwerk(QPaintDevice *paintDevice, Kraftwerk_Last_Speicher *kraftwerk)
{
    QColor lineColor = QColor(int(255*0.4), int(255*0.2), int(255*0.1));
    if (kraftwerk->gestoert())
    {
        lineColor = QColor(int(255*1.0), int(255*0.4), int(255*0.4));
    }
    else if (kraftwerk->Leistung_aktuell() > 0.0)
    {
        lineColor = QColor(int(255*0.24), int(255*0.9), int(255*0.0));
    }
    else if (qAbs(kraftwerk->x_N) < 0.001)
    {
        lineColor = QColor(int(255*0.6), int(255*0.6), int(255*0.6));
    }

    qreal x_offset = 0.0;
    qreal y_offset = 1.0;

    if (kraftwerk->istSpeicher())
        x_offset = -5.0*1.5;
    else if (kraftwerk->x_Nmin < -0.0001)
        x_offset = -2*1.5;

    x_offset *= 20.0;   // Skalierung
    y_offset *= 20.0;   // Skalierung

    QPainter painter;
    painter.begin(paintDevice);
    painter.setRenderHint(QPainter::Antialiasing);

    QBrush brush;
    QPen pen;

    brush.setColor(QColor(255, 255, 0, 100));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(lineColor);
    pen.setWidthF(qAbs(kraftwerk->x_N) + 0.5);

    painter.setBrush(brush);
    painter.setPen(pen);

    // Anschlusslinie zum Netzverknüpfungspunkt
    Knoten *knoten = sucheKnotenIndex(kraftwerk->K);
    QPointF posNVP = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    QPointF posKW = posNVP + QPointF(x_offset, y_offset);

    painter.drawLine(posNVP, posKW);

    QRectF bgRect;
    bgRect.setWidth(40.0);
    bgRect.setHeight(80.0);
    bgRect.moveTopRight(posKW + QPointF(bgRect.width()/2.0, 0.0));

    painter.drawRoundedRect(bgRect, 3.0, 3.0);

    painter.end();

    /*


    % Anschlusslinie zum Netzverknüpfungspunkt
    plot([x (x-x_offset) (x-x_offset)], [y (y-y_offset) (y-2*y_offset)],...
        '',...
        'Color', LineColor, 'LineStyle', LineStyle, 'LineWidth', 0.5 + abs(p_norm));

    % Box für Bargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
        '',...
        'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 12);
    % Stellgrößenbargraph
    plot([(x-x_offset + 0.5) (x-x_offset + 0.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + abs(p_norm)*1.0)],...
        '',...
        'Color', LineColor, 'LineStyle', '-', 'LineWidth', 8);

    if (typ == "Speicher")
        % Box für Batteriesymbol
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 24);
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 1.0)],...
            '',...
            'Color', [.6 .6 .6], 'LineStyle', '-', 'LineWidth', 12);
        % Füllstand Batterie
        plot([(x-x_offset + 1.5) (x-x_offset + 1.5)], [(y-2*y_offset - 1.2) (y-2*y_offset - 1.2 + 0.9*Kraftwerk.b_N)],...
            '',...
            'Color', [.2 .2 1], 'LineStyle', '-', 'LineWidth', 20);
    end

    % Text des Kraftwerks
    if (P > 10000)
        Nennleistungstext = sprintf("%8.0f MW", P / 1000);
    else
        Nennleistungstext = sprintf("%8.0f kW", P);
    end

    if (abs(p) > 10000)
        Istleistungstext = sprintf("%8.0f MW", p / 1000);
    else
        Istleistungstext = sprintf("%8.0f kW", p);
    end

    Kraftwerkstext = sprintf("%s %03i\np=%s\nP=%s", typ, n, Istleistungstext, Nennleistungstext);
    text(x - x_offset ,y - 2*y_offset, Kraftwerkstext,...
        'FontSize',10, 'Rotation', 90,...
        'HorizontalAlignment', 'Right',...
        'VerticalAlignment', 'bottom',...
        'FontName', 'FixedWidth');


    */
}

void Netzberechnung::paintLeitung(QPaintDevice *paintDevice, Leitung *leitung)
{
    qreal lineWidth;
    QColor lineColor_lineOK(int(255*0.1), int(255*0.2), int(255*1.0));
    QColor lineColor_lineNotOK(int(255*1.0), int(255*0.4), int(255*0.4));

    Knoten* startKnoten = sucheKnotenIndex(leitung->Startknoten());
    Knoten* endKnoten = sucheKnotenIndex(leitung->Endknoten());
    lineWidth = qAbs(leitung->p_L) + 0.5;
    qreal power = qAbs(leitung->Leistung_aktuell());

    QPainter painter;
    painter.begin(paintDevice);
    painter.setRenderHint(QPainter::Antialiasing);

    QBrush brush;
    QPen pen;

    brush.setColor(QColor(0, 0, 0, 0));
    brush.setStyle(Qt::SolidPattern);
    pen.setWidthF(lineWidth);

    if (leitung->gestoert())
        pen.setColor(lineColor_lineNotOK);
    else
        pen.setColor(lineColor_lineOK);

    painter.setBrush(brush);
    painter.setPen(pen);

    QPointF startPoint = QPointF(startKnoten->Long_K, this->height() / 20.0 - startKnoten->Lat_K) * 20.0;
    QPointF endPoint = QPointF(endKnoten->Long_K, this->height() / 20.0 - endKnoten->Lat_K) * 20.0;
    painter.drawLine(startPoint, endPoint);

    pen.setColor(Qt::black);
    QRectF textRect;
    textRect.setWidth(150.0);
    textRect.setHeight(15.0);
    textRect.moveCenter((startPoint + endPoint) / 2.0);

    QString text;
    if (power < 10000.0)
        text.sprintf("L%i: %.0lf kW", leitung->L, power);
    else
        text.sprintf("L%i: %8.0lf MW", leitung->L, power / 1000.0);

    painter.drawText(textRect, Qt::AlignCenter, text);

    painter.end();
}

void Netzberechnung::paintKnoten(QPaintDevice *paintDevice, Knoten *knoten)
{
    QPainter painter;
    painter.begin(paintDevice);
    painter.setRenderHint(QPainter::Antialiasing);

    QBrush brush;
    QPen pen;

    brush.setColor(QColor(int(255*0.2), int(255*0.7), int(255*0.6), 255));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(QColor(0, 0, 0, 255));

    painter.setBrush(brush);
    painter.setPen(pen);

    QPointF point = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    painter.drawEllipse(point, 4.0, 4.0);

    QString text;
    text.sprintf("K%i", knoten->K);
    painter.drawText(point + QPointF(10.0, 0.0), text);

    painter.end();
}
