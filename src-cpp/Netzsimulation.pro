#-------------------------------------------------
#
# Project created by QtCreator 2019-08-24T22:25:41
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = Netzsimulation
TEMPLATE = app

# The following define makes your compiler emit warnings if you use
# any feature of Qt which has been marked as deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

CONFIG += c++11

SOURCES += \
        knoten.cpp \
        kraftwerk_last_speicher.cpp \
        leitung.cpp \
        logger.cpp \
        main.cpp \
        mainwindow.cpp \
        math/matrix.cpp \
        netzberechnung.cpp \
        trend.cpp

HEADERS += \
        knoten.h \
        kraftwerk_last_speicher.h \
        leitung.h \
        logger.h \
        mainwindow.h \
        math/matrix.h \
        netzberechnung.h \
        trend.h

FORMS += \
        mainwindow.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
