#pragma once
#include <QObject>
#include <QString>
#include <QVariantList>
#include <mpv/client.h>
class PlaybackController : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
  Q_PROPERTY(double position READ position NOTIFY positionChanged)
  Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(QString title READ title NOTIFY titleChanged)
  Q_PROPERTY(QString error READ error NOTIFY errorChanged)
public:
  explicit PlaybackController(QObject *parent = nullptr);
  ~PlaybackController() override;
  mpv_handle *handle() const { return handle_; }
  bool paused() const { return paused_; }
  double position() const { return position_; }
  double duration() const { return duration_; }
  double volume() const { return volume_; }
  QString title() const { return title_; }
  QString error() const { return error_; }
  Q_INVOKABLE void openFile(const QString &path);
  Q_INVOKABLE QVariantList searchMedia(const QString &query) const;
  Q_INVOKABLE void togglePause();
  Q_INVOKABLE void stop();
  Q_INVOKABLE void seek(double seconds);
  Q_INVOKABLE void setVolume(double value);
  Q_INVOKABLE void setPaused(bool value);
  Q_INVOKABLE void openSubtitle(const QString &path);
  Q_INVOKABLE void seekRelative(double seconds);
  Q_INVOKABLE void processEvents();
signals:
  void pausedChanged();
  void positionChanged();
  void durationChanged();
  void volumeChanged();
  void titleChanged();
  void errorChanged();
  void engineEvent();
private:
  static void wakeup(void *ctx);
  void setError(QString message);
  mpv_handle *handle_ = nullptr;
  bool paused_ = true;
  double position_ = 0, duration_ = 0, volume_ = 70;
  QString title_ = "No media selected", error_;
};
