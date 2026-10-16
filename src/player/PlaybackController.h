#pragma once
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QProcess>
#include <mpv/client.h>
class PlaybackController : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
  Q_PROPERTY(double position READ position NOTIFY positionChanged)
  Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(double playbackSpeed READ playbackSpeed NOTIFY playbackSpeedChanged)
  Q_PROPERTY(QVariantList audioTracks READ audioTracks NOTIFY audioTracksChanged)
  Q_PROPERTY(int selectedAudioTrack READ selectedAudioTrack NOTIFY audioTracksChanged)
  Q_PROPERTY(QString title READ title NOTIFY titleChanged)
  Q_PROPERTY(QString songTitle READ songTitle NOTIFY metadataChanged)
  Q_PROPERTY(QString artist READ artist NOTIFY metadataChanged)
  Q_PROPERTY(QString album READ album NOTIFY metadataChanged)
  Q_PROPERTY(QString artworkUrl READ artworkUrl NOTIFY metadataChanged)
  Q_PROPERTY(QString error READ error NOTIFY errorChanged)
  Q_PROPERTY(QString qualityProfile READ qualityProfile NOTIFY qualityProfileChanged)
public:
  explicit PlaybackController(QObject *parent = nullptr);
  ~PlaybackController() override;
  mpv_handle *handle() const { return handle_; }
  bool paused() const { return paused_; }
  double position() const { return position_; }
  double duration() const { return duration_; }
  double volume() const { return volume_; }
  double playbackSpeed() const { return playbackSpeed_; }
  QVariantList audioTracks() const { return audioTracks_; }
  int selectedAudioTrack() const { return selectedAudioTrack_; }
  QString title() const { return title_; }
  QString songTitle() const { return songTitle_; }
  QString artist() const { return artist_; }
  QString album() const { return album_; }
  QString artworkUrl() const { return artworkUrl_; }
  QString error() const { return error_; }
  QString qualityProfile() const { return qualityProfile_; }
  Q_INVOKABLE void setQualityProfile(const QString &profile);
  Q_INVOKABLE void openFile(const QString &path);
  Q_INVOKABLE void saveMusicTags(const QString &title, const QString &artist, const QString &album, const QString &coverPath = QString(), const QString &outputName = QString());
  Q_INVOKABLE QString locationPath(const QString &name) const;
  Q_INVOKABLE QVariantList browseFolder(const QString &path, const QString &filter) const;
  Q_INVOKABLE QVariantList recentMedia() const;
  Q_INVOKABLE QVariantList searchMedia(const QString &query) const;
  Q_INVOKABLE void togglePause();
  Q_INVOKABLE void stop();
  Q_INVOKABLE void seek(double seconds);
  Q_INVOKABLE void setVolume(double value);
  Q_INVOKABLE void setPlaybackSpeed(double speed);
  Q_INVOKABLE void selectAudioTrack(int id);
  Q_INVOKABLE void setPaused(bool value);
  Q_INVOKABLE void openSubtitle(const QString &path);
  Q_INVOKABLE void setSubtitleDelay(double seconds);
  Q_INVOKABLE void setSubtitleSize(int size);
  Q_INVOKABLE void cycleSubtitleTrack();
  Q_INVOKABLE QVariantList browseSubtitles(const QString &path) const;
  Q_INVOKABLE QVariantList browseCoverImages(const QString &path) const;
  Q_INVOKABLE QVariantList scanMusicLibrary(const QString &folder, const QString &filter) const;
  Q_INVOKABLE void inspectMusicTags(const QVariantList &songs);
  Q_INVOKABLE void seekRelative(double seconds);
  Q_INVOKABLE void processEvents();
signals:
  void pausedChanged();
  void positionChanged();
  void durationChanged();
  void volumeChanged();
  void playbackSpeedChanged();
  void audioTracksChanged();
  void titleChanged();
  void metadataChanged();
  void libraryTagFound(QString path, QString artist, QString album, QString title);
  void tagSaveFinished(bool success, QString message);
  void errorChanged();
  void engineEvent();
  void recentMediaChanged();
  void qualityProfileChanged();
  void playbackFinished();
private:
  static void wakeup(void *ctx);
  void setError(QString message);
  void loadLocalArtwork(const QString &path);
  void inspectNextMusicTag();
  mpv_handle *handle_ = nullptr;
  bool paused_ = true;
  double position_ = 0, duration_ = 0, volume_ = 70, playbackSpeed_ = 1;
  QVariantList audioTracks_;
  int selectedAudioTrack_ = -1;
  QString title_ = "No media selected", error_;
  QString qualityProfile_ = "Balanced";
  QString songTitle_, artist_, album_, artworkUrl_, currentFile_;
  QProcess *artworkProcess_ = nullptr;
  QProcess *libraryProbe_ = nullptr;
  QStringList pendingMusicFiles_;
};
