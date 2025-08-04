import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String _questionsVersionKey = "question_version";

  static const String _storedVersionKey = "stored_question_version";

  static const String _questionKey = "question";
  static const String _defaultQuestion = "Move the slider to the right";

  int _localVersion = 0;
  bool _isInitialized = false;

  /// Notifies UI when version changes
  final ValueNotifier<int> versionUpdateCounter = ValueNotifier<int>(0);

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _localVersion = prefs.getInt(_storedVersionKey) ?? 0;

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration(seconds: 60),
      ),
    );

    await _remoteConfig.setDefaults({
      _questionsVersionKey: _localVersion,
      _questionKey: _defaultQuestion,
    });

    try {
      await _remoteConfig.fetchAndActivate();

      // Update local version after successful fetch
      _updateLocalVersion(prefs);

      _remoteConfig.onConfigUpdated.listen((_) async {
        await _remoteConfig.fetchAndActivate();
        _updateLocalVersion(prefs);
      });

      _isInitialized = true;
      debugPrint('RemoteConfig initialized successfully');
    } catch (e) {
      debugPrint('RemoteConfig fetch failed: $e');
      // Still mark as initialized even if fetch fails, so we can use defaults
      _isInitialized = true;
    }
  }

  /// Update local version from remote config
  void _updateLocalVersion(SharedPreferences prefs) {
    final fetchedVersion = _remoteConfig.getInt(_questionsVersionKey);

    if (_localVersion != fetchedVersion) {
      debugPrint(
        'RemoteConfig version updated: $_localVersion -> $fetchedVersion',
      );
      _localVersion = fetchedVersion;
      debugPrint(
        'RemoteConfig version updated 2: $_localVersion -> $fetchedVersion',
      );
      prefs.setInt(_storedVersionKey, fetchedVersion);
      debugPrint(
        'RemoteConfig version updated 2: $_storedVersionKey -> $fetchedVersion',
      ); // Save to persistent storage
      _onVersionChanged(fetchedVersion);
    }
  }

  /// Called when remote version changes
  void _onVersionChanged(int version) {
    debugPrint('Questions version updated to: $version');
    versionUpdateCounter.value++;
  }

  /// Public accessor for current version
  int get currentQuestionsVersion => _localVersion;

  /// Get question value with fallback
  String get question {
    final value = _remoteConfig.getString(_questionKey);
    return value.isNotEmpty ? value : _defaultQuestion;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
