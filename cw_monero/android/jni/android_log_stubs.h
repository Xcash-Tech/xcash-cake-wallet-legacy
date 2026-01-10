// Android-safe logging stubs
// MINFO and other logging macros crash on Android because stdout is not available
// This header provides empty stubs to prevent crashes

#ifndef ANDROID_LOG_STUBS_H
#define ANDROID_LOG_STUBS_H

#ifdef __ANDROID__

// Disable easylogging++ output to stdout/stderr which crashes on Android
#undef MINFO
#undef MDEBUG
#undef MWARNING
#undef MERROR
#undef MFATAL
#undef MTRACE
#undef MLOG

#define MINFO(x) do {} while(0)
#define MDEBUG(x) do {} while(0)
#define MWARNING(x) do {} while(0)
#define MERROR(x) do {} while(0)
#define MFATAL(x) do {} while(0)
#define MTRACE(x) do {} while(0)
#define MLOG(level, x) do {} while(0)

#endif // __ANDROID__

#endif // ANDROID_LOG_STUBS_H
