// SPDX-License-Identifier: GPL-3.0-or-later
//
// JNI bridge between app.booboard.keyboard.images.SdNative and stable-diffusion.cpp (see
// third_party/README.md). No network code. The prompt is never logged: engine log lines go to the Android log
// at WARN and above only, and any line or error text that contains the prompt is replaced.

#include <jni.h>
#include <android/log.h>

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <mutex>
#include <set>
#include <string>

#include "stable-diffusion.h"

#define STB_IMAGE_WRITE_STATIC
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

namespace {

constexpr const char* kLogTag = "BooBoardImages";

constexpr jint kResultOk = 0;
constexpr jint kResultCancelled = 1;
constexpr jint kResultError = 2;

constexpr int kPhaseLoading = 0;
constexpr int kPhaseSampling = 1;
constexpr int kPhaseDecoding = 2;

JavaVM* g_vm = nullptr;

// ---- Last error and prompt redaction --------------------------------------------------------------------
std::mutex g_text_mutex;
std::string g_last_error;
std::string g_redact_prompt;
std::string g_redact_negative;

void replace_all(std::string& text, const std::string& needle, const char* with) {
    if (needle.empty()) return;
    size_t at = 0;
    while ((at = text.find(needle, at)) != std::string::npos) {
        text.replace(at, needle.size(), with);
        at += std::strlen(with);
    }
}

// Removes the current prompt texts from a message. Locks g_text_mutex.
std::string redact(const char* raw) {
    std::string text = raw ? raw : "";
    std::lock_guard<std::mutex> lock(g_text_mutex);
    replace_all(text, g_redact_prompt, "[prompt]");
    replace_all(text, g_redact_negative, "[prompt]");
    return text;
}

void set_last_error(const std::string& text) {
    std::lock_guard<std::mutex> lock(g_text_mutex);
    g_last_error = text;
}

void set_redaction(const std::string& prompt, const std::string& negative) {
    std::lock_guard<std::mutex> lock(g_text_mutex);
    g_redact_prompt = prompt;
    g_redact_negative = negative;
}

// Engine error text for the last failed call, with the prompt removed.
void remember_engine_error(const char* what, sd_status_t status) {
    const char* detail = sd_get_last_error();
    std::string text = std::string(what) + " (status " + std::to_string(static_cast<int>(status)) + ")";
    if (detail && *detail) text += ": " + redact(detail);
    set_last_error(text);
}

void engine_log(enum sd_log_level_t level, const char* text, void*) {
    if (level < SD_LOG_WARN) return;
    const int priority = level == SD_LOG_WARN ? ANDROID_LOG_WARN : ANDROID_LOG_ERROR;
    const std::string safe = redact(text);
    __android_log_write(priority, kLogTag, safe.c_str());
}

// ---- JNI helpers ----------------------------------------------------------------------------------------
// JNI's "modified UTF-8" mangles emoji, so strings are converted from UTF-16 by hand.
std::string to_utf8(JNIEnv* env, jstring value) {
    std::string out;
    if (!value) return out;
    const jsize length = env->GetStringLength(value);
    const jchar* chars = env->GetStringChars(value, nullptr);
    if (!chars) return out;
    out.reserve(static_cast<size_t>(length) * 3);
    for (jsize i = 0; i < length; ++i) {
        uint32_t cp = chars[i];
        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < length && chars[i + 1] >= 0xDC00 && chars[i + 1] <= 0xDFFF) {
            cp = 0x10000 + ((cp - 0xD800) << 10) + (chars[i + 1] - 0xDC00);
            ++i;
        } else if (cp >= 0xD800 && cp <= 0xDFFF) {
            cp = 0xFFFD;  // lone surrogate
        }
        if (cp < 0x80) {
            out.push_back(static_cast<char>(cp));
        } else if (cp < 0x800) {
            out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        } else if (cp < 0x10000) {
            out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        } else {
            out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
        }
    }
    env->ReleaseStringChars(value, chars);
    return out;
}

// Detaches a thread that this library attached, when the thread ends.
struct ThreadDetacher {
    bool attached = false;
    ~ThreadDetacher() {
        if (attached && g_vm) g_vm->DetachCurrentThread();
    }
};
thread_local ThreadDetacher t_detacher;

JNIEnv* current_env() {
    if (!g_vm) return nullptr;
    JNIEnv* env = nullptr;
    const jint state = g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (state == JNI_OK) return env;
    if (state == JNI_EDETACHED && g_vm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
        t_detacher.attached = true;
        return env;
    }
    return nullptr;
}

// A Kotlin SdProgressListener held through a global reference for the length of one native call, because the
// engine may report from another thread than the one that called in.
class Listener {
public:
    Listener(JNIEnv* env, jobject listener) {
        if (!listener) return;
        jclass cls = env->GetObjectClass(listener);
        method_ = cls ? env->GetMethodID(cls, "onProgress", "(III)V") : nullptr;
        if (cls) env->DeleteLocalRef(cls);
        if (!method_) {
            env->ExceptionClear();
            return;
        }
        ref_ = env->NewGlobalRef(listener);
    }
    ~Listener() {
        if (!ref_) return;
        if (JNIEnv* env = current_env()) env->DeleteGlobalRef(ref_);
    }
    Listener(const Listener&) = delete;
    Listener& operator=(const Listener&) = delete;

    void report(int phase, int step, int steps) const {
        if (!ref_) return;
        JNIEnv* env = current_env();
        if (!env) return;
        env->CallVoidMethod(ref_, method_, static_cast<jint>(phase), static_cast<jint>(step), static_cast<jint>(steps));
        if (env->ExceptionCheck()) env->ExceptionClear();
    }

private:
    jobject ref_ = nullptr;
    jmethodID method_ = nullptr;
};

void engine_progress(const sd_generation_progress_t* info, void* data) {
    if (!info || !info->stage || !data) return;
    const auto* listener = static_cast<const Listener*>(data);
    const int completed = static_cast<int>(info->completed);
    const int total = static_cast<int>(info->total);
    if (std::strcmp(info->stage, "loading") == 0) {
        listener->report(kPhaseLoading, completed, total);
    } else if (std::strcmp(info->stage, "sampling") == 0) {
        listener->report(kPhaseSampling, completed, total);
    } else if (std::strcmp(info->stage, "vae_decode") == 0) {
        listener->report(kPhaseDecoding, 0, 0);
    }
}

// ---- Engine handle --------------------------------------------------------------------------------------
struct Engine {
    sd_ctx_t* ctx = nullptr;
    std::mutex mutex;
    std::condition_variable idle;
    bool running = false;
};

// Handles that are alive. nativeCancel and nativeFree check it so a late cancel never touches freed memory.
std::mutex g_registry_mutex;
std::set<Engine*> g_engines;

Engine* from_handle(jlong handle) {
    return reinterpret_cast<Engine*>(static_cast<intptr_t>(handle));
}

bool set_string(sd_opt_t* opt, const char* key, const std::string& value) {
    const sd_status_t status = sd_opt_set_string(opt, key, value.c_str());
    if (status != SD_STATUS_OK) {
        remember_engine_error((std::string("option ") + key).c_str(), status);
        return false;
    }
    return true;
}

bool set_int(sd_opt_t* opt, const char* key, int64_t value) {
    const sd_status_t status = sd_opt_set_int(opt, key, value);
    if (status != SD_STATUS_OK) {
        remember_engine_error((std::string("option ") + key).c_str(), status);
        return false;
    }
    return true;
}

bool set_bool(sd_opt_t* opt, const char* key, bool value) {
    const sd_status_t status = sd_opt_set_bool(opt, key, value);
    if (status != SD_STATUS_OK) {
        remember_engine_error((std::string("option ") + key).c_str(), status);
        return false;
    }
    return true;
}

bool set_float(sd_opt_t* opt, const char* key, double value) {
    const sd_status_t status = sd_opt_set_float(opt, key, value);
    if (status != SD_STATUS_OK) {
        remember_engine_error((std::string("option ") + key).c_str(), status);
        return false;
    }
    return true;
}

// Writes the first image of [result] as PNG: to "<path>.tmp", then renamed, so a reader never sees half a file.
bool write_png(const sd_result_t* result, const std::string& path) {
    if (sd_result_get_image_count(result) < 1) {
        set_last_error("the engine returned no picture");
        return false;
    }
    const sd_tensor_t* image = sd_result_get_image(result, 0);
    if (!image || sd_tensor_type(image) != SD_TENSOR_U8 || sd_tensor_rank(image) != 3) {
        set_last_error("the engine returned a picture in an unexpected format");
        return false;
    }
    const int channels = static_cast<int>(sd_tensor_dim(image, 0));
    const int width = static_cast<int>(sd_tensor_dim(image, 1));
    const int height = static_cast<int>(sd_tensor_dim(image, 2));
    const void* pixels = sd_tensor_data(image);
    if (!pixels || channels < 1 || channels > 4 || width < 1 || height < 1 ||
        sd_tensor_byte_size(image) < static_cast<size_t>(channels) * width * height) {
        set_last_error("the engine returned a picture with a bad size");
        return false;
    }
    const std::string temp = path + ".tmp";
    if (!stbi_write_png(temp.c_str(), width, height, channels, pixels, width * channels)) {
        set_last_error("could not write the PNG file");
        std::remove(temp.c_str());
        return false;
    }
    if (std::rename(temp.c_str(), path.c_str()) != 0) {
        std::remove(path.c_str());
        if (std::rename(temp.c_str(), path.c_str()) != 0) {
            set_last_error("could not move the PNG file into place");
            std::remove(temp.c_str());
            return false;
        }
    }
    return true;
}

jlong load_model(JNIEnv* env, jstring model_path, jstring taesd_path, jint threads, jobject listener_object) {
    set_last_error("");
    Listener listener(env, listener_object);
    listener.report(kPhaseLoading, 0, 0);

    const std::string model = to_utf8(env, model_path);
    const std::string taesd = to_utf8(env, taesd_path);
    if (model.empty() || taesd.empty()) {
        set_last_error("model or decoder path is empty");
        return 0;
    }

    sd_ctx_opt_t* opt = sd_ctx_opt_create();
    if (!opt) {
        set_last_error("out of memory");
        return 0;
    }
    // The GGUF has no full VAE (first_stage_model.* is absent): TAESD is THE decoder, not just a preview.
    bool ok = set_string(opt, "model_path", model) && set_string(opt, "taesd_path", taesd) &&
              set_bool(opt, "tae_preview_only", false) && (threads <= 0 || set_int(opt, "n_threads", threads));
    sd_ctx_t* ctx = nullptr;
    if (ok) {
        const sd_status_t status = sd_ctx_create(opt, &ctx);
        if (status != SD_STATUS_OK) {
            remember_engine_error("could not create the engine", status);
            ok = false;
        }
    }
    sd_opt_free(opt);
    if (!ok) return 0;

    // Weights are read when the first picture starts (the engine loads lazily); this probes the file now so a
    // wrong or damaged model is reported at load time.
    if (!sd_ctx_supports_image_generation(ctx)) {
        remember_engine_error("the model cannot make pictures", SD_STATUS_UNSUPPORTED);
        sd_ctx_free(ctx);
        return 0;
    }

    auto* engine = new Engine();
    engine->ctx = ctx;
    {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        g_engines.insert(engine);
    }
    return static_cast<jlong>(reinterpret_cast<intptr_t>(engine));
}

jint generate(JNIEnv* env, jlong handle, jstring prompt_s, jstring negative_s, jlong seed, jint steps, jint width,
              jint height, jfloat cfg, jstring out_path_s, jobject listener_object) {
    set_last_error("");
    Engine* engine = from_handle(handle);
    {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        if (!engine || g_engines.find(engine) == g_engines.end()) {
            set_last_error("the model is not loaded");
            return kResultError;
        }
    }
    {
        std::lock_guard<std::mutex> lock(engine->mutex);
        if (engine->running) {
            set_last_error("a picture is already being made");
            return kResultError;
        }
        engine->running = true;
    }

    const std::string prompt = to_utf8(env, prompt_s);
    const std::string negative = to_utf8(env, negative_s);
    const std::string out_path = to_utf8(env, out_path_s);
    set_redaction(prompt, negative);

    jint result_code = kResultError;
    sd_img_gen_opt_t* opt = nullptr;
    sd_result_t* result = nullptr;
    {
        Listener listener(env, listener_object);
        sd_set_generation_progress_callback(engine->ctx, engine_progress, &listener);

        opt = sd_img_gen_opt_create();
        bool ok = opt != nullptr;
        if (!ok) set_last_error("out of memory");
        // LCM: sampler "lcm", scheduler left on auto (the engine picks the lcm scheduler for it).
        ok = ok && set_string(opt, "prompt", prompt) && (negative.empty() || set_string(opt, "negative_prompt", negative)) &&
             set_int(opt, "seed", seed) && set_int(opt, "width", width) && set_int(opt, "height", height) &&
             set_string(opt, "sample.method", "lcm") && set_int(opt, "sample.steps", steps) &&
             set_float(opt, "sample.guidance.txt_cfg", cfg);
        if (ok) {
            const sd_status_t status = sd_generate_image(engine->ctx, opt, &result);
            if (status == SD_STATUS_OK) {
                result_code = write_png(result, out_path) ? kResultOk : kResultError;
            } else if (status == SD_STATUS_CANCELLED) {
                result_code = kResultCancelled;
            } else {
                remember_engine_error("could not make the picture", status);
            }
        }
        sd_result_free(result);
        sd_opt_free(opt);
        sd_set_generation_progress_callback(engine->ctx, nullptr, nullptr);
    }
    set_redaction("", "");

    {
        std::lock_guard<std::mutex> lock(engine->mutex);
        engine->running = false;
    }
    engine->idle.notify_all();
    return result_code;
}

void cancel(jlong handle) {
    std::lock_guard<std::mutex> lock(g_registry_mutex);
    Engine* engine = from_handle(handle);
    if (!engine || g_engines.find(engine) == g_engines.end()) return;
    sd_cancel_generation(engine->ctx, SD_CANCEL_ALL);
}

void free_model(jlong handle) {
    Engine* engine = from_handle(handle);
    {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        if (!engine || g_engines.erase(engine) == 0) return;  // unknown or already freed
        // New cancels can no longer reach the engine; stop a picture that is still being made.
        sd_cancel_generation(engine->ctx, SD_CANCEL_ALL);
    }
    {
        std::unique_lock<std::mutex> lock(engine->mutex);
        engine->idle.wait(lock, [engine] { return !engine->running; });
    }
    sd_ctx_free(engine->ctx);
    delete engine;
}

}  // namespace

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    g_vm = vm;
    sd_set_log_callback(engine_log, nullptr);
    return JNI_VERSION_1_6;
}

JNIEXPORT jlong JNICALL Java_app_booboard_keyboard_images_SdNative_nativeLoad(JNIEnv* env, jclass, jstring model_path,
                                                                             jstring taesd_path, jint threads,
                                                                             jobject listener) {
    try {
        return load_model(env, model_path, taesd_path, threads, listener);
    } catch (const std::exception& e) {
        set_last_error(std::string("load failed: ") + redact(e.what()));
    } catch (...) {
        set_last_error("load failed");
    }
    return 0;
}

JNIEXPORT jint JNICALL Java_app_booboard_keyboard_images_SdNative_nativeGenerate(
    JNIEnv* env, jclass, jlong handle, jstring prompt, jstring negative_prompt, jlong seed, jint steps, jint width,
    jint height, jfloat cfg_scale, jstring out_png_path, jobject listener) {
    try {
        return generate(env, handle, prompt, negative_prompt, seed, steps, width, height, cfg_scale, out_png_path,
                        listener);
    } catch (const std::exception& e) {
        set_last_error(std::string("picture failed: ") + redact(e.what()));
    } catch (...) {
        set_last_error("picture failed");
    }
    // An exception left the engine marked as running: clear it so the handle stays usable.
    Engine* engine = from_handle(handle);
    {
        std::lock_guard<std::mutex> lock(g_registry_mutex);
        if (!engine || g_engines.find(engine) == g_engines.end()) return kResultError;
    }
    {
        std::lock_guard<std::mutex> lock(engine->mutex);
        engine->running = false;
    }
    engine->idle.notify_all();
    set_redaction("", "");
    return kResultError;
}

JNIEXPORT void JNICALL Java_app_booboard_keyboard_images_SdNative_nativeCancel(JNIEnv*, jclass, jlong handle) {
    cancel(handle);
}

JNIEXPORT void JNICALL Java_app_booboard_keyboard_images_SdNative_nativeFree(JNIEnv*, jclass, jlong handle) {
    try {
        free_model(handle);
    } catch (...) {
    }
}

JNIEXPORT jstring JNICALL Java_app_booboard_keyboard_images_SdNative_nativeLastError(JNIEnv* env, jclass) {
    std::string text;
    {
        std::lock_guard<std::mutex> lock(g_text_mutex);
        text = g_last_error;
    }
    // NewStringUTF wants modified UTF-8: keep plain ASCII only (error texts are English, with file names at most).
    for (char& c : text) {
        if (static_cast<unsigned char>(c) < 0x20 || static_cast<unsigned char>(c) > 0x7E) c = '?';
    }
    return env->NewStringUTF(text.c_str());
}

}  // extern "C"
