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
#include <QProcess>
#include <QTimer>
#include <QImage>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
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
  mpv_observe_property(handle_, 5, "metadata", MPV_FORMAT_NODE);
  mpv_observe_property(handle_, 6, "speed", MPV_FORMAT_DOUBLE);
  mpv_observe_property(handle_, 7, "track-list", MPV_FORMAT_NODE);
  mpv_observe_property(handle_, 8, "aid", MPV_FORMAT_NODE);
  mpv_set_wakeup_callback(handle_, &PlaybackController::wakeup, this);
  connect(this, &PlaybackController::engineEvent, this, &PlaybackController::processEvents, Qt::QueuedConnection);
  setVolume(std::clamp(QSettings().value("playbackVolume", 70.0).toDouble(), 0.0, 100.0));
  setPlaybackSpeed(std::clamp(QSettings().value("playbackSpeed", 1.0).toDouble(), 0.5, 2.0));
  const QString savedQuality = QSettings().value("videoQualityProfile", "Balanced").toString();
  setQualityProfile(savedQuality);
}
PlaybackController::~PlaybackController() {
  if (artworkProcess_) { artworkProcess_->disconnect(this); artworkProcess_->kill(); artworkProcess_->waitForFinished(1000); }
  if (libraryProbe_) { libraryProbe_->disconnect(this); libraryProbe_->kill(); libraryProbe_->waitForFinished(1000); }
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
  currentFile_ = info.absoluteFilePath();
  lastSavedPosition_ = -1;
  title_ = info.fileName(); emit titleChanged();
  songTitle_ = info.completeBaseName(); artist_.clear(); album_.clear(); artworkUrl_.clear(); emit metadataChanged();
  loadLocalArtwork(info.absoluteFilePath());
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
void PlaybackController::setVolume(double value) { double v = std::clamp(value, 0.0, 100.0); mpv_set_property_async(handle_, 0, "volume", MPV_FORMAT_DOUBLE, &v); QSettings().setValue("playbackVolume", v); }
void PlaybackController::setPlaybackSpeed(double speed) {
  double v = std::clamp(speed, 0.5, 2.0);
  const int status = mpv_set_property(handle_, "speed", MPV_FORMAT_DOUBLE, &v);
  if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
  else QSettings().setValue("playbackSpeed", v);
}
void PlaybackController::selectAudioTrack(int id) {
  if (id < 0) {
    const int status = mpv_set_property_string(handle_, "aid", "no");
    if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
    return;
  }
  const QByteArray value = QByteArray::number(id);
  const int status = mpv_set_property_string(handle_, "aid", value.constData());
  if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
}

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
        case 2: {
          double x = *static_cast<double *>(prop->data);
          if (position_ != x) { position_ = x; emit positionChanged(); }
          if (!currentFile_.isEmpty() && duration_ > 60 && x >= 10 &&
              (lastSavedPosition_ < 0 || std::abs(x - lastSavedPosition_) >= 5)) {
            const QString key = "resume/" + QString::fromLatin1(QCryptographicHash::hash(
                 QFile::encodeName(currentFile_), QCryptographicHash::Sha256).toHex());
            QSettings().setValue(key, x);
            lastSavedPosition_ = x;
          }
          break;
        }
        case 3: { double x = *static_cast<double *>(prop->data); if (duration_ != x) { duration_ = x; emit durationChanged(); } break; }
        case 4: { double x = *static_cast<double *>(prop->data); if (volume_ != x) { volume_ = x; emit volumeChanged(); } break; }
        case 6: {
          const double v = *static_cast<double *>(prop->data);
          if (playbackSpeed_ != v) { playbackSpeed_ = v; emit playbackSpeedChanged(); }
          break;
        }
        case 7: {
          const auto *node = static_cast<const mpv_node *>(prop->data);
          if (node->format != MPV_FORMAT_NODE_ARRAY || !node->u.list) break;
          QVariantList tracks;
          for (int i = 0; i < node->u.list->num; ++i) {
            const mpv_node &entry = node->u.list->values[i];
            if (entry.format != MPV_FORMAT_NODE_MAP || !entry.u.list) continue;
            int id = -1;
            QString type, lang, title;
            for (int j = 0; j < entry.u.list->num; ++j) {
              const auto &value = entry.u.list->values[j];
              const QString key = QString::fromUtf8(entry.u.list->keys[j]);
              if (key == "id" && value.format == MPV_FORMAT_INT64) id = int(value.u.int64);
              if (value.format == MPV_FORMAT_STRING) {
                if (key == "type") type = QString::fromUtf8(value.u.string);
                else if (key == "lang") lang = QString::fromUtf8(value.u.string);
                else if (key == "title") title = QString::fromUtf8(value.u.string);
              }
            }
            if (type != "audio" || id < 0) continue;
            const QString label = QStringLiteral("Track %1").arg(id) +
                (lang.isEmpty() ? QString() : " · " + lang) +
                (title.isEmpty() ? QString() : " · " + title);
            tracks.append(QVariantMap{{"id", id}, {"label", label}});
          }
          audioTracks_ = tracks;
          emit audioTracksChanged();
          break;
        }
        case 8: {
          const auto *node = static_cast<const mpv_node *>(prop->data);
          int id = -1;
          if (node->format == MPV_FORMAT_INT64) id = int(node->u.int64);
          if (selectedAudioTrack_ != id) { selectedAudioTrack_ = id; emit audioTracksChanged(); }
          break;
        }
        case 5: {
          const auto *node = static_cast<const mpv_node *>(prop->data);
          if (node->format != MPV_FORMAT_NODE_MAP || !node->u.list) break;
          QString newTitle, newArtist, newAlbum;
          const mpv_node_list *list = node->u.list;
          for (int i = 0; i < list->num; ++i) {
            if (!list->keys[i] || list->values[i].format != MPV_FORMAT_STRING) continue;
            const QString key = QString::fromUtf8(list->keys[i]).toLower();
            const QString value = QString::fromUtf8(list->values[i].u.string);
            if (key == "title") newTitle = value;
            else if (key == "artist") newArtist = value;
            else if (key == "album_artist" && newArtist.isEmpty()) newArtist = value;
            else if (key == "album") newAlbum = value;
          }
          if (!newTitle.isEmpty()) songTitle_ = newTitle;
          artist_ = newArtist;
          album_ = newAlbum;
          emit metadataChanged();
          break;
        }
      }
    } else if (event->event_id == MPV_EVENT_END_FILE) {
      auto *end = static_cast<mpv_event_end_file *>(event->data);
      if (end && end->reason == MPV_END_FILE_REASON_ERROR) setError(QString::fromUtf8(mpv_error_string(end->error)));
      else if (end && end->reason == MPV_END_FILE_REASON_EOF) {
        if (!currentFile_.isEmpty()) {
          const QString key = "resume/" + QString::fromLatin1(QCryptographicHash::hash(
              QFile::encodeName(currentFile_), QCryptographicHash::Sha256).toHex());
          QSettings().remove(key);
        }
        emit playbackFinished();
      }
    } else if (event->event_id == MPV_EVENT_FILE_LOADED) {
      setError({});
      if (!currentFile_.isEmpty()) {
        const QString key = "resume/" + QString::fromLatin1(QCryptographicHash::hash(
            QFile::encodeName(currentFile_), QCryptographicHash::Sha256).toHex());
        const double saved = QSettings().value(key, 0).toDouble();
        if (saved >= 10 && (duration_ <= 0 || saved < duration_ - 15)) {
          const QByteArray t = QByteArray::number(saved, 'f', 2);
          const char *args[] = {"seek", t.constData(), "absolute", nullptr};
          mpv_command_async(handle_, 0, args);
        }
      }
    }
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

void PlaybackController::setSubtitleDelay(double seconds) {
  QByteArray value = QByteArray::number(std::clamp(seconds, -30.0, 30.0), 'f', 2);
  const int status = mpv_set_property_string(handle_, "sub-delay", value.constData());
  if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
}
void PlaybackController::setSubtitleSize(int size) {
  QByteArray value = QByteArray::number(std::clamp(size, 20, 90));
  const int status = mpv_set_property_string(handle_, "sub-font-size", value.constData());
  if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
}
void PlaybackController::cycleSubtitleTrack() {
  const char *args[] = {"cycle", "sid", nullptr};
  const int status = mpv_command_async(handle_, 0, args);
  if (status < 0) setError(QString::fromUtf8(mpv_error_string(status)));
}

void PlaybackController::loadLocalArtwork(const QString &path) {
  if (artworkProcess_) {
    artworkProcess_->disconnect(this);
    artworkProcess_->kill();
    artworkProcess_->deleteLater();
    artworkProcess_ = nullptr;
  }
  const QString suffix = QFileInfo(path).suffix().toLower();
  if (!QSet<QString>{"mp3","m4a","flac","ogg","opus","aac","wma","alac"}.contains(suffix))
    return;
  // Optional local FFmpeg utility, never a network request; failures retain the fallback icon.
  const QString ffmpeg = QStandardPaths::findExecutable("ffmpeg");
  if (ffmpeg.isEmpty()) return;
  auto *process = new QProcess(this);
  artworkProcess_ = process;
  process->setProgram(ffmpeg);
  process->setArguments({"-nostdin", "-hide_banner", "-loglevel", "error",
                         "-i", path, "-map", "0:v:0", "-frames:v", "1",
                         "-f", "image2pipe", "-vcodec", "mjpeg", "pipe:1"});
  process->setProcessChannelMode(QProcess::SeparateChannels);
  connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
          this, [this, process, path](int code, QProcess::ExitStatus status) {
    if (artworkProcess_ != process) { process->deleteLater(); return; }
    artworkProcess_ = nullptr;
    const QByteArray output = process->readAllStandardOutput();
    process->deleteLater();
    if (status != QProcess::NormalExit || code != 0 || output.isEmpty() || output.size() > 5 * 1024 * 1024) return;
    QImage image = QImage::fromData(output);
    if (image.isNull()) return;
    image = image.scaled(500, 500, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/artwork";
    if (!QDir().mkpath(cacheDir)) return;
    const QByteArray digest = QCryptographicHash::hash(QFile::encodeName(path), QCryptographicHash::Sha256).toHex();
    const QString coverPath = cacheDir + "/" + QString::fromLatin1(digest) + ".png";
    if (!image.save(coverPath, "PNG")) return;
    artworkUrl_ = QUrl::fromLocalFile(coverPath).toString();
    emit metadataChanged();
  });
  process->start();
  QTimer::singleShot(3500, this, [this, process] {
    if (artworkProcess_ == process && process->state() != QProcess::NotRunning) process->kill();
  });
}

void PlaybackController::saveMusicTags(const QString &title, const QString &artist, const QString &album, const QString &coverPath, const QString &outputName) {
  const QFileInfo source(currentFile_);
  if (!source.isFile() || !source.isReadable() ||
      !QSet<QString>{"mp3", "flac", "m4a", "ogg", "opus"}.contains(source.suffix().toLower())) {
    emit tagSaveFinished(false, "Open a supported local audio file first.");
    return;
  }
  const QString ffmpeg = QStandardPaths::findExecutable("ffmpeg");
  if (ffmpeg.isEmpty()) { emit tagSaveFinished(false, "FFmpeg is required to save tags."); return; }
  QString baseName = outputName.trimmed();
  if (baseName.isEmpty()) baseName = source.completeBaseName() + "-edited";
  // Save As accepts a filename only, never a path or traversal sequence.
  if (baseName.contains('/') || baseName.contains(QChar(92)) || baseName == "." ||
      baseName == ".." || baseName.contains("..") || baseName.size() > 180) {
    emit tagSaveFinished(false, "Choose a filename without folders or '..'.");
    return;
  }
  const QString suffix = "." + source.suffix();
  if (baseName.endsWith(suffix, Qt::CaseInsensitive)) baseName.chop(suffix.size());
  const QString output = source.dir().filePath(baseName + suffix);
  if (QFileInfo(output).absoluteFilePath() == source.absoluteFilePath()) {
    emit tagSaveFinished(false, "The original file cannot be overwritten.");
    return;
  }
  if (QFileInfo::exists(output)) {
    emit tagSaveFinished(false, "The edited copy already exists. Rename or move it first.");
    return;
  }
  const QString selectedCover = QUrl(coverPath).isLocalFile() ? QUrl(coverPath).toLocalFile() : coverPath;
  const bool withCover = !selectedCover.trimmed().isEmpty();
  if (withCover) {
    const QFileInfo cover(selectedCover);
    if (source.suffix().compare("mp3", Qt::CaseInsensitive) != 0) {
      emit tagSaveFinished(false, "Adding artwork currently supports MP3 files only.");
      return;
    }
    if (!cover.isFile() || !cover.isReadable() || cover.size() > 15 * 1024 * 1024 ||
        !QSet<QString>{"jpg", "jpeg", "png"}.contains(cover.suffix().toLower())) {
      emit tagSaveFinished(false, "Choose a readable JPG or PNG image smaller than 15 MB.");
      return;
    }
    QImage testImage(selectedCover);
    if (testImage.isNull()) {
      emit tagSaveFinished(false, "The selected image could not be decoded.");
      return;
    }
  }
  auto *proc = new QProcess(this);
  QStringList args = {"-nostdin", "-hide_banner", "-loglevel", "error",
                      "-n", "-i", source.absoluteFilePath(), "-map", "0",
                      "-c", "copy", "-metadata", "title=" + title.left(300),
                      "-metadata", "artist=" + artist.left(300),
                      "-metadata", "album=" + album.left(300), output};
  if (withCover) {
    // Preserve the audio stream and attach one image as ID3 cover art.
    args = {"-nostdin", "-hide_banner", "-loglevel", "error", "-n",
            "-i", source.absoluteFilePath(), "-i", selectedCover,
            "-map", "0:a:0", "-map", "1:v:0", "-c:a", "copy",
            "-c:v", "mjpeg", "-disposition:v:0", "attached_pic",
            "-metadata:s:v:0", "title=Album cover",
            "-metadata:s:v:0", "comment=Cover (front)",
            "-metadata", "title=" + title.left(300),
            "-metadata", "artist=" + artist.left(300),
            "-metadata", "album=" + album.left(300), "-id3v2_version", "3", output};
  }
  proc->setProgram(ffmpeg);
  proc->setArguments(args);
  connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
          this, [this, proc, output](int code, QProcess::ExitStatus status) {
    const QString errorText = QString::fromUtf8(proc->readAllStandardError()).trimmed();
    proc->deleteLater();
    if (status == QProcess::NormalExit && code == 0 && QFileInfo(output).isFile()) {
      emit tagSaveFinished(true, "Saved a new copy: " + output);
    } else {
      QFile::remove(output);
      emit tagSaveFinished(false, errorText.isEmpty() ? "Unable to write music information." : errorText.left(250));
    }
  });
  proc->start();
}

QVariantList PlaybackController::browseCoverImages(const QString &path) const {
  QVariantList items;
  QDir dir(path);
  if (!dir.exists() || !QFileInfo(dir.absolutePath()).isReadable()) return items;
  static const QSet<QString> imageTypes = {"jpg", "jpeg", "png"};
  const QFileInfoList entries = dir.entryInfoList(QDir::Dirs | QDir::Files |
    QDir::NoDotAndDotDot | QDir::Readable, QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
  for (const QFileInfo &entry : entries) {
    const bool folder = entry.isDir();
    if (!folder && !imageTypes.contains(entry.suffix().toLower())) continue;
    items.append(QVariantMap{{"name", entry.fileName()}, {"path", entry.absoluteFilePath()},
                             {"directory", folder}});
    if (items.size() >= 500) break;
  }
  return items;
}

QVariantList PlaybackController::scanMusicLibrary(const QString &folder, const QString &filter) const {
  QVariantList songs;
  const QDir dir(folder);
  if (!dir.exists() || !QFileInfo(dir.absolutePath()).isReadable()) return songs;
  const QSet<QString> audioExt = {"mp3", "flac", "wav", "ogg", "opus", "m4a", "aac", "wma", "alac"};
  QDirIterator files(dir.absolutePath(), QDir::Files | QDir::Readable | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
  int inspected = 0;
  while (files.hasNext() && inspected < 5000 && songs.size() < 600) {
    files.next();
    ++inspected;
    const QFileInfo info = files.fileInfo();
    if (!audioExt.contains(info.suffix().toLower())) continue;
    if (!filter.isEmpty() && !info.fileName().contains(filter, Qt::CaseInsensitive)) continue;
    songs.append(QVariantMap{{"name", info.completeBaseName()}, {"path", info.absoluteFilePath()},
                             {"folder", info.absolutePath()}});
  }
  return songs;
}

void PlaybackController::inspectMusicTags(const QVariantList &songs) {
  pendingMusicFiles_.clear();
  if (libraryProbe_) {
    libraryProbe_->disconnect(this);
    libraryProbe_->kill();
    libraryProbe_->deleteLater();
    libraryProbe_ = nullptr;
  }
  if (QStandardPaths::findExecutable("ffprobe").isEmpty()) return;
  // Limit metadata reads to keep large libraries responsive.
  for (const QVariant &item : songs) {
    const QString path = item.toMap().value("path").toString();
    if (QFileInfo(path).isFile() && pendingMusicFiles_.size() < 250)
      pendingMusicFiles_.append(path);
  }
  inspectNextMusicTag();
}
void PlaybackController::inspectNextMusicTag() {
  if (pendingMusicFiles_.isEmpty() || libraryProbe_) return;
  const QString path = pendingMusicFiles_.takeFirst();
  auto *probe = new QProcess(this);
  libraryProbe_ = probe;
  probe->setProgram("ffprobe");
  probe->setArguments({"-v", "error", "-show_entries",
                       "format_tags=title,artist,album", "-of", "json", path});
  connect(probe, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
          this, [this, probe, path](int exitCode, QProcess::ExitStatus status) {
    if (libraryProbe_ != probe) { probe->deleteLater(); return; }
    libraryProbe_ = nullptr;
    if (exitCode == 0 && status == QProcess::NormalExit) {
      const QJsonObject tags = QJsonDocument::fromJson(probe->readAllStandardOutput())
                                     .object().value("format").toObject().value("tags").toObject();
      QString artist, album, title;
      for (auto it = tags.begin(); it != tags.end(); ++it) {
        const QString k = it.key().toLower();
        if (k == "artist") artist = it.value().toString();
        else if (k == "album") album = it.value().toString();
        else if (k == "title") title = it.value().toString();
      }
      emit libraryTagFound(path, artist, album, title);
    }
    probe->deleteLater();
    inspectNextMusicTag();
  });
  probe->start();
  QTimer::singleShot(1200, this, [this, probe] {
    if (libraryProbe_ == probe && probe->state() != QProcess::NotRunning) probe->kill();
  });
}

QString PlaybackController::mediaInformation() const {
  if (currentFile_.isEmpty()) return "Open a local media file to view its information.";
  const QFileInfo file(currentFile_);
  QStringList lines = {"File: " + file.fileName(),
                       "Location: " + file.absoluteFilePath(),
                       "Size: " + QString::number(file.size() / 1048576.0, 'f', 2) + " MiB"};
  auto read = [this](const char *key) {
    char *value = mpv_get_property_string(handle_, key);
    if (!value) return QString();
    const QString result = QString::fromUtf8(value);
    mpv_free(value);
    return result;
  };
  for (const auto &field : {
      std::pair<const char *, const char *>{"Video codec", "video-codec"},
      {"Width", "width"}, {"Height", "height"},
      {"Frame rate", "estimated-vf-fps"},
      {"Audio codec", "audio-codec"},
      {"Audio channels", "audio-params/channel-count"},
      {"Sample rate", "audio-params/samplerate"},
      {"Container", "file-format"}}) {
    const QString value = read(field.second);
    if (!value.isEmpty()) lines << QString::fromUtf8(field.first) + ": " + value;
  }
  lines << "Duration: " + QString::number(duration_, 'f', 1) + " seconds";
  return lines.join("\n");
}
