#include "PlaybackController.h"
#include <QFileInfo>
#include <QDir>
#include <QDirIterator>
#include <QStandardPaths>
#include <QSet>
#include <QVariantMap>
#include <QSettings>
#include <QFile>
#include <QMetaObject>
#include <QUrl>
#include <algorithm>
#include <stdexcept>
PlaybackController::PlaybackController(QObject *parent) : QObject(parent) {
  handle_ = mpv_create();
  if (!handle_) throw std::runtime_error("Cannot initialise libmpv");
  mpv_set_option_string(handle_, "vo", "libmpv");
  mpv_set_option_string(handle_, "hwdec", "auto-safe");
  mpv_set_option_string(handle_, "idle", "yes");
  if (mpv_initialize(handle_) < 0) {
    mpv_terminate_destroy(handle_); handle_ = nullptr;
    throw std::runtime_error("Cannot start libmpv");
  }
  mpv_observe_property(handle_, 1, "pause", MPV_FORMAT_FLAG);
  mpv_observe_property(handle_, 2, "time-pos", MPV_FORMAT_DOUBLE);
  mpv_observe_property(handle_, 3, "duration", MPV_FORMAT_DOUBLE);
  mpv_observe_property(handle_, 4, "volume", MPV_FORMAT_DOUBLE);
  mpv_set_wakeup_callback(handle_, &PlaybackController::wakeup, this);
  connect(this, &PlaybackController::engineEvent, this, &PlaybackController::processEvents, Qt::QueuedConnection);
  setVolume(70);
  const QString savedQuality = QSettings().value("videoQualityProfile", "Balanced").toString();
  setQualityProfile(savedQuality);
}
PlaybackController::~PlaybackController() {
  if (handle_) { mpv_set_wakeup_callback(handle_, nullptr, nullptr); mpv_terminate_destroy(handle_); }
}
void PlaybackController::wakeup(void *ctx) {
  auto *self = static_cast<PlaybackController *>(ctx);
  QMetaObject::invokeMethod(self, "processEvents", Qt::QueuedConnection);
}
void PlaybackController::setError(QString message) { if (error_ != message) { error_ = message; emit errorChanged(); } }
void PlaybackController::openFile(const QString &path) {
  QUrl url(path);
  QString localPath = url.isLocalFile() ? url.toLocalFile() : path;
  QFileInfo info(localPath);
  if (!info.isFile() || !info.isReadable()) { setError("File is unavailable or not readable"); return; }
  setError({});
  title_ = info.fileName(); emit titleChanged();
  QSettings settings;
  QStringList recent = settings.value("recentMedia").toStringList();
  recent.removeAll(info.absoluteFilePath());
  recent.prepend(info.absoluteFilePath());
  while (recent.size() > 20) recent.removeLast();
  settings.setValue("recentMedia", recent);
  emit recentMediaChanged();
  QByteArray bytes = QFile::encodeName(info.absoluteFilePath());
  const char *args[] = {"loadfile", bytes.constData(), "replace", nullptr};
  int result = mpv_command_async(handle_, 0, args);
  if (result < 0) setError(QString::fromUtf8(mpv_error_string(result)));
}
void PlaybackController::togglePause() { setPaused(!paused_); }
void PlaybackController::setPaused(bool paused) { int value = paused ? 1 : 0; mpv_set_property_async(handle_, 0, "pause", MPV_FORMAT_FLAG, &value); }
void PlaybackController::stop() { const char *args[] = {"stop", nullptr}; mpv_command_async(handle_, 0, args); }
void PlaybackController::seek(double seconds) {
  if (duration_ <= 0) return;
  QByteArray t = QByteArray::number(std::clamp(seconds, 0.0, duration_), 'f', 3);
  const char *args[] = {"seek", t.constData(), "absolute+exact", nullptr}; mpv_command_async(handle_, 0, args);
}
void PlaybackController::seekRelative(double seconds) { seek(position_ + seconds); }
void PlaybackController::setVolume(double value) { double v = std::clamp(value, 0.0, 100.0); mpv_set_property_async(handle_, 0, "volume", MPV_FORMAT_DOUBLE, &v); }
void PlaybackController::openSubtitle(const QString &path) {
  QUrl url(path); QString local = url.isLocalFile() ? url.toLocalFile() : path;
  if (!QFileInfo(local).isFile()) { setError("Subtitle file not found"); return; }
  QByteArray bytes = QFile::encodeName(local);
  const char *args[] = {"sub-add", bytes.constData(), "select", nullptr};
  mpv_command_async(handle_, 0, args);
}
void PlaybackController::processEvents() {
  if (!handle_) return;
  while (true) {
    mpv_event *event = mpv_wait_event(handle_, 0);
    if (event->event_id == MPV_EVENT_NONE) break;
    if (event->event_id == MPV_EVENT_PROPERTY_CHANGE) {
      auto *prop = static_cast<mpv_event_property *>(event->data);
      if (!prop->data) continue;
      switch (event->reply_userdata) {
        case 1: { bool x = *static_cast<int *>(prop->data); if (paused_ != x) { paused_ = x; emit pausedChanged(); } break; }
        case 2: { double x = *static_cast<double *>(prop->data); if (position_ != x) { position_ = x; emit positionChanged(); } break; }
        case 3: { double x = *static_cast<double *>(prop->data); if (duration_ != x) { duration_ = x; emit durationChanged(); } break; }
        case 4: { double x = *static_cast<double *>(prop->data); if (volume_ != x) { volume_ = x; emit volumeChanged(); } break; }
      }
    } else if (event->event_id == MPV_EVENT_END_FILE) {
      auto *end = static_cast<mpv_event_end_file *>(event->data);
      if (end && end->reason == MPV_END_FILE_REASON_ERROR) setError(QString::fromUtf8(mpv_error_string(end->error)));
      else if (end && end->reason == MPV_END_FILE_REASON_EOF) emit playbackFinished();
    } else if (event->event_id == MPV_EVENT_FILE_LOADED) { setError({}); }
  }
}

QVariantList PlaybackController::searchMedia(const QString &query) const {
  QVariantList results;
  const QString needle = query.trimmed();
  if (needle.size() < 2) return results;
  // Intentionally user-local and bounded: never index the entire disk.
  const auto extensions = QSet<QString>{
    "mp4","mkv","avi","mov","webm","mpeg","mpg","m4v","flv","ts",
    "mp3","aac","flac","wav","ogg","opus","m4a","wma","alac"
  };
  const auto home = QDir::homePath();
  const QStringList folders = {
    QStandardPaths::writableLocation(QStandardPaths::DesktopLocation),
    QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
    QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
    QStandardPaths::writableLocation(QStandardPaths::MoviesLocation),
    QStandardPaths::writableLocation(QStandardPaths::MusicLocation),
    QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)
  };
  QSet<QString> visited;
  int inspected = 0;
  for (const QString &folder : folders) {
    const QString canonical = QFileInfo(folder).canonicalFilePath();
    if (canonical.isEmpty() || !canonical.startsWith(home + QDir::separator()) || visited.contains(canonical))
      continue;
    visited.insert(canonical);
    QDirIterator iterator(canonical, QDir::Files | QDir::NoDotAndDotDot,
                          QDirIterator::Subdirectories);
    while (iterator.hasNext() && inspected < 12000 && results.size() < 100) {
      iterator.next();
      ++inspected;
      const QFileInfo info = iterator.fileInfo();
      if (!extensions.contains(info.suffix().toLower())) continue;
      if (!info.fileName().contains(needle, Qt::CaseInsensitive)) continue;
      results.append(QVariantMap{{"name", info.fileName()}, {"path", info.absoluteFilePath()},
                                  {"folder", info.absolutePath()}});
    }
    if (inspected >= 12000 || results.size() >= 100) break;
  }
  return results;
}

QString PlaybackController::locationPath(const QString &name) const {
  if (name == "Desktop") return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
  if (name == "Documents") return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
  if (name == "Pictures") return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
  if (name == "Computer") return "/";
  if (name == "Videos") return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
  if (name == "Music") return QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
  if (name == "Downloads") return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
  return QDir::homePath();
}

QVariantList PlaybackController::browseFolder(const QString &path, const QString &filter) const {
  QVariantList items;
  QDir dir(path);
  if (!dir.exists() || !QFileInfo(dir.absolutePath()).isReadable()) return items;
  static const QSet<QString> supported = {
    "mp4","mkv","avi","mov","webm","mpeg","mpg","m4v","flv","ts",
    "mp3","aac","flac","wav","ogg","opus","m4a","wma","alac"
  };
  const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::Files |
    QDir::NoDotAndDotDot | QDir::Readable, QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
  for (const QFileInfo &entry : entries) {
    const bool directory = entry.isDir();
    if (!directory && !supported.contains(entry.suffix().toLower())) continue;
    if (!filter.isEmpty() && !entry.fileName().contains(filter, Qt::CaseInsensitive)) continue;
    items.append(QVariantMap{{"name",entry.fileName()}, {"path",entry.absoluteFilePath()},
                             {"directory",directory}, {"folder",entry.absolutePath()}});
    if (items.size() >= 500) break;
  }
  return items;
}

QVariantList PlaybackController::recentMedia() const {
  QVariantList items;
  const QStringList paths = QSettings().value("recentMedia").toStringList();
  for (const QString &path : paths) {
    const QFileInfo info(path);
    if (!info.isFile() || !info.isReadable()) continue;
    items.append(QVariantMap{{"name", info.fileName()},
                             {"path", info.absoluteFilePath()},
                             {"directory", false},
                             {"folder", info.absolutePath()}});
  }
  return items;
}

void PlaybackController::setQualityProfile(const QString &requested) {
  if (!handle_) return;
  // High Quality is temporarily disabled: changing to EWA LanczosSharp while
  // rendering caused an abort on an older Intel GPU. Do not restore that saved
  // profile on startup or set it while video is playing.
  const QString profile = requested == "Performance" ? "Performance" : "Balanced";
  const char *filter = profile == "Performance" ? "bilinear" : "spline36";
  const int result = mpv_set_property_string(handle_, "scale", filter);
  if (result < 0) {
    setError(QStringLiteral("Cannot apply video scaling: ") +
             QString::fromUtf8(mpv_error_string(result)));
    return;
  }
  QSettings().setValue("videoQualityProfile", profile);
  if (qualityProfile_ != profile) {
    qualityProfile_ = profile;
    emit qualityProfileChanged();
  }
}

QVariantList PlaybackController::browseSubtitles(const QString &path) const {
  QVariantList items;
  QDir dir(path);
  if (!dir.exists() || !QFileInfo(dir.absolutePath()).isReadable()) return items;
  const QSet<QString> extensions = {"srt", "ass", "ssa", "vtt", "sub", "sup"};
  const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::Files |
    QDir::NoDotAndDotDot | QDir::Readable, QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
  for (const QFileInfo &entry : entries) {
    const bool folder = entry.isDir();
    if (!folder && !extensions.contains(entry.suffix().toLower())) continue;
    items.append(QVariantMap{{"name", entry.fileName()}, {"path", entry.absoluteFilePath()},
                             {"directory", folder}});
    if (items.size() >= 500) break;
  }
  return items;
}
