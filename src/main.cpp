#include "player/PlaybackController.h"
#include "player/MpvVideoItem.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QDebug>
#include <exception>
int main(int argc, char *argv[]) {
  QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
  QGuiApplication app(argc, argv);
  QGuiApplication::setApplicationName("Jatayu Media Player");
  QGuiApplication::setOrganizationName("Jatayu");
  try {
    PlaybackController player;
    qmlRegisterType<MpvVideoItem>("Jatayu.Backend", 1, 0, "MpvVideoItem");
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("player", &player);
    engine.loadFromModule("JatayuMediaPlayer", "Main");
    if (engine.rootObjects().isEmpty()) return 2;
    if (argc > 1) player.openFile(QString::fromLocal8Bit(argv[1]));
    return app.exec();
  } catch (const std::exception &e) {
    qCritical() << "Unable to start player:" << e.what();
    return 1;
  }
}
