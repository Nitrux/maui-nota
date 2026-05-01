#include <QCommandLineParser>
#include <QIcon>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include <KLocalizedString>

#include <MauiKit4/Core/mauiapp.h>
#include <MauiKit4/TextEditor/moduleinfo.h>

#include "../nota_version.h"

// Models
#include "models/historymodel.h"

#include "controllers/server.h"

#define NOTA_URI "org.maui.nota"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    app.setOrganizationName(QStringLiteral("Maui"));
    app.setWindowIcon(QIcon(":/img/nota.svg"));

    KLocalizedString::setApplicationDomain("nota");

    KAboutData about(QStringLiteral("nota"),
                     QStringLiteral("Nota"),
                     NOTA_VERSION_STRING,
                     i18n("Browse, create and edit text files."),
                     KAboutLicense::LGPL_V3,
                     APP_COPYRIGHT_NOTICE,
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.addAuthor(QStringLiteral("Anupam Basak"), i18n("Developer"), QStringLiteral("anupam.basak27@gmail.com"));
    about.setHomepage("https://mauikit.org");
    about.setProductName("maui/nota");
    about.setBugAddress("https://invent.kde.org/maui/nota/-/issues");
    about.setOrganizationDomain(NOTA_URI);
    about.setProgramLogo(app.windowIcon());

    const auto FBData = MauiKitTextEditor::aboutData();
    about.addComponent(FBData.name(), MauiKitTextEditor::buildVersion(), FBData.version(), FBData.webAddress());

    KAboutData::setApplicationData(about);
    MauiApp::instance()->setIconName("qrc:/img/nota.svg");

    QCommandLineParser parser;

    about.setupCommandLine(&parser);
    parser.process(app);

    about.processCommandLine(&parser);
    const QStringList args = parser.positionalArguments();
    QStringList paths;

    if (!args.isEmpty())
    {
        for(const auto &path : args)
            paths << QUrl::fromUserInput(path).toString();
    }

    if (AppInstance::attachToExistingInstance(QUrl::fromStringList(paths), false))
    {
        // Successfully attached to existing instance of Nota
        return 0;
    }

    AppInstance::registerService();

    auto server = std::make_unique<Server>();

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/app/maui/nota/main.qml"));
    QObject::connect(
                &engine,
                &QQmlApplicationEngine::objectCreated,
                &app,
                [url, args, &server](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);

        server->setQmlObject(obj);
        if (!args.isEmpty())
            server->openFiles(args, false);

    },
    Qt::QueuedConnection);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    qmlRegisterSingletonInstance<Server>(NOTA_URI, 1, 0, "Server", server.get());
    qmlRegisterType<HistoryModel>(NOTA_URI, 1, 0, "History");

    engine.load(url);

    return app.exec();
}
