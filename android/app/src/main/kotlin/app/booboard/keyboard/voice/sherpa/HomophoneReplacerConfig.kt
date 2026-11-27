// Copied unmodified from k2-fsa/sherpa-onnx v2.0.1 (Apache-2.0): android/SherpaOnnxAar/sherpa_onnx/src/main/java/com/k2fsa/sherpa/onnx/HomophoneReplacerConfig.kt
// JNI binds to these class names, so keep the package. See docs/notices/voice.md.
package com.k2fsa.sherpa.onnx

data class HomophoneReplacerConfig(
    var dictDir: String = "", // unused
    var lexicon: String = "",
    var ruleFsts: String = "",
)
