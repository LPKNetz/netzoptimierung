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
    QPainter painter;
    painter.begin(paintDevice);
    painter.setRenderHint(QPainter::Antialiasing);

    painter.translate(-400.0, 0.0);
    painter.scale(1.0, 1.0);

    foreach(Kraftwerk_Last_Speicher *kraftwerk, mKraftwerksliste)
    {
        paintKraftwerk(&painter, kraftwerk);
    }

    foreach(Leitung *leitung, mLeitungliste)
    {
        paintLeitung(&painter, leitung);
    }

    foreach(Knoten *knoten, mKnotenliste)
    {
        paintKnoten(&painter, knoten);
    }

    painter.end();
}

void Netzberechnung::paintKraftwerk(QPainter *painter, Kraftwerk_Last_Speicher *kraftwerk)
{
    QColor lineColor = QColor(int(255*0.4), int(255*0.2), int(255*0.1));
    if (kraftwerk->gestoert())
    {
        lineColor = QColor(int(255*1.0), int(255*0.4), int(255*0.4));
    }
    else if (kraftwerk->Leistung_aktuell() > 0.0)
    {
        lineColor = QColor(int(255*0.24), int(255*0.7), int(255*0.2));
    }
    else if (qAbs(kraftwerk->x_N) < 0.001)
    {
        lineColor = QColor(int(255*0.6), int(255*0.6), int(255*0.6));
    }

    qreal x_offset = 0.0;
    qreal y_offset = 0.5;

    if (kraftwerk->istSpeicher())
        x_offset = -5.0*1.5;
    else if (kraftwerk->x_Nmin < -0.0001)   // Last
        x_offset = -2*1.5;

    x_offset *= 20.0;   // Skalierung
    y_offset *= 20.0;   // Skalierung

    QBrush brush;
    QPen pen;

    brush.setColor(QColor(255, 255, 0, 100));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(lineColor);
    pen.setWidthF(qAbs(kraftwerk->x_N) + 0.5);

    painter->setBrush(brush);
    painter->setPen(pen);
    QFont font;
    font.setPointSizeF(6.0);
    painter->setFont(font);

    // Anschlusslinie zum Netzverknüpfungspunkt
    Knoten *knoten = sucheKnotenIndex(kraftwerk->K);
    QPointF posNVP = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    QPointF posKW = posNVP + QPointF(x_offset, y_offset);

    painter->drawLine(posNVP, posKW);

    QRectF bgRect;  // Background rect behind power plant
    bgRect.setWidth(50.0);
    if (kraftwerk->istSpeicher())
        bgRect.setHeight(55.0);
    else
        bgRect.setHeight(40.0);
    bgRect.moveTopRight(QPointF(0.0, -bgRect.height()/2.0));


    painter->save();
    painter->translate(posKW);
    painter->rotate(-90.0);



    QString kraftwerkstext;
    QString typ;
    QString Istleistungstext;
    QString Nennleistungstext;

    if (kraftwerk->istSpeicher())
        typ = "Speicher";
    else if (kraftwerk->x_Nmin < -0.0001)
        typ = "Last";
    else
        typ = "Kraftwerk";

    if (kraftwerk->P_N > 10000.0)
        Nennleistungstext.sprintf("%8.0f MW", kraftwerk->P_N / 1000.0);
    else
        Nennleistungstext.sprintf("%8.0f kW", kraftwerk->P_N);

    if (qAbs(kraftwerk->Leistung_aktuell()) > 10000.0)
        Istleistungstext.sprintf("%8.0f MW", kraftwerk->Leistung_aktuell() / 1000.0);
    else
        Istleistungstext.sprintf("%8.0f kW", kraftwerk->Leistung_aktuell());


    kraftwerkstext.sprintf("%s %03i\np=%s\nP=%s", typ.toUtf8().data(), kraftwerk->N, Istleistungstext.toUtf8().data(), Nennleistungstext.toUtf8().data());
    painter->drawRoundedRect(bgRect, 3.0, 3.0);

    painter->setPen(Qt::black);
    painter->drawText(bgRect.adjusted(2.0, 2.0, -2.0, -2.0), Qt::AlignHCenter | Qt::AlignTop, kraftwerkstext);

    brush.setColor(QColor(int(255*0.4), int(255*0.4), int(255*0.4)));
    painter->setBrush(brush);
    painter->setPen(Qt::NoPen);

    // Leistungsanzeige
    QRectF bargraph_bg;
    bargraph_bg.setWidth(40.0);
    bargraph_bg.setHeight(6.0);
    bargraph_bg.moveBottomLeft(bgRect.bottomLeft() + QPointF(2.0, -2.0));

    painter->drawRect(bargraph_bg);
    painter->setBrush(lineColor);
    QRectF bargraph = bargraph_bg.adjusted(1.0, 1.0, -1.0, -1.0);
    bargraph.setWidth(bargraph.width() * qAbs(kraftwerk->x_N));

    painter->drawRect(bargraph);

    // Bunkerfüllstandsanzeige
    if (kraftwerk->istSpeicher())
    {
        bargraph_bg.moveTop(bargraph_bg.top() - 18.0);
        bargraph_bg.adjust(0.0, 0.0, -5.0, 0.0);
        bargraph_bg.setHeight(14);
        painter->setBrush(brush);
        painter->drawRect(bargraph_bg);
        bargraph = bargraph_bg.adjusted(1.0, 1.0, -1.0, -1.0);
        painter->drawRect(bargraph_bg.adjusted(0.0, 4.0, 5.0, -4.0));

        painter->setBrush(QColor(int(255*0.2), int(255*0.2), int(255*1.0)));
        bargraph.setWidth(bargraph.width() * qAbs(kraftwerk->b_N));

        painter->drawRect(bargraph);
    }

    painter->restore();
}

void Netzberechnung::paintLeitung(QPainter *painter, Leitung *leitung)
{
    qreal lineWidth;
    QColor lineColor_lineOK(int(255*0.1), int(255*0.2), int(255*1.0));
    QColor lineColor_lineNotOK(int(255*1.0), int(255*0.4), int(255*0.4));

    Knoten* startKnoten = sucheKnotenIndex(leitung->Startknoten());
    Knoten* endKnoten = sucheKnotenIndex(leitung->Endknoten());
    lineWidth = qAbs(leitung->p_L) + 0.5;
    qreal power = qAbs(leitung->Leistung_aktuell());
    bool reversePower = (leitung->Leistung_aktuell() < 0.0);

    QBrush brush;
    QPen pen;
    QFont font;
    font.setPointSizeF(7.5);
    painter->setFont(font);

    brush.setColor(QColor(0, 0, 0, 0));
    brush.setStyle(Qt::SolidPattern);
    pen.setWidthF(lineWidth);

    if (leitung->gestoert())
        pen.setColor(lineColor_lineNotOK);
    else
        pen.setColor(lineColor_lineOK);

    painter->setBrush(brush);
    painter->setPen(pen);

    QPointF startPoint = QPointF(startKnoten->Long_K, this->height() / 20.0 - startKnoten->Lat_K) * 20.0;
    QPointF endPoint = QPointF(endKnoten->Long_K, this->height() / 20.0 - endKnoten->Lat_K) * 20.0;
    if (reversePower)
    {
        QPointF tmp = endPoint;
        endPoint = startPoint;
        startPoint = tmp;
    }
    painter->drawLine(startPoint, endPoint);

    // Leistungsflussrichtung mit Pfeil zeigen
    QPointF pfeilPoint = endPoint - 0.1 * (endPoint - startPoint);
    painter->save();
    painter->translate(pfeilPoint);
    painter->rotate(10);
    painter->drawLine(QPointF(0.0, 0.0), - 0.1 * (endPoint - startPoint));
    painter->rotate(-20);
    painter->drawLine(QPointF(0.0, 0.0), - 0.1 * (endPoint - startPoint));
    painter->restore();


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

    QRectF br;
    painter->drawText(textRect, Qt::AlignCenter, text, &br);
    painter->setBrush(QColor(170, 245, 200, 190));
    painter->setPen(Qt::NoPen);
    br.adjust(-2.0, -2.0, 2.0, 2.0);
    painter->drawRect(br);
    painter->setPen(Qt::blue);
    painter->drawText(textRect, Qt::AlignCenter, text);
}

void Netzberechnung::paintKnoten(QPainter *painter, Knoten *knoten)
{
    QBrush brush;
    QPen pen;

    brush.setColor(QColor(int(255*0.2), int(255*0.7), int(255*0.6), 255));
    brush.setStyle(Qt::SolidPattern);
    pen.setColor(QColor(0, 0, 0, 255));

    painter->setBrush(brush);
    painter->setPen(pen);

    QPointF point = QPointF(knoten->Long_K, this->height() / 20.0 - knoten->Lat_K) * 20.0;
    painter->drawEllipse(point, 4.0, 4.0);

    QString text;
    text.sprintf("K%i", knoten->K);
    painter->drawText(point + QPointF(10.0, 0.0), text);
}
