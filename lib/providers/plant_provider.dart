import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../models/app_models.dart';
import '../services/api_service.dart';
import '../helpers/network_helper.dart';
import '../helpers/cache_helper.dart';

class PlantProvider extends ChangeNotifier {
  Plant? _plant;
  SensorData? _sensorData;
  List<NotificationItem> _notifications = [];
  List<HistoricalDataPoint> _historicalData = [];
  List<PlantProfile> _plantProfiles = [];
  String _selectedPeriod = '24h';
  bool _isLoading = false;
  String? _error;
  Timer? _sensorTimer;

  // Getters
  Plant? get plant => _plant;
  SensorData? get sensorData => _sensorData;
  List<NotificationItem> get notifications => _notifications;
  List<HistoricalDataPoint> get historicalData => _historicalData;
  List<PlantProfile> get plantProfiles => _plantProfiles;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPlant => _plant != null;

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

  // 식물 프로파일 로드
  Future<void> loadPlantProfiles() async {
    try {
      _setError(null);
      _plantProfiles = await ApiService.getPlantProfiles();
      notifyListeners();
    } catch (e) {
      _setError('식물 프로파일을 불러오는데 실패했습니다: $e');
      print('Error loading plant profiles: $e');
    }
  }

  // 식물 등록
  Future<bool> registerPlant(Plant plant) async {
    _setLoading(true);
    _setError(null);

    try {
      Plant? registeredPlant = await ApiService.registerPlant(plant);
      if (registeredPlant != null) {
        _plant = registeredPlant;
        await CacheHelper.setString(CacheHelper.CURRENT_PLANT_ID, registeredPlant.id);
        await loadPlantData();
        _startPeriodicUpdates();
        notifyListeners();
        return true;
      } else {
        _setError('식물 등록에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 등록 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // AI 식물 등록 (시뮬레이션)
  Future<bool> registerPlantWithAI() async {
    _setLoading(true);
    _setError(null);

    try {
      // 시뮬레이션: 카메라 촬영 지연
      await Future.delayed(Duration(seconds: 1));

      if (_plantProfiles.isNotEmpty) {
        PlantProfile randomProfile = _plantProfiles[Random().nextInt(_plantProfiles.length)];

        // AI 인식 시뮬레이션
        AIIdentificationResult mockResult = AIIdentificationResult(
          species: randomProfile.species,
          confidence: 0.75 + Random().nextDouble() * 0.2, // 75-95% 정확도
          suggestedName: '내 ${randomProfile.commonName}',
          optimalSettings: {
            'optimalTempMin': randomProfile.optimalTempMin,
            'optimalTempMax': randomProfile.optimalTempMax,
            'optimalHumidityMin': randomProfile.optimalHumidityMin,
            'optimalHumidityMax': randomProfile.optimalHumidityMax,
            'optimalSoilMoistureMin': randomProfile.optimalSoilMoistureMin,
            'optimalSoilMoistureMax': randomProfile.optimalSoilMoistureMax,
            'optimalLightMin': randomProfile.optimalLightMin,
            'optimalLightMax': randomProfile.optimalLightMax,
          },
        );

        Plant aiRecognizedPlant = Plant(
          id: '', // API에서 생성됨
          name: mockResult.suggestedName,
          species: mockResult.species,
          registeredDate: DateTime.now().toString().split(' ')[0],
          optimalTempMin: mockResult.optimalSettings['optimalTempMin']!,
          optimalTempMax: mockResult.optimalSettings['optimalTempMax']!,
          optimalHumidityMin: mockResult.optimalSettings['optimalHumidityMin']!,
          optimalHumidityMax: mockResult.optimalSettings['optimalHumidityMax']!,
          optimalSoilMoistureMin: mockResult.optimalSettings['optimalSoilMoistureMin']!,
          optimalSoilMoistureMax: mockResult.optimalSettings['optimalSoilMoistureMax']!,
          optimalLightMin: mockResult.optimalSettings['optimalLightMin']!,
          optimalLightMax: mockResult.optimalSettings['optimalLightMax']!,
        );

        return await registerPlant(aiRecognizedPlant);
      } else {
        _setError('식물 프로파일을 먼저 로드해주세요.');
        return false;
      }
    } catch (e) {
      _setError('AI 인식에 실패했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 정보 업데이트
  Future<bool> updatePlant(Plant updatedPlant) async {
    if (_plant == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      Plant? result = await ApiService.updatePlant(_plant!.id, updatedPlant);
      if (result != null) {
        _plant = result;
        notifyListeners();
        return true;
      } else {
        _setError('식물 정보 업데이트에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 정보 업데이트 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 삭제
  Future<bool> deletePlant() async {
    if (_plant == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      bool success = await ApiService.deletePlant(_plant!.id);
      if (success) {
        _plant = null;
        _sensorData = null;
        _notifications.clear();
        _historicalData.clear();
        _stopPeriodicUpdates();
        await CacheHelper.remove(CacheHelper.CURRENT_PLANT_ID);
        notifyListeners();
        return true;
      } else {
        _setError('식물 삭제에 실패했습니다.');
        return false;
      }
    } catch (e) {
      _setError('식물 삭제 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 식물 데이터 로드
  Future<void> loadPlantData() async {
    if (_plant == null) return;

    try {
      _setError(null);

      // 병렬로 데이터 로드
      final results = await Future.wait([
        ApiService.getCurrentSensorData(_plant!.id),
        ApiService.getNotifications(_plant!.id),
        ApiService.getHistoricalData(_plant!.id, _selectedPeriod),
      ]);

      _sensorData = results[0] as SensorData?;
      _notifications = results[1] as List<NotificationItem>;
      _historicalData = results[2] as List<HistoricalDataPoint>;

      notifyListeners();
    } catch (e) {
      _setError('식물 데이터 로드 실패: $e');
      print('Error loading plant data: $e');
    }
  }

  // 과거 데이터 로드
  Future<void> loadHistoricalData() async {
    if (_plant == null) return;

    try {
      _setError(null);
      _historicalData = await ApiService.getHistoricalData(_plant!.id, _selectedPeriod);
      notifyListeners();
    } catch (e) {
      _setError('과거 데이터 로드 실패: $e');
      print('Error loading historical data: $e');
    }
  }

  // 기간 선택 변경
  void setSelectedPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
      loadHistoricalData();
    }
  }

  // 알림 읽음 처리
  Future<void> markNotificationAsRead(int notificationId, int index) async {
    try {
      bool success = await ApiService.markNotificationAsRead(notificationId);
      if (success && index < _notifications.length) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // 주기적 업데이트 시작 (데모용으로 더 빠른 주기)
  void _startPeriodicUpdates() {
    _stopPeriodicUpdates();
    _sensorTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_plant != null) {
        loadPlantData();
      }
    });
  }

  // 주기적 업데이트 중지
  void _stopPeriodicUpdates() {
    _sensorTimer?.cancel();
    _sensorTimer = null;
  }

  // 센서 데이터 상태 체크
  bool isValueInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  // 전체 상태 계산
  String getOverallStatus() {
    if (_sensorData == null || _plant == null) return '확인 중...';

    bool tempOk = isValueInRange(_sensorData!.temperature, _plant!.optimalTempMin, _plant!.optimalTempMax);
    bool humidityOk = isValueInRange(_sensorData!.humidity, _plant!.optimalHumidityMin, _plant!.optimalHumidityMax);
    bool soilOk = isValueInRange(_sensorData!.soilMoisture, _plant!.optimalSoilMoistureMin, _plant!.optimalSoilMoistureMax);
    bool lightOk = isValueInRange(_sensorData!.light, _plant!.optimalLightMin, _plant!.optimalLightMax);

    int okCount = [tempOk, humidityOk, soilOk, lightOk].where((x) => x).length;

    if (okCount == 4) return '아주 좋아요';
    if (okCount >= 2) return '건강해요';
    return '관심이 필요해요';
  }

  // 상태 색상 계산
  Color getOverallStatusColor() {
    String status = getOverallStatus();
    switch (status) {
      case '최적':
        return Color(0xFF2E7D32);
      case '양호':
        return Color(0xFF66BB6A);
      case '주의 필요':
        return Color(0xFFE53E3E);
      default:
        return Color(0xFF999999);
    }
  }

  // 읽지 않은 알림 수
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // 데모용 랜덤 알림 생성 (시연 중 다양한 상황 보여주기 위함)
  void generateDemoNotification() {
    if (_plant == null) return;

    List<String> demoMessages = [
      '물주기 시간이에요! 목이 마른 것 같아요',
      '햇빛이 부족해요. 밝은 곳으로 옮겨주세요',
      '습도가 조금 낮네요. 분무기로 촉촉하게 해주세요',
      '온도가 좀 맞지 않아요. 확인해주세요',
      '식물 상태가 아주 좋아요! 잘 키우고 계시네요',
      '새싹이 나올 것 같은 기분이에요',
      '식물이 행복해해요! 계속 이렇게 돌봐주세요',
    ];

    List<String> types = ['warning', 'info', 'success', 'error'];

    Random random = Random();
    String message = demoMessages[random.nextInt(demoMessages.length)];
    String type = types[random.nextInt(types.length)];

    _notifications.insert(0, NotificationItem(
      id: _notifications.length + 1,
      plantId: _plant!.id,
      type: type,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    ));

    notifyListeners();
  }

  @override
  void dispose() {
    _stopPeriodicUpdates();
    super.dispose();
  }
}