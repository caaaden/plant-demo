import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/api_service.dart';
import '../helpers/cache_helper.dart';

class SettingsProvider extends ChangeNotifier {
  Settings? _settings;
  bool _isLoading = false;
  String? _error;

  // Getters
  Settings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get pushNotificationEnabled => _settings?.pushNotificationEnabled ?? true;
  String get language => _settings?.language ?? 'ko';
  String get theme => _settings?.theme ?? 'system'; // 기본값을 system으로 변경

  // 로딩 상태 관리
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 에러 상태 관리
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  // 설정 초기화
  Future<void> initializeSettings() async {
    _setLoading(true);
    _setError(null);

    try {
      // 먼저 캐시에서 로드
      final cachedSettings = CacheHelper.getJson(CacheHelper.USER_SETTINGS);
      if (cachedSettings != null) {
        _settings = Settings.fromJson(cachedSettings);
        notifyListeners();
      }

      // 서버에서 최신 설정 로드 (시연용이므로 ApiService 호출)
      Settings? serverSettings = await ApiService.getSettings();
      if (serverSettings != null) {
        _settings = serverSettings;
        // 캐시에 저장
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, serverSettings.toJson());
      } else if (_settings == null) {
        // 기본 설정 생성 - 테마 기본값을 system으로 변경
        _settings = Settings(
          userId: 'user_default',
          pushNotificationEnabled: true,
          language: 'ko',
          theme: 'system', // 기본값 변경
        );
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, _settings!.toJson());
      }

      notifyListeners();
    } catch (e) {
      _setError('설정을 불러오는데 실패했습니다: $e');

      // 에러 발생 시 기본 설정 사용
      if (_settings == null) {
        _settings = Settings(
          userId: 'user_default',
          pushNotificationEnabled: true,
          language: 'ko',
          theme: 'system', // 기본값 변경
        );
        notifyListeners();
      }

      print('Error initializing settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 설정 업데이트
  Future<bool> updateSettings(Settings newSettings) async {
    _setLoading(true);
    _setError(null);

    try {
      Settings? result = await ApiService.updateSettings(newSettings);
      if (result != null) {
        _settings = result;
        // 캐시에 저장
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, result.toJson());
        notifyListeners();
        return true;
      } else {
        _setError('설정 업데이트에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('설정 업데이트 중 오류가 발생했습니다: $e');

      // 오프라인일 경우 로컬에만 저장
      _settings = newSettings;
      await CacheHelper.setJson(CacheHelper.USER_SETTINGS, newSettings.toJson());
      notifyListeners();

      print('Error updating settings: $e');
      return true; // 로컬 저장은 성공
    } finally {
      _setLoading(false);
    }
  }

  // 푸시 알림 토글 (즉시 반영, 백그라운드 저장)
  Future<bool> togglePushNotification() async {
    if (_settings == null) return false;

    // 즉시 UI 업데이트
    final newValue = !_settings!.pushNotificationEnabled;
    _settings = _settings!.copyWith(pushNotificationEnabled: newValue);
    notifyListeners();

    // 백그라운드에서 저장 (로딩 상태 없이)
    try {
      final updatedSettings = _settings!;
      Settings? result = await ApiService.updateSettings(updatedSettings);
      if (result != null) {
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, result.toJson());
        return true;
      }
    } catch (e) {
      // 저장 실패 시에도 UI는 이미 변경된 상태 유지
      print('Error saving notification settings: $e');
    }
    return true; // UI는 이미 업데이트되었으므로 true 반환
  }

  // 언어 변경 (언어 선택 기능 제거되지만 메서드는 유지)
  Future<bool> changeLanguage(String language) async {
    if (_settings == null) return false;

    final updatedSettings = _settings!.copyWith(language: language);
    return await updateSettings(updatedSettings);
  }

  // 테마 변경 (즉시 반영, 백그라운드 저장)
  Future<bool> changeTheme(String theme) async {
    if (_settings == null) return false;

    // 즉시 UI 업데이트
    _settings = _settings!.copyWith(theme: theme);
    notifyListeners();

    // 백그라운드에서 저장
    try {
      final updatedSettings = _settings!;
      Settings? result = await ApiService.updateSettings(updatedSettings);
      if (result != null) {
        await CacheHelper.setJson(CacheHelper.USER_SETTINGS, result.toJson());
        return true;
      }
    } catch (e) {
      print('Error saving theme settings: $e');
    }
    return true;
  }

  // 설정 리셋 - 테마 기본값도 system으로 변경
  Future<bool> resetSettings() async {
    final defaultSettings = Settings(
      userId: _settings?.userId ?? 'user_default',
      pushNotificationEnabled: true,
      language: 'ko',
      theme: 'system', // 기본값 변경
    );

    return await updateSettings(defaultSettings);
  }
}