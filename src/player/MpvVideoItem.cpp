#include "MpvVideoItem.h"
#include "PlaybackController.h"
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLFramebufferObject>
#include <QMetaObject>
#include <QPointer>
#include <stdexcept>
namespace {
void *getProcAddress(void *, const char *name) {
  auto *ctx = QOpenGLContext::currentContext();
  return ctx ? reinterpret_cast<void *>(ctx->getProcAddress(name)) : nullptr;
}
class MpvRenderer final : public QQuickFramebufferObject::Renderer {
public:
  explicit MpvRenderer(const MpvVideoItem *item) : item_(const_cast<MpvVideoItem *>(item)) {}
  ~MpvRenderer() override {
    if (context_) {
      mpv_render_context_set_update_callback(context_, nullptr, nullptr);
      mpv_render_context_free(context_);
    }
  }
  void synchronize(QQuickFramebufferObject *item) override {
    auto *video = static_cast<MpvVideoItem *>(item);
    auto *controller = qobject_cast<PlaybackController *>(video->controller());
    if (!context_ && controller && controller->handle()) {
      mpv_opengl_init_params gl = {getProcAddress, nullptr};
      mpv_render_param params[] = {{MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                                   {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl}, {MPV_RENDER_PARAM_INVALID, nullptr}};
      if (mpv_render_context_create(&context_, controller->handle(), params) >= 0) {
        mpv_render_context_set_update_callback(context_, &MpvRenderer::onUpdate, this);
      }
    }
  }
  QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override {
    return new QOpenGLFramebufferObject(size, QOpenGLFramebufferObject::CombinedDepthStencil);
  }
  void render() override {
    if (!context_) return;
    QOpenGLFramebufferObject *fbo = framebufferObject();
    mpv_opengl_fbo mpvFbo = {static_cast<int>(fbo->handle()), fbo->width(), fbo->height(), 0};
    int flip = 1;
    mpv_render_param params[] = {{MPV_RENDER_PARAM_OPENGL_FBO, &mpvFbo},
                                 {MPV_RENDER_PARAM_FLIP_Y, &flip}, {MPV_RENDER_PARAM_INVALID, nullptr}};
    mpv_render_context_render(context_, params);
    if (QOpenGLContext::currentContext()) QOpenGLContext::currentContext()->functions()->glFlush();
  }
private:
  static void onUpdate(void *ctx) {
    auto *self = static_cast<MpvRenderer *>(ctx);
    if (self->item_) QMetaObject::invokeMethod(self->item_.data(), "update", Qt::QueuedConnection);
  }
  QPointer<MpvVideoItem> item_;
  mpv_render_context *context_ = nullptr;
};
}
MpvVideoItem::MpvVideoItem(QQuickItem *parent) : QQuickFramebufferObject(parent) { setMirrorVertically(false); }
QQuickFramebufferObject::Renderer *MpvVideoItem::createRenderer() const { return new MpvRenderer(this); }
void MpvVideoItem::setController(QObject *controller) {
  if (controller_ == controller) return;
  controller_ = controller; emit controllerChanged(); update();
}
