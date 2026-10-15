#pragma once
#include <QQuickFramebufferObject>
#include <mpv/render_gl.h>
class PlaybackController;
class MpvVideoItem : public QQuickFramebufferObject {
  Q_OBJECT
  Q_PROPERTY(QObject* controller READ controller WRITE setController NOTIFY controllerChanged)
public:
  explicit MpvVideoItem(QQuickItem *parent = nullptr);
  Renderer *createRenderer() const override;
  QObject *controller() const { return controller_; }
  void setController(QObject *controller);
signals:
  void controllerChanged();
private:
  QObject *controller_ = nullptr;
};
