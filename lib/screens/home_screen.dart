import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/plant_registration_form.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (plantProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (plantProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    plantProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => plantProvider.loadPlantData(),
                  child: Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // 식물이 없을 때와 있을 때 분기
              plantProvider.hasPlant
                  ? _buildPlantInfoWidget(context, plantProvider)
                  : _buildNoPlantWidget(context, plantProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPlantWidget(BuildContext context, PlantProvider plantProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100, // 80에서 100으로 증가
            height: 100, // 80에서 100으로 증가
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(50), // 40에서 50으로 증가
            ),
            child: Icon(
              Icons.eco_outlined,
              size: 50, // 40에서 50으로 증가
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 24),
          Text(
            '아직 식물 친구가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 식물 친구를 만나볼까요?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: plantProvider.isLoading ? null : () {
              _showPlantRegistrationDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '식물 친구 만들기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantInfoWidget(BuildContext context, PlantProvider plantProvider) {
    final plant = plantProvider.plant!;
    final sensorData = plantProvider.sensorData;

    if (sensorData == null) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('센서 데이터를 불러오는 중...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 식물 정보 카드
        Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          plant.species,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56, // 48에서 56으로 증가
                      height: 56, // 48에서 56으로 증가
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(28), // 24에서 28로 증가
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        size: 32, // 28에서 32로 증가
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '함께한 지 ${_calculateDaysSinceRegistration(plant.registeredDate)}일째',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '우리 식물 컨디션',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: plantProvider.getOverallStatusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: plantProvider.getOverallStatusColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        plantProvider.getOverallStatus(),
                        style: TextStyle(
                          color: plantProvider.getOverallStatusColor(),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 20),

        // 센서 데이터 그리드
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            SensorCard(
              icon: Icons.thermostat_outlined,
              color: Color(0xFFE57373),
              title: '온도',
              value: '${sensorData.temperature.toStringAsFixed(1)}°C',
              optimal: '적정 온도 ${plant.optimalTempMin.toInt()}-${plant.optimalTempMax.toInt()}°C',
              isOptimal: plantProvider.isValueInRange(
                sensorData.temperature,
                plant.optimalTempMin,
                plant.optimalTempMax,
              ),
            ),
            SensorCard(
              icon: Icons.water_drop_outlined,
              color: Color(0xFF64B5F6),
              title: '습도',
              value: '${sensorData.humidity.toStringAsFixed(0)}%',
              optimal: '적정 습도 ${plant.optimalHumidityMin.toInt()}-${plant.optimalHumidityMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.humidity,
                plant.optimalHumidityMin,
                plant.optimalHumidityMax,
              ),
            ),
            SensorCard(
              icon: Icons.opacity_outlined,
              color: Color(0xFF81C784),
              title: '흙 수분',
              value: '${sensorData.soilMoisture.toStringAsFixed(0)}%',
              optimal: '적정 수분 ${plant.optimalSoilMoistureMin.toInt()}-${plant.optimalSoilMoistureMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.soilMoisture,
                plant.optimalSoilMoistureMin,
                plant.optimalSoilMoistureMax,
              ),
            ),
            SensorCard(
              icon: Icons.wb_sunny_outlined,
              color: Color(0xFFFFB74D),
              title: '햇빛',
              value: '${sensorData.light.toStringAsFixed(0)}%',
              optimal: '적정 조도 ${plant.optimalLightMin.toInt()}-${plant.optimalLightMax.toInt()}%',
              isOptimal: plantProvider.isValueInRange(
                sensorData.light,
                plant.optimalLightMin,
                plant.optimalLightMax,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // 상태 카드는 이제 식물 정보 카드에 통합되었으므로 제거
      ],
    );
  }

  void _showPlantRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PlantRegistrationForm();
      },
    );
  }

  int _calculateDaysSinceRegistration(String registeredDate) {
    try {
      DateTime registered = DateTime.parse(registeredDate);
      DateTime now = DateTime.now();
      return now.difference(registered).inDays + 1; // +1을 해서 등록일도 1일째로 계산
    } catch (e) {
      return 1; // 파싱 실패 시 기본값
    }
  }
}