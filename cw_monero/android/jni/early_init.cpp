// Early initialization to disable logging BEFORE any xcash-core static constructors run
// Priority 1 ensures this runs before libwallet_api.a static initializers (typically priority 65535)

#ifdef __ANDROID__

#include <android/log.h>

#define LOG_TAG "xcash"

// Redirect easylogging++ output to Android logcat
// This struct initializes before anything else
struct EarlyLogDisabler {
    EarlyLogDisabler() {
        __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "Early log initializer running");
    }
} __attribute__((init_priority(101)));

static EarlyLogDisabler g_early_log_disabler;

#endif
