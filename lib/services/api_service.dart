import 'dart:io';
import 'dart:convert';
import 'dart:math';

import '../models/app_models.dart';
import '../helpers/api_exception.dart';

class ApiService {
  // 더미 데이터 저장용
  static Plant? _currentPlant;
  static List<SensorData> _sensorDataHistory = [];
  static List<NotificationItem> _notifications = [];
  static Settings? _userSettings;
  static Random _random = Random();

  // 시뮬레이션을 위한 타이머 카운터
  static int _timeCounter = 0;

  // 식물 등록
  static Future<Plant?> registerPlant(Plant plant) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));

    try {
      // 고유 ID 생성
      String plantId = 'plant_${DateTime.now().millisecondsSinceEpoch}';

      _currentPlant = plant.copyWith(id: plantId);

      // 초기 센서 데이터 생성
      _generateInitialSensorData(plantId);

      // 환영 알림 생성
      _notifications.add(NotificationItem(
        id: _notifications.length + 1,
        plantId: plantId,
        type: 'success',
        message: '${plant.name}과(와) 함께하는 여행이 시작되었어요!',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      return _currentPlant;
    } catch (e) {
      throw ApiException('식물 등록에 실패했습니다: $e');
    }
  }

  // 식물 정보 조회
  static Future<Plant?> getPlant(String plantId) async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
    return _currentPlant;
  }

  // 식물 정보 수정
  static Future<Plant?> updatePlant(String plantId, Plant plant) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    if (_currentPlant != null) {
      _currentPlant = plant;

      // 설정 변경 알림
      _notifications.add(NotificationItem(
        id: _notifications.length + 1,
        plantId: plantId,
        type: 'info',
        message: '${plant.name}의 환경 설정을 새롭게 조정했어요',
        timestamp: DateTime.now(),
        isRead: false,
      ));

      return _currentPlant;
    }
    return null;
  }

  // 식물 삭제
  static Future<bool> deletePlant(String plantId) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    _currentPlant = null;
    _sensorDataHistory.clear();
    _notifications.clear();

    return true;
  }

  // 현재 센서 데이터 조회
  static Future<SensorData?> getCurrentSensorData(String plantId) async {
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    if (_currentPlant == null) return null;

    // 현실적인 센서 데이터 생성
    SensorData currentData = _generateRealisticSensorData(plantId);

    // 히스토리에 추가 (최근 100개만 유지)
    _sensorDataHistory.add(currentData);
    if (_sensorDataHistory.length > 100) {
      _sensorDataHistory.removeAt(0);
    }

    // 센서 값이 최적 범위를 벗어나면 경고 알림 생성
    _checkAndGenerateWarnings(currentData);

    return currentData;
  }

  // 과거 센서 데이터 조회
  static Future<List<HistoricalDataPoint>> getHistoricalData(String plantId, String period) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));

    if (_currentPlant == null) return [];

    int dataPoints;
    int intervalMinutes;
    DateTime startTime;

    switch (period) {
      case '24h':
        dataPoints = 48; // 30분 간격
        intervalMinutes = 30;
        startTime = DateTime.now().subtract(Duration(hours: 24));
        break;
      case '7d':
        dataPoints = 42; // 4시간 간격
        intervalMinutes = 240;
        startTime = DateTime.now().subtract(Duration(days: 7));
        break;
      case '30d':
        dataPoints = 30; // 1일 간격
        intervalMinutes = 1440;
        startTime = DateTime.now().subtract(Duration(days: 30));
        break;
      case '90d':
        dataPoints = 45; // 2일 간격
        intervalMinutes = 2880;
        startTime = DateTime.now().subtract(Duration(days: 90));
        break;
      default:
        dataPoints = 24;
        intervalMinutes = 60;
        startTime = DateTime.now().subtract(Duration(hours: 24));
    }

    List<HistoricalDataPoint> historicalData = [];

    for (int i = 0; i < dataPoints; i++) {
      DateTime timestamp = startTime.add(Duration(minutes: intervalMinutes * i));

      // 시간대별로 다른 패턴 적용
      double timeOfDayFactor = _getTimeOfDayFactor(timestamp.hour);
      double seasonalFactor = _getSeasonalFactor(timestamp);

      historicalData.add(HistoricalDataPoint(
        id: 'hist_${timestamp.millisecondsSinceEpoch}',
        plantId: plantId,
        date: timestamp.toString().split(' ')[0],
        time: timestamp.hour * 60 + timestamp.minute,
        temperature: _generateVariantValue(22, 4, timeOfDayFactor * seasonalFactor),
        humidity: _generateVariantValue(55, 10, timeOfDayFactor),
        soilMoisture: _generateVariantValue(50, 8, 1.0),
        light: _generateVariantValue(65, 15, timeOfDayFactor),
      ));
    }

    return historicalData;
  }

  // 알림 목록 조회
  static Future<List<NotificationItem>> getNotifications(String plantId, {int limit = 10, int offset = 0, bool unreadOnly = false}) async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));

    List<NotificationItem> filteredNotifications = _notifications
        .where((n) => n.plantId == plantId)
        .toList();

    if (unreadOnly) {
      filteredNotifications = filteredNotifications.where((n) => !n.isRead).toList();
    }

    // 최신순 정렬
    filteredNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 페이지네이션
    int start = offset;
    int end = (offset + limit).clamp(0, filteredNotifications.length);

    return filteredNotifications.sublist(start, end);
  }

  // 알림 읽음 처리
  static Future<bool> markNotificationAsRead(int notificationId) async {
    await Future.delayed(Duration(milliseconds: 100));

    int index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      return true;
    }
    return false;
  }

  // 사용자 설정 조회
  static Future<Settings?> getSettings() async {
    await Future.delayed(Duration(milliseconds: 200));

    _userSettings ??= Settings(
      userId: 'demo_user',
      pushNotificationEnabled: true,
      language: 'ko',
      theme: 'system', // 기본값을 system으로 변경
    );

    return _userSettings;
  }

  // 사용자 설정 업데이트
  static Future<Settings?> updateSettings(Settings settings) async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    _userSettings = settings;
    return _userSettings;
  }

  // 식물 프로파일 목록 조회
  static Future<List<PlantProfile>> getPlantProfiles() async {
    await Future.delayed(Duration(milliseconds: 500));

    return [
      PlantProfile(
        species: 'Monstera deliciosa',
        commonName: '몬스테라',
        optimalTempMin: 18,
        optimalTempMax: 25,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 40,
        optimalSoilMoistureMax: 60,
        optimalLightMin: 40,
        optimalLightMax: 70,
        description: '실내에서 기르기 쉬운 대형 관엽식물',
      ),
      PlantProfile(
        species: 'Pothos aureus',
        commonName: '포토스',
        optimalTempMin: 16,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 30,
        optimalSoilMoistureMax: 50,
        optimalLightMin: 30,
        optimalLightMax: 60,
        description: '초보자도 키우기 쉬운 덩굴성 식물',
      ),
      PlantProfile(
        species: 'Sansevieria trifasciata',
        commonName: '산세베리아',
        optimalTempMin: 15,
        optimalTempMax: 28,
        optimalHumidityMin: 30,
        optimalHumidityMax: 50,
        optimalSoilMoistureMin: 20,
        optimalSoilMoistureMax: 40,
        optimalLightMin: 20,
        optimalLightMax: 80,
        description: '공기정화 효과가 뛰어난 다육식물',
      ),
      PlantProfile(
        species: 'Ficus elastica',
        commonName: '고무나무',
        optimalTempMin: 18,
        optimalTempMax: 26,
        optimalHumidityMin: 45,
        optimalHumidityMax: 65,
        optimalSoilMoistureMin: 35,
        optimalSoilMoistureMax: 55,
        optimalLightMin: 50,
        optimalLightMax: 80,
        description: '광택이 나는 큰 잎이 특징인 관엽식물',
      ),
      PlantProfile(
        species: 'Dracaena fragrans',
        commonName: '드라세나',
        optimalTempMin: 16,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 30,
        optimalSoilMoistureMax: 50,
        optimalLightMin: 30,
        optimalLightMax: 70,
        description: '줄무늬 잎이 아름다운 실내식물',
      ),
      PlantProfile(
        species: 'Spathiphyllum wallisii',
        commonName: '스파티필름',
        optimalTempMin: 18,
        optimalTempMax: 25,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 50,
        optimalSoilMoistureMax: 70,
        optimalLightMin: 20,
        optimalLightMax: 50,
        description: '하얀 꽃이 피는 공기정화 식물',
      ),
      PlantProfile(
        species: 'Chlorophytum comosum',
        commonName: '스파이더 플랜트',
        optimalTempMin: 15,
        optimalTempMax: 24,
        optimalHumidityMin: 40,
        optimalHumidityMax: 60,
        optimalSoilMoistureMin: 35,
        optimalSoilMoistureMax: 55,
        optimalLightMin: 40,
        optimalLightMax: 80,
        description: '줄무늬 잎과 작은 새싹이 매력적인 식물',
      ),
      PlantProfile(
        species: 'Philodendron hederaceum',
        commonName: '필로덴드론',
        optimalTempMin: 18,
        optimalTempMax: 27,
        optimalHumidityMin: 50,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 40,
        optimalSoilMoistureMax: 60,
        optimalLightMin: 30,
        optimalLightMax: 60,
        description: '하트 모양 잎이 아름다운 덩굴식물',
      ),
      PlantProfile(
        species: 'Aloe vera',
        commonName: '알로에',
        optimalTempMin: 16,
        optimalTempMax: 30,
        optimalHumidityMin: 20,
        optimalHumidityMax: 40,
        optimalSoilMoistureMin: 15,
        optimalSoilMoistureMax: 35,
        optimalLightMin: 60,
        optimalLightMax: 90,
        description: '약용으로도 사용되는 다육식물',
      ),
      PlantProfile(
        species: 'Zamioculcas zamiifolia',
        commonName: 'ZZ 플랜트',
        optimalTempMin: 15,
        optimalTempMax: 26,
        optimalHumidityMin: 30,
        optimalHumidityMax: 50,
        optimalSoilMoistureMin: 20,
        optimalSoilMoistureMax: 40,
        optimalLightMin: 20,
        optimalLightMax: 70,
        description: '물을 적게 줘도 되는 초보자용 식물',
      ),
    ];
  }

  // AI 식물 인식 (시뮬레이션)
  static Future<AIIdentificationResult?> identifyPlant(File imageFile) async {
    // AI 처리 시뮬레이션
    await Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(3000)));

    try {
      // 랜덤하게 식물 선택
      List<PlantProfile> profiles = await getPlantProfiles();
      PlantProfile selectedProfile = profiles[_random.nextInt(profiles.length)];

      // 인식 정확도 시뮬레이션
      double confidence = 0.7 + _random.nextDouble() * 0.25; // 70-95%

      return AIIdentificationResult(
        species: selectedProfile.species,
        confidence: confidence,
        suggestedName: '내 ${selectedProfile.commonName}',
        optimalSettings: {
          'optimalTempMin': selectedProfile.optimalTempMin,
          'optimalTempMax': selectedProfile.optimalTempMax,
          'optimalHumidityMin': selectedProfile.optimalHumidityMin,
          'optimalHumidityMax': selectedProfile.optimalHumidityMax,
          'optimalSoilMoistureMin': selectedProfile.optimalSoilMoistureMin,
          'optimalSoilMoistureMax': selectedProfile.optimalSoilMoistureMax,
          'optimalLightMin': selectedProfile.optimalLightMin,
          'optimalLightMax': selectedProfile.optimalLightMax,
        },
      );
    } catch (e) {
      // 가끔 인식 실패 시뮬레이션
      if (_random.nextDouble() < 0.1) {
        return null;
      }
      rethrow;
    }
  }

  // === 헬퍼 메서드들 ===

  static void _generateInitialSensorData(String plantId) {
    // 초기 센서 데이터 10개 생성
    DateTime now = DateTime.now();
    for (int i = 9; i >= 0; i--) {
      SensorData data = SensorData(
        id: 'sensor_${now.millisecondsSinceEpoch - (i * 30000)}',
        plantId: plantId,
        temperature: _generateVariantValue(22, 3, 1.0),
        humidity: _generateVariantValue(55, 8, 1.0),
        soilMoisture: _generateVariantValue(50, 6, 1.0),
        light: _generateVariantValue(65, 12, 1.0),
        timestamp: now.subtract(Duration(minutes: i * 30)),
      );
      _sensorDataHistory.add(data);
    }
  }

  static SensorData _generateRealisticSensorData(String plantId) {
    _timeCounter++;
    DateTime now = DateTime.now();

    // 시간대별 변화 요소
    double timeOfDayFactor = _getTimeOfDayFactor(now.hour);

    return SensorData(
      id: 'sensor_${now.millisecondsSinceEpoch}',
      plantId: plantId,
      temperature: _generateVariantValue(22, 3, timeOfDayFactor),
      humidity: _generateVariantValue(55, 8, 1.0),
      soilMoisture: _generateVariantValue(50, 6, 1.0 - (_timeCounter * 0.002)), // 시간이 지나면서 서서히 감소
      light: _generateVariantValue(65, 12, timeOfDayFactor),
      timestamp: now,
    );
  }

  static double _generateVariantValue(double base, double variance, double factor) {
    double randomOffset = (_random.nextDouble() - 0.5) * variance * 2;
    double value = (base + randomOffset) * factor;
    return value.clamp(0, 100);
  }

  static double _getTimeOfDayFactor(int hour) {
    // 낮에는 높고 밤에는 낮은 값
    if (hour >= 6 && hour <= 18) {
      return 1.0 + (sin((hour - 6) * pi / 12) * 0.3); // 0.7 ~ 1.3
    } else {
      return 0.7; // 밤시간
    }
  }

  static double _getSeasonalFactor(DateTime date) {
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    double seasonalCycle = sin((dayOfYear / 365.0) * 2 * pi);
    return 1.0 + (seasonalCycle * 0.2); // 계절별 0.8 ~ 1.2 배 변화
  }

  static void _checkAndGenerateWarnings(SensorData data) {
    if (_currentPlant == null) return;

    Plant plant = _currentPlant!;
    DateTime now = DateTime.now();

    // 온도 체크
    if (data.temperature < plant.optimalTempMin || data.temperature > plant.optimalTempMax) {
      if (_shouldGenerateWarning('temperature')) {
        _notifications.add(NotificationItem(
          id: _notifications.length + 1,
          plantId: plant.id,
          type: 'warning',
          message: '온도가 좀 맞지 않아요 (${data.temperature.toStringAsFixed(1)}°C). 적정 온도는 ${plant.optimalTempMin.toInt()}-${plant.optimalTempMax.toInt()}°C예요',
          timestamp: now,
          isRead: false,
        ));
      }
    }

    // 습도 체크
    if (data.humidity < plant.optimalHumidityMin || data.humidity > plant.optimalHumidityMax) {
      if (_shouldGenerateWarning('humidity')) {
        _notifications.add(NotificationItem(
          id: _notifications.length + 1,
          plantId: plant.id,
          type: 'warning',
          message: '습도를 조금 조절해주세요 (${data.humidity.toStringAsFixed(0)}%). 적정 습도는 ${plant.optimalHumidityMin.toInt()}-${plant.optimalHumidityMax.toInt()}%예요',
          timestamp: now,
          isRead: false,
        ));
      }
    }

    // 토양 수분 체크
    if (data.soilMoisture < plant.optimalSoilMoistureMin) {
      if (_shouldGenerateWarning('soil_low')) {
        _notifications.add(NotificationItem(
          id: _notifications.length + 1,
          plantId: plant.id,
          type: 'error',
          message: '목이 말라해요! 물을 주시겠어요? (현재 ${data.soilMoisture.toStringAsFixed(0)}%)',
          timestamp: now,
          isRead: false,
        ));
      }
    } else if (data.soilMoisture > plant.optimalSoilMoistureMax) {
      if (_shouldGenerateWarning('soil_high')) {
        _notifications.add(NotificationItem(
          id: _notifications.length + 1,
          plantId: plant.id,
          type: 'warning',
          message: '흙이 너무 촉촉해요 (${data.soilMoisture.toStringAsFixed(0)}%). 조금 말려주세요',
          timestamp: now,
          isRead: false,
        ));
      }
    }

    // 조도 체크
    if (data.light < plant.optimalLightMin) {
      if (_shouldGenerateWarning('light_low')) {
        _notifications.add(NotificationItem(
          id: _notifications.length + 1,
          plantId: plant.id,
          type: 'info',
          message: '햇빛이 부족해요 (${data.light.toStringAsFixed(0)}%). 밝은 곳으로 옮겨주세요',
          timestamp: now,
          isRead: false,
        ));
      }
    }
  }

  // 중복 알림 방지를 위한 체크
  static Map<String, DateTime> _lastWarningTimes = {};

  static bool _shouldGenerateWarning(String type) {
    DateTime now = DateTime.now();
    DateTime? lastTime = _lastWarningTimes[type];

    if (lastTime == null || now.difference(lastTime).inMinutes >= 30) {
      _lastWarningTimes[type] = now;
      return true;
    }
    return false;
  }
}