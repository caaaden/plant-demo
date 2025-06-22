import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../providers/plant_provider.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class PlantRegistrationForm extends StatefulWidget {
  @override
  _PlantRegistrationFormState createState() => _PlantRegistrationFormState();
}

class _PlantRegistrationFormState extends State<PlantRegistrationForm> {
  String _registrationMode = 'manual';
  String _plantName = '';
  String _plantSpecies = '';
  bool _isAIProcessing = false;
  Map<String, double> _optimalSettings = {
    'optimalTempMin': 18,
    'optimalTempMax': 25,
    'optimalHumidityMin': 40,
    'optimalHumidityMax': 70,
    'optimalSoilMoistureMin': 40,
    'optimalSoilMoistureMax': 70,
    'optimalLightMin': 60,
    'optimalLightMax': 90,
  };

  void _updateOptimalSettings(List<PlantProfile> plantProfiles) {
    PlantProfile? profile = plantProfiles.firstWhere(
          (p) => p.species == _plantSpecies,
      orElse: () => PlantProfile(
        species: '',
        commonName: '',
        optimalTempMin: 18,
        optimalTempMax: 25,
        optimalHumidityMin: 40,
        optimalHumidityMax: 70,
        optimalSoilMoistureMin: 40,
        optimalSoilMoistureMax: 70,
        optimalLightMin: 60,
        optimalLightMax: 90,
        description: '',
      ),
    );

    if (profile.species.isNotEmpty) {
      setState(() {
        _optimalSettings = {
          'optimalTempMin': profile.optimalTempMin,
          'optimalTempMax': profile.optimalTempMax,
          'optimalHumidityMin': profile.optimalHumidityMin,
          'optimalHumidityMax': profile.optimalHumidityMax,
          'optimalSoilMoistureMin': profile.optimalSoilMoistureMin,
          'optimalSoilMoistureMax': profile.optimalSoilMoistureMax,
          'optimalLightMin': profile.optimalLightMin,
          'optimalLightMax': profile.optimalLightMax,
        };
      });
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_plantName.isEmpty || _plantSpecies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('식물 이름과 종류를 입력해주세요')),
      );
      return;
    }

    Plant newPlant = Plant(
      id: '', // API에서 생성됨
      name: _plantName,
      species: _plantSpecies,
      registeredDate: DateTime.now().toString().split(' ')[0],
      optimalTempMin: _optimalSettings['optimalTempMin']!,
      optimalTempMax: _optimalSettings['optimalTempMax']!,
      optimalHumidityMin: _optimalSettings['optimalHumidityMin']!,
      optimalHumidityMax: _optimalSettings['optimalHumidityMax']!,
      optimalSoilMoistureMin: _optimalSettings['optimalSoilMoistureMin']!,
      optimalSoilMoistureMax: _optimalSettings['optimalSoilMoistureMax']!,
      optimalLightMin: _optimalSettings['optimalLightMin']!,
      optimalLightMax: _optimalSettings['optimalLightMax']!,
    );

    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    bool success = await plantProvider.registerPlant(newPlant);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('식물이 등록되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(plantProvider.error ?? '등록에 실패했습니다. 다시 시도해주세요'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAIRegistration(BuildContext context) async {
    setState(() {
      _isAIProcessing = true;
    });

    try {
      // 시뮬레이션: 카메라 촬영과 AI 처리 과정
      await Future.delayed(Duration(milliseconds: 500));

      // "사진 촬영" 시뮬레이션
      bool takePhotoConfirmed = await _showTakePhotoDialog(context);
      if (!takePhotoConfirmed) {
        setState(() {
          _isAIProcessing = false;
        });
        return;
      }

      // AI 인식 처리 시뮬레이션
      await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(2000)));

      // 랜덤하게 성공/실패 시뮬레이션 (90% 성공률)
      if (Random().nextDouble() < 0.1) {
        throw Exception('식물 인식에 실패했습니다. 더 선명한 사진으로 다시 시도해주세요');
      }

      // 모의 AI 인식 결과 생성
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      List<PlantProfile> profiles = plantProvider.plantProfiles;

      if (profiles.isEmpty) {
        throw Exception('식물 데이터베이스를 불러올 수 없습니다');
      }

      PlantProfile selectedProfile = profiles[Random().nextInt(profiles.length)];
      double confidence = 0.7 + Random().nextDouble() * 0.25; // 70-95% 정확도

      Plant aiRecognizedPlant = Plant(
        id: '', // API에서 생성됨
        name: '내 ${selectedProfile.commonName}',
        species: selectedProfile.species,
        registeredDate: DateTime.now().toString().split(' ')[0],
        optimalTempMin: selectedProfile.optimalTempMin,
        optimalTempMax: selectedProfile.optimalTempMax,
        optimalHumidityMin: selectedProfile.optimalHumidityMin,
        optimalHumidityMax: selectedProfile.optimalHumidityMax,
        optimalSoilMoistureMin: selectedProfile.optimalSoilMoistureMin,
        optimalSoilMoistureMax: selectedProfile.optimalSoilMoistureMax,
        optimalLightMin: selectedProfile.optimalLightMin,
        optimalLightMax: selectedProfile.optimalLightMax,
      );

      bool success = await plantProvider.registerPlant(aiRecognizedPlant);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 인식이 완료되었습니다\n${selectedProfile.species} (정확도: ${(confidence * 100).toStringAsFixed(1)}%)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(plantProvider.error ?? '식물 등록에 실패했습니다');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI 인식 실패: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isAIProcessing = false;
      });
    }
  }

  Future<bool> _showTakePhotoDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green),
              SizedBox(width: 8),
              Text('식물 사진 찍기'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      size: 60,
                      color: Colors.green[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '식물 사진',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '식물 잎이 잘 보이도록 찍어주세요! AI가 더 정확하게 알아볼 수 있어요',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: Icon(Icons.camera_alt),
              label: Text('사진 찍기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '식물 등록',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: plantProvider.isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // 내용
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 등록 모드 선택
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isAIProcessing || plantProvider.isLoading) ? null : () {
                                  setState(() {
                                    _registrationMode = 'ai';
                                  });
                                },
                                icon: Icon(Icons.camera_alt_outlined, size: 18),
                                label: Text('AI로 찾기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _registrationMode == 'ai' ? Color(0xFF4CAF50) : Color(0xFFF5F5F5),
                                  foregroundColor: _registrationMode == 'ai' ? Colors.white : Color(0xFF666666),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_isAIProcessing || plantProvider.isLoading) ? null : () {
                                  setState(() {
                                    _registrationMode = 'manual';
                                  });
                                },
                                icon: Icon(Icons.add, size: 18),
                                label: Text('직접 등록'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _registrationMode == 'manual' ? Color(0xFF4CAF50) : Color(0xFFF5F5F5),
                                  foregroundColor: _registrationMode == 'manual' ? Colors.white : Color(0xFF666666),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        _registrationMode == 'ai'
                            ? _buildAIRegistration(context)
                            : _buildManualRegistration(context, plantProvider.plantProfiles),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAIRegistration(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(40),
            ),
            child: _isAIProcessing
                ? CircularProgressIndicator()
                : Icon(
              Icons.photo_camera,
              size: 40,
              color: Color(0xFF66BB6A),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _isAIProcessing ? 'AI가 식물을 분석하고 있습니다...' : 'AI 식물 인식',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _isAIProcessing
                ? '잠시만 기다려주세요'
                : '사진을 찍어주시면 AI가 식물을 인식해드립니다',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isAIProcessing ? null : () => _handleAIRegistration(context),
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
              _isAIProcessing ? '분석 중...' : '사진 찍기',
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

  Widget _buildManualRegistration(BuildContext context, List<PlantProfile> plantProfiles) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '식물 이름',
            hintText: '예: 우리집 몬스테라',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _plantName = value;
            });
          },
        ),

        SizedBox(height: 16),

        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: '어떤 식물인가요?',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: _plantSpecies.isEmpty ? null : _plantSpecies,
          menuMaxHeight: 250,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down),
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
          ),
          onChanged: (String? value) {
            setState(() {
              _plantSpecies = value ?? '';
            });
            _updateOptimalSettings(plantProfiles);
          },
          selectedItemBuilder: (BuildContext context) {
            return [
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '선택하세요',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...plantProfiles.map((PlantProfile profile) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${profile.species} (${profile.commonName})',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ];
          },
          items: [
            DropdownMenuItem(
              value: '',
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '선택하세요',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...plantProfiles.map((PlantProfile profile) {
              return DropdownMenuItem(
                value: profile.species,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.species,
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (profile.commonName.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          profile.commonName,
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),

        if (_plantSpecies.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildOptimalSettingsInfo(),
        ],

        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Consumer<PlantProvider>(
            builder: (context, plantProvider, child) {
              return ElevatedButton(
                onPressed: plantProvider.isLoading ? null : () => _handleSubmit(context),
                child: Text(
                  '식물 등록하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptimalSettingsInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.green[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '적정 환경 설정',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptimalInfoRow(
                  Icons.thermostat_outlined,
                  '온도',
                  '${_optimalSettings['optimalTempMin']!.toInt()}°C - ${_optimalSettings['optimalTempMax']!.toInt()}°C',
                  Colors.red[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.water_drop_outlined,
                  '습도',
                  '${_optimalSettings['optimalHumidityMin']!.toInt()}% - ${_optimalSettings['optimalHumidityMax']!.toInt()}%',
                  Colors.blue[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.opacity_outlined,
                  '토양 수분',
                  '${_optimalSettings['optimalSoilMoistureMin']!.toInt()}% - ${_optimalSettings['optimalSoilMoistureMax']!.toInt()}%',
                  Colors.green[400]!,
                ),
                SizedBox(height: 6),
                _buildOptimalInfoRow(
                  Icons.wb_sunny_outlined,
                  '조도',
                  '${_optimalSettings['optimalLightMin']!.toInt()}% - ${_optimalSettings['optimalLightMax']!.toInt()}%',
                  Colors.orange[400]!,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '나중에 설정에서 언제든 변경할 수 있습니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}