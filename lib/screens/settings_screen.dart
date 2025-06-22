import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/plant_settings_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/info_row.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<PlantProvider, SettingsProvider>(
        builder: (context, plantProvider, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 등록된 식물 섹션
                SettingsSection(
                  title: '나의 식물',
                  child: _buildPlantSection(context, plantProvider),
                ),

                SizedBox(height: 16),

                // 알림 설정 섹션
                SettingsSection(
                  title: '알림 설정',
                  child: _buildNotificationSection(context, settingsProvider),
                ),

                SizedBox(height: 16),

                // 앱 설정 섹션
                SettingsSection(
                  title: '앱 설정',
                  child: _buildAppSection(context, settingsProvider),
                ),

                SizedBox(height: 16),

                // 앱 정보 섹션
                SettingsSection(
                  title: '앱 정보',
                  child: _buildAppInfoSection(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantSection(BuildContext context, PlantProvider plantProvider) {
    if (!plantProvider.hasPlant) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 30,
                color: Color(0xFF999999),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '아직 식물 친구가 없어요',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '홈 화면에서 식물 친구를 만들어보세요',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final plant = plantProvider.plant!;
    return Column(
      children: [
        InfoRow(label: '식물 이름', value: plant.name),
        InfoRow(label: '종류', value: plant.species),
        InfoRow(label: '등록일', value: plant.registeredDate),

        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),

        Text(
          '환경 설정',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        SizedBox(height: 8),

        _buildOptimalRangeInfo(
          Icons.thermostat_outlined,
          '온도',
          '${plant.optimalTempMin.toInt()}°C - ${plant.optimalTempMax.toInt()}°C',
          Colors.red[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.water_drop_outlined,
          '습도',
          '${plant.optimalHumidityMin.toInt()}% - ${plant.optimalHumidityMax.toInt()}%',
          Colors.blue[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.opacity_outlined,
          '토양 수분',
          '${plant.optimalSoilMoistureMin.toInt()}% - ${plant.optimalSoilMoistureMax.toInt()}%',
          Colors.green[400]!,
        ),
        _buildOptimalRangeInfo(
          Icons.wb_sunny_outlined,
          '조도',
          '${plant.optimalLightMin.toInt()}% - ${plant.optimalLightMax.toInt()}%',
          Colors.orange[400]!,
        ),

        SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: plantProvider.isLoading ? null : () {
              _showPlantSettingsDialog(context);
            },
            icon: Icon(Icons.tune),
            label: Text('설정 변경하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: plantProvider.isLoading ? null : () {
              _showDeletePlantDialog(context, plantProvider);
            },
            icon: Icon(Icons.logout),
            label: Text('식물 삭제'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '식물 상태 알림받기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    settingsProvider.pushNotificationEnabled
                        ? '알림이 켜져있어요'
                        : '알림이 꺼져있어요. 켜주시면 식물을 더 잘 돌볼 수 있어요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settingsProvider.pushNotificationEnabled,
              onChanged: (value) {
                settingsProvider.togglePushNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? '알림이 켜졌어요' : '알림이 꺼졌어요'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        if (settingsProvider.error != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              settingsProvider.error!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppSection(BuildContext context, SettingsProvider settingsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '테마',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        DropdownButton<String>(
          value: settingsProvider.theme,
          underline: SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: 'light', child: Text('라이트')),
            DropdownMenuItem(value: 'dark', child: Text('다크')),
            DropdownMenuItem(value: 'system', child: Text('시스템')),
          ],
          onChanged: (value) {
            if (value != null) {
              settingsProvider.changeTheme(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('테마가 변경되었어요'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      children: [
        InfoRow(label: '앱 버전', value: '1.0.0'),
        InfoRow(label: '개발팀', value: '돌보미 팀'),
      ],
    );
  }

  Widget _buildOptimalRangeInfo(IconData icon, String label, String range, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          Spacer(),
          Text(
            range,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlantSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantSettingsDialog();
      },
    );
  }

  void _showDeletePlantDialog(BuildContext context, PlantProvider plantProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('식물 친구와 헤어지기'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정말로 식물 친구와 헤어지시겠어요?'),
              SizedBox(height: 8),
              Text(
                '다음 추억들이 모두 사라져요:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text('• 함께한 기록들'),
              Text('• 성장 데이터'),
              Text('• 소중한 알림들'),
              Text('• 환경 설정'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('아니요, 더 함께해요'),
            ),
            ElevatedButton(
              onPressed: plantProvider.isLoading ? null : () async {
                bool success = await plantProvider.deletePlant();
                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('식물이 삭제되었어요'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(plantProvider.error ?? '삭제에 실패했습니다. 다시 시도해주세요'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('헤어지기'),
            ),
          ],
        );
      },
    );
  }
}