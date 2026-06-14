package com.example.conventant_navigation

import android.content.Intent
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.covenant.navigation/native_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openVoiceInputSettings" -> openSettings(
                    Intent(Settings.ACTION_VOICE_INPUT_SETTINGS),
                    result,
                    "VOICE_INPUT_SETTINGS_UNAVAILABLE"
                )
                "openTtsDataInstaller" -> openSettings(
                    Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA),
                    result,
                    "TTS_INSTALLER_UNAVAILABLE"
                )
                "openLocationSettings" -> openSettings(
                    Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS),
                    result,
                    "LOCATION_SETTINGS_UNAVAILABLE"
                )
                else -> result.notImplemented()
            }
        }
    }

    private fun openSettings(
        intent: Intent,
        result: MethodChannel.Result,
        errorCode: String
    ) {
        try {
            startActivity(intent)
            result.success(true)
        } catch (error: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
                result.success(true)
            } catch (fallbackError: Exception) {
                result.error(errorCode, fallbackError.localizedMessage, null)
            }
        }
    }
}
