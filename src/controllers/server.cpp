#include "server.h"

#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QMimeDatabase>
#include <QQuickWindow>
#include <QQmlApplicationEngine>

#include "notainterface.h"
#include "notaadaptor.h"

namespace
{
bool isKnownTextMime(const QString &mimeName)
{
    if (mimeName.startsWith(QLatin1String("text/"))) {
        return true;
    }

    static const QStringList textualApplicationMimes = {
        QStringLiteral("application/xml"),
        QStringLiteral("application/yaml"),
        QStringLiteral("application/javascript"),
        QStringLiteral("application/json"),
        QStringLiteral("application/pgp-keys"),
        QStringLiteral("application/x-cmakecache"),
        QStringLiteral("application/x-gitignore"),
        QStringLiteral("application/x-kdevelop"),
        QStringLiteral("application/x-kicad-project"),
        QStringLiteral("application/x-perl"),
        QStringLiteral("application/x-shellscript"),
        QStringLiteral("application/x-yaml"),
        QStringLiteral("application/vnd.kde.knotificationrc")
    };

    return textualApplicationMimes.contains(mimeName);
}

bool hasLikelyTextContent(const QString &localPath)
{
    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }

    const QByteArray data = file.read(8192);
    if (data.isEmpty()) {
        return true;
    }

    int suspiciousBytes = 0;
    for (const auto value : data) {
        const unsigned char c = static_cast<unsigned char>(value);
        if (c == '\0') {
            return false;
        }

        // Treat uncommon control bytes as suspicious binary content.
        if ((c < 0x09) || (c > 0x0D && c < 0x20)) {
            ++suspiciousBytes;
        }
    }

    return suspiciousBytes * 100 <= data.size() * 30;
}

bool isAmbiguousMime(const QString &mimeName)
{
    return mimeName.isEmpty()
            || mimeName == QLatin1String("application/octet-stream")
            || mimeName == QLatin1String("application/x-zerosize")
            || mimeName == QLatin1String("inode/x-empty");
}

bool shouldAcceptUrl(const QUrl &url, const QMimeDatabase &mimeDb, QString *mimeNameOut = nullptr)
{
    if (!url.isValid()) {
        return false;
    }

    const auto mimeName = mimeDb.mimeTypeForUrl(url).name();
    if (mimeNameOut) {
        *mimeNameOut = mimeName;
    }

    if (isKnownTextMime(mimeName)) {
        return true;
    }

    if (!url.isLocalFile()) {
        return false;
    }

    const QFileInfo info(url.toLocalFile());
    if (!info.exists() || !info.isFile()) {
        return false;
    }

    return isAmbiguousMime(mimeName) && hasLikelyTextContent(info.absoluteFilePath());
}
}

QVector<QPair<QSharedPointer<OrgKdeNotaActionsInterface>, QStringList>> AppInstance::appInstances(const QString& preferredService)
{
    QVector<QPair<QSharedPointer<OrgKdeNotaActionsInterface>, QStringList>> dolphinInterfaces;

    if (!preferredService.isEmpty())
    {
        QSharedPointer<OrgKdeNotaActionsInterface> preferredInterface(
                    new OrgKdeNotaActionsInterface(preferredService,
                                                   QStringLiteral("/Actions"),
                                                   QDBusConnection::sessionBus()));

        qDebug() << "IS PREFRFRED INTERFACE VALID?" << preferredInterface->isValid() << preferredInterface->lastError().message();
        if (preferredInterface->isValid() && !preferredInterface->lastError().isValid()) {
            dolphinInterfaces.append(qMakePair(preferredInterface, QStringList()));
        }
    }

    // Look for dolphin instances among all available dbus services.
    QDBusConnectionInterface *sessionInterface = QDBusConnection::sessionBus().interface();
    const QStringList dbusServices = sessionInterface ? sessionInterface->registeredServiceNames().value() : QStringList();
    // Don't match the service without trailing "-" (unique instance)
    const QString pattern = QStringLiteral("org.kde.nota-");

    // Don't match the pid without leading "-"
    const QString myPid = QLatin1Char('-') + QString::number(QCoreApplication::applicationPid());

    for (const QString& service : dbusServices)
    {
        if (service.startsWith(pattern) && !service.endsWith(myPid))
        {
            qDebug() << "EXISTING INTANCES" << service;

            // Check if instance can handle our URLs
            QSharedPointer<OrgKdeNotaActionsInterface> interface(
                        new OrgKdeNotaActionsInterface(service,
                                                       QStringLiteral("/Actions"),
                                                       QDBusConnection::sessionBus()));
            if (interface->isValid() && !interface->lastError().isValid())
            {
                dolphinInterfaces.append(qMakePair(interface, QStringList()));
            }
        }
    }

    return dolphinInterfaces;
}

bool AppInstance::attachToExistingInstance(const QList<QUrl>& inputUrls, bool splitView, const QString& preferredService)
{
    bool attached = false;

    if (inputUrls.isEmpty())
    {
        return false;
    }

    auto dolphinInterfaces = appInstances(preferredService);
    if (dolphinInterfaces.isEmpty())
    {
        return false;
    }

    QStringList newUrls;

    // check to see if any instances already have any of the given URLs open
    const auto urls = QUrl::toStringList(inputUrls);
    for (const QString& url : urls)
    {
        bool urlFound = false;

        for (auto& interface: dolphinInterfaces)
        {
            auto isUrlOpenReply = interface.first->isUrlOpen(url);
            isUrlOpenReply.waitForFinished();

            if (!isUrlOpenReply.isError() && isUrlOpenReply.value())
            {
                interface.second.append(url);
                urlFound = true;
                break;
            }
        }

        if (!urlFound)
        {
            newUrls.append(url);
        }
    }

    if(newUrls.isEmpty())
    {
        auto interface = dolphinInterfaces.first();
        auto reply = interface.first->focusFile(urls.first());
        reply.waitForFinished();

        if (!reply.isError())
        {
            interface.first->activateWindow();
        }

        return true;
    }

    for (const auto& interface: std::as_const(dolphinInterfaces))
    {
        auto reply = interface.first->openFiles(newUrls, splitView);
        reply.waitForFinished();

        if (!reply.isError())
        {
            interface.first->activateWindow();
            attached = true;
            break;
        }
    }

    return attached;
}

bool AppInstance::registerService()
{
    QDBusConnectionInterface *iface = QDBusConnection::sessionBus().interface();

    auto registration = iface->registerService(QStringLiteral("org.kde.nota-%1").arg(QCoreApplication::applicationPid()),
                                               QDBusConnectionInterface::ReplaceExistingService,
                                               QDBusConnectionInterface::DontAllowReplacement);

    if (!registration.isValid())
    {
        qWarning("2 Failed to register D-Bus service \"%s\" on session bus: \"%s\"",
                 qPrintable("org.kde.nota"),
                 qPrintable(registration.error().message()));
        return false;
    }

    return true;
}


Server::Server(QObject *parent) : QObject(parent)
  , m_qmlObject(nullptr)
{
    new ActionsAdaptor(this);
    if(!QDBusConnection::sessionBus().registerObject(QStringLiteral("/Actions"), this))
    {
        qDebug() << "FAILED TO REGISTER BACKGROUND DBUS OBJECT";
        return;
    }
}

void Server::setQmlObject(QObject *object)
{
    if(!m_qmlObject)
    {
        m_qmlObject = object;
    }
}

void Server::activateWindow()
{
    if(m_qmlObject)
    {
        qDebug() << "ACTIVET WINDOW FROM C++";
        auto window = qobject_cast<QQuickWindow *>(m_qmlObject);
        if (window)
        {
            qDebug() << "Trying to raise wndow";
            window->raise();
            window->requestActivate();
        }
    }
}

void Server::quit()
{
    QCoreApplication::quit();
}

void Server::openFiles(const QStringList &urls, bool)
{
    auto files = filterFiles(urls);

    if(m_qmlObject)
    {
        if(files.isEmpty())
        {
            openEmptyTab();
        }else
        {
            QMetaObject::invokeMethod(m_qmlObject, "openFiles",
                                      Q_ARG(QVariant, files));
        }

    }
}

void Server::openNewTab(const QString &url)
{
    if(m_qmlObject)
    {
        QMetaObject::invokeMethod(m_qmlObject, "openFile",
                                  Q_ARG(QString, url));
    }
}

void Server::openEmptyTab()
{
    if(m_qmlObject)
    {
        QMetaObject::invokeMethod(m_qmlObject, "openTab");
    }
}

void Server::focusFile(const QString &url)
{
    if(m_qmlObject)
    {
        QMetaObject::invokeMethod(m_qmlObject, "focusFile",
                                  Q_ARG(QString, url));
    }
}

void Server::openNewTabAndActivate(const QString &url)
{
    if(m_qmlObject)
    {
        QMetaObject::invokeMethod(m_qmlObject, "openFile",
                                  Q_ARG(QString, url));
        this->activateWindow();
    }
}

void Server::openNewWindow(const QString &)
{

}

bool Server::isUrlOpen(const QString &url)
{
    bool value = false;

    if(m_qmlObject)
    {
        QMetaObject::invokeMethod(m_qmlObject, "isUrlOpen",
                                  Q_RETURN_ARG(bool, value),
                                  Q_ARG(QString, url));
    }
    return value;
}

QStringList Server::filterFiles(const QStringList &urls)
{
    qDebug() << "REQUEST FILES" << urls;
    QStringList res;
    const QMimeDatabase mimeDb;

    for (const auto &url : urls) {
        const auto url_ = QUrl::fromUserInput(url);
        QString mimeName;
        const bool accepted = shouldAcceptUrl(url_, mimeDb, &mimeName);
        qDebug() << "REQUEST FILES" << url_.toString() << mimeName;

        if (accepted) {
            res << url_.toString();
        }
    }

    qDebug() << "REQUEST FILES" << res;

    return res;
}

bool Server::shouldOpenFile(const QString &url)
{
    const QMimeDatabase mimeDb;
    return shouldAcceptUrl(QUrl::fromUserInput(url), mimeDb);
}

QStringList Server::filterOpenableFiles(const QStringList &urls)
{
    return filterFiles(urls);
}
