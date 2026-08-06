#pragma once

#include <QObject>
#include <QLocalSocket>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QString>
#include <qqmlintegration.h>

class GreetdClient : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool authenticating READ isAuthenticating NOTIFY authenticatingChanged)
    Q_PROPERTY(bool testMode READ isTestMode NOTIFY testModeChanged)
    Q_PROPERTY(QString authPrompt READ authPrompt NOTIFY authPromptChanged)
    Q_PROPERTY(QString authMessageType READ authMessageType NOTIFY authMessageTypeChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool authFailed READ isAuthFailed NOTIFY authFailedChanged)
    Q_PROPERTY(bool authSuccess READ isAuthSuccess NOTIFY authSuccessChanged)

public:
    explicit GreetdClient(QObject *parent = nullptr);
    ~GreetdClient() override;

    bool isConnected() const { return m_connected; }
    bool isAuthenticating() const { return m_authenticating; }
    bool isTestMode() const { return m_testMode; }
    QString authPrompt() const { return m_authPrompt; }
    QString authMessageType() const { return m_authMessageType; }
    QString errorMessage() const { return m_errorMessage; }
    bool isAuthFailed() const { return m_authFailed; }
    bool isAuthSuccess() const { return m_authSuccess; }

    Q_INVOKABLE void connectToGreetd();
    Q_INVOKABLE void createSession(const QString &username);
    Q_INVOKABLE void respondAuth(const QString &response);
    Q_INVOKABLE void startSession(const QString &command);
    Q_INVOKABLE void cancelSession();
    Q_INVOKABLE void loginTestMode(const QString &username, const QString &password, const QString &command);

signals:
    void connectedChanged();
    void authenticatingChanged();
    void testModeChanged();
    void authPromptChanged();
    void authMessageTypeChanged();
    void errorMessageChanged();
    void authFailedChanged();
    void authSuccessChanged();
    void sessionStarted();

private slots:
    void onSocketReadyRead();
    void onSocketError(QLocalSocket::LocalSocketError socketError);

private:
    void sendJson(const QJsonObject &json);
    void handleMessage(const QJsonObject &json);

    QLocalSocket *m_socket{nullptr};
    QByteArray m_buffer;

    bool m_connected{false};
    bool m_authenticating{false};
    bool m_testMode{false};
    bool m_authFailed{false};
    bool m_authSuccess{false};

    QString m_authPrompt;
    QString m_authMessageType;
    QString m_errorMessage;
    QString m_pendingUser;
    QString m_pendingCommand;
};
