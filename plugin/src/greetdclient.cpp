#include "greetdclient.hpp"
#include <QCoreApplication>
#include <QProcessEnvironment>
#include <QDebug>
#include <QtEndian>

GreetdClient::GreetdClient(QObject *parent)
    : QObject(parent), m_socket(new QLocalSocket(this))
{
    connect(m_socket, &QLocalSocket::readyRead, this, &GreetdClient::onSocketReadyRead);
    connect(m_socket, &QLocalSocket::errorOccurred, this, &GreetdClient::onSocketError);

    connectToGreetd();
}

GreetdClient::~GreetdClient()
{
    if (m_socket && m_socket->isOpen()) {
        m_socket->close();
    }
}

void GreetdClient::connectToGreetd()
{
    const QString sockPath = QProcessEnvironment::systemEnvironment().value(QStringLiteral("GREETD_SOCK"));
    if (sockPath.isEmpty()) {
        qWarning() << "[CaelestiaGreeter] $GREETD_SOCK not found in environment. Enabling Test Mode.";
        m_testMode = true;
        emit testModeChanged();
        m_connected = true;
        emit connectedChanged();
        return;
    }

    m_testMode = false;
    emit testModeChanged();

    m_socket->connectToServer(sockPath);
    if (m_socket->waitForConnected(2000)) {
        m_connected = true;
        emit connectedChanged();
        qDebug() << "[CaelestiaGreeter] Successfully connected to greetd socket:" << sockPath;
    } else {
        qWarning() << "[CaelestiaGreeter] Failed to connect to greetd socket:" << m_socket->errorString() << ". Falling back to Test Mode.";
        m_testMode = true;
        emit testModeChanged();
        m_connected = true;
        emit connectedChanged();
    }
}

void GreetdClient::sendJson(const QJsonObject &json)
{
    if (m_testMode) {
        qDebug() << "[CaelestiaGreeter] [TestMode] Outgoing JSON:" << json;
        return;
    }

    if (!m_socket || m_socket->state() != QLocalSocket::ConnectedState) {
        qWarning() << "[CaelestiaGreeter] Cannot send JSON: Socket is not connected.";
        return;
    }

    const QByteArray jsonData = QJsonDocument(json).toJson(QJsonDocument::Compact);
    quint32 len = static_cast<quint32>(jsonData.size());

    // Native byte order length prefix as per greetd spec
    QByteArray packet;
    packet.append(reinterpret_cast<const char*>(&len), sizeof(len));
    packet.append(jsonData);

    m_socket->write(packet);
    m_socket->flush();
}

void GreetdClient::createSession(const QString &username)
{
    m_pendingUser = username;
    m_errorMessage.clear();
    emit errorMessageChanged();
    m_authFailed = false;
    emit authFailedChanged();
    m_authSuccess = false;
    emit authSuccessChanged();
    m_authenticating = true;
    emit authenticatingChanged();

    if (m_testMode) {
        qDebug() << "[CaelestiaGreeter] [TestMode] Created session for user:" << username;
        m_authPrompt = QStringLiteral("Password: ");
        m_authMessageType = QStringLiteral("secret");
        emit authPromptChanged();
        emit authMessageTypeChanged();
        return;
    }

    QJsonObject req;
    req[QStringLiteral("type")] = QStringLiteral("create_session");
    req[QStringLiteral("username")] = username;
    sendJson(req);
}

void GreetdClient::respondAuth(const QString &response)
{
    if (m_testMode) {
        qDebug() << "[CaelestiaGreeter] [TestMode] Responded to auth prompt with length:" << response.length();
        if (response.isEmpty()) {
            m_authFailed = true;
            emit authFailedChanged();
            m_errorMessage = QStringLiteral("Authentication failed (Empty password)");
            emit errorMessageChanged();
            m_authenticating = false;
            emit authenticatingChanged();
        } else {
            m_authSuccess = true;
            emit authSuccessChanged();
            m_authenticating = false;
            emit authenticatingChanged();
            qDebug() << "[CaelestiaGreeter] [TestMode] Auth Success! Ready to start session.";
        }
        return;
    }

    QJsonObject req;
    req[QStringLiteral("type")] = QStringLiteral("post_auth_message_response");
    if (!response.isNull()) {
        req[QStringLiteral("response")] = response;
    }
    sendJson(req);
}

void GreetdClient::startSession(const QString &command)
{
    m_pendingCommand = command;

    if (m_testMode) {
        qDebug() << "[CaelestiaGreeter] [TestMode] Starting session with command:" << command;
        emit sessionStarted();
        return;
    }

    QJsonObject req;
    req[QStringLiteral("type")] = QStringLiteral("start_session");

    QJsonArray cmdArray;
    const QStringList tokens = command.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    for (const QString &tok : tokens) {
        cmdArray.append(tok);
    }
    req[QStringLiteral("cmd")] = cmdArray;
    req[QStringLiteral("env")] = QJsonArray();

    sendJson(req);
}

void GreetdClient::cancelSession()
{
    m_authenticating = false;
    emit authenticatingChanged();
    m_authPrompt.clear();
    emit authPromptChanged();
    m_errorMessage.clear();
    emit errorMessageChanged();

    if (m_testMode) {
        qDebug() << "[CaelestiaGreeter] [TestMode] Cancelled session";
        return;
    }

    QJsonObject req;
    req[QStringLiteral("type")] = QStringLiteral("cancel_session");
    sendJson(req);
}

void GreetdClient::loginTestMode(const QString &username, const QString &password, const QString &command)
{
    createSession(username);
    respondAuth(password);
    if (m_authSuccess) {
        startSession(command);
    }
}

void GreetdClient::onSocketReadyRead()
{
    m_buffer.append(m_socket->readAll());

    while (m_buffer.size() >= static_cast<int>(sizeof(quint32))) {
        quint32 payloadLen = 0;
        std::memcpy(&payloadLen, m_buffer.constData(), sizeof(quint32));

        if (m_buffer.size() < static_cast<int>(sizeof(quint32) + payloadLen)) {
            break; // Wait for full packet
        }

        const QByteArray payload = m_buffer.mid(sizeof(quint32), payloadLen);
        m_buffer.remove(0, sizeof(quint32) + payloadLen);

        QJsonParseError parseErr;
        QJsonDocument doc = QJsonDocument::fromJson(payload, &parseErr);
        if (parseErr.error == QJsonParseError::NoError && doc.isObject()) {
            handleMessage(doc.object());
        } else {
            qWarning() << "[CaelestiaGreeter] JSON Parse error:" << parseErr.errorString();
        }
    }
}

void GreetdClient::onSocketError(QLocalSocket::LocalSocketError socketError)
{
    qWarning() << "[CaelestiaGreeter] Socket Error:" << socketError << m_socket->errorString();
}

void GreetdClient::handleMessage(const QJsonObject &json)
{
    const QString type = json.value(QStringLiteral("type")).toString();

    if (type == QStringLiteral("success")) {
        qDebug() << "[CaelestiaGreeter] Received success response from greetd";
        if (m_authenticating && !m_authSuccess) {
            // Authentication succeeded
            m_authSuccess = true;
            emit authSuccessChanged();
            m_authenticating = false;
            emit authenticatingChanged();

            if (!m_pendingCommand.isEmpty()) {
                startSession(m_pendingCommand);
            }
        } else {
            emit sessionStarted();
        }
    } else if (type == QStringLiteral("auth_message")) {
        m_authMessageType = json.value(QStringLiteral("auth_message_type")).toString();
        m_authPrompt = json.value(QStringLiteral("auth_message")).toString();
        emit authMessageTypeChanged();
        emit authPromptChanged();
        qDebug() << "[CaelestiaGreeter] Auth Prompt received:" << m_authPrompt << "Type:" << m_authMessageType;
    } else if (type == QStringLiteral("error")) {
        const QString errDesc = json.value(QStringLiteral("description")).toString();
        const QString errType = json.value(QStringLiteral("error_type")).toString();
        qWarning() << "[CaelestiaGreeter] Error from greetd:" << errType << errDesc;

        m_errorMessage = errDesc.isEmpty() ? QStringLiteral("Authentication failed") : errDesc;
        emit errorMessageChanged();
        m_authFailed = true;
        emit authFailedChanged();
        m_authenticating = false;
        emit authenticatingChanged();
    }
}
