import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/plant_provider.dart';
import '../widgets/period_selector.dart';
import '../widgets/chart_legend.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        if (!plantProvider.hasPlant) {
          return _buildNoPlantWidget();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '성장 기록 📊',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // 기간 선택 카드
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '조회 기간',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16),
                      PeriodSelector(
                        selectedPeriod: plantProvider.selectedPeriod,
                        onPeriodChanged: plantProvider.setSelectedPeriod,
                        isLoading: plantProvider.isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // 차트 카드
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '센서 데이터 변화',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (plantProvider.isLoading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // 차트
                      Container(
                        height: 300,
                        child: _buildChart(context, plantProvider),
                      ),

                      SizedBox(height: 16),

                      // 범례
                      ChartLegend(),

                      if (plantProvider.error != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  plantProvider.error!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 데이터 요약 카드
              if (plantProvider.historicalData.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDataSummaryCard(plantProvider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoPlantWidget() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              size: 30,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 16),
          Text(
            '등록된 식물이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            '홈 화면에서 식물을 등록해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, PlantProvider plantProvider) {
    if (plantProvider.isLoading && plantProvider.historicalData.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (plantProvider.historicalData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '선택한 기간에 데이터가 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다른 기간을 선택해보세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 20,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 &&
                    index < plantProvider.historicalData.length &&
                    index % _getDateInterval(plantProvider.historicalData.length) == 0) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateLabel(plantProvider.historicalData[index].date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // 온도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.temperature);
            }).toList(),
            isCurved: true,
            color: Colors.red[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 습도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.humidity);
            }).toList(),
            isCurved: true,
            color: Colors.blue[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 토양 수분 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.soilMoisture);
            }).toList(),
            isCurved: true,
            color: Colors.green[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // 조도 라인
          LineChartBarData(
            spots: plantProvider.historicalData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.light);
            }).toList(),
            isCurved: true,
            color: Colors.orange[400]!,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard(PlantProvider plantProvider) {
    final data = plantProvider.historicalData;
    if (data.isEmpty) return SizedBox.shrink();

    // 평균값 계산
    final avgTemp = data.map((e) => e.temperature).reduce((a, b) => a + b) / data.length;
    final avgHumidity = data.map((e) => e.humidity).reduce((a, b) => a + b) / data.length;
    final avgSoil = data.map((e) => e.soilMoisture).reduce((a, b) => a + b) / data.length;
    final avgLight = data.map((e) => e.light).reduce((a, b) => a + b) / data.length;

    // 최대/최소값
    final maxTemp = data.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);
    final minTemp = data.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '데이터 요약 (${plantProvider.selectedPeriod})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '평균 온도',
                    '${avgTemp.toStringAsFixed(1)}°C',
                    Icons.thermostat_outlined,
                    Colors.red[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '평균 습도',
                    '${avgHumidity.toStringAsFixed(0)}%',
                    Icons.water_drop_outlined,
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '평균 토양수분',
                    '${avgSoil.toStringAsFixed(0)}%',
                    Icons.opacity_outlined,
                    Colors.green[400]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '평균 조도',
                    '${avgLight.toStringAsFixed(0)}%',
                    Icons.wb_sunny_outlined,
                    Colors.orange[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getDateInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 30) return 5;
    if (dataLength <= 100) return 10;
    return 20;
  }

  String _formatDateLabel(String date) {
    try {
      final DateTime dateTime = DateTime.parse(date);
      return '${dateTime.month}/${dateTime.day}';
    } catch (e) {
      return date;
    }
  }
}