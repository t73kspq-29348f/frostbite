#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QNetworkProxy>
#include <QDebug>

#include <mainwindow.h>
#include <windowfacade.h>
#include <clientsettings.h>
#include <eauthservice.h>
#include <xmlparserthread.h>
#include <debuglogger.h>

#include <environment.h>

class MainWindow;
class WindowFacade;
class ClientSettings;
class EAuthService;
class XmlParserThread;
class DebugLogger;

class TcpClient : public QObject {
    Q_OBJECT

public:
    TcpClient(QObject *parent = 0);
    ~TcpClient();

    void writeCommand(QString);
    void showError(QString);
    void updateSettings();
    void disconnectFromServer();    

private:
    MainWindow *mainWindow;
    QTcpSocket *tcpSocket;
    QByteArray buffer;
    WindowFacade *windowFacade;
    ClientSettings *settings;
    EAuthService *eAuth;
    QString sessionKey;
    XmlParserThread* xmlParserThread;
    DebugLogger* debugLogger;

    void loadMockData();

signals:
    void characterFound(QString, QString);
    void retrieveSessionKey(QString);
    void eAuthGameSelected(QString);
    void sessionRetrieved(QString, QString, QString);
    void eAuthError(QString);
    void addToQueue(QByteArray);
    void updateHighlighterSettings();
    void resetPassword();
    void enableGameSelect();

public slots:
    void setProxy(bool, QString, QString);
    void socketReadyRead();
    void socketError(QAbstractSocket::SocketError);
    void connectToHost(QString, QString, QString);
    void disconnectedFromHost();
    void initEauthSession(QString, QString, QString, QString);
    void selectGame();
    void gameSelected(QString);
    void resetEauthSession();
    void addCharacter(QString, QString);
    void retrieveEauthSession(QString);
    void eAuthSessionRetrieved(QString, QString, QString);
    void connectWizardError(QString);
    void authError();
    void writeSettings();
};


#endif // TCPCLIENT_H
