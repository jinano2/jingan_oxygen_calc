
import 'package:flutter/material.dart';

void main() {
  runApp(const OxygenApp());
}

class OxygenApp extends StatelessWidget {
  const OxygenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '京安救護氧氣計算',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        fontFamily: null, // 交給系統字型處理，支援繁體中文
      ),
      home: const OxygenCalculatorPage(),
    );
  }
}

class OxygenTank {
  final String name;
  final double fullPressure; // 滿瓶壓力 (bar)
  final double capacityL; // 滿瓶容量 (L)
  final double reservePressure; // 預留壓力 (bar)

  const OxygenTank({
    required this.name,
    required this.fullPressure,
    required this.capacityL,
    this.reservePressure = 10,
  });

  /// 可用容量 (扣掉預留壓力後可用的 L)
  double usableVolume(double currentPressure) {
    final p =
        (currentPressure - reservePressure).clamp(0, fullPressure).toDouble();
    return p / fullPressure * capacityL;
  }

  /// 回傳剩餘時間 (Duration)
  Duration remainTime(double currentPressure, double flowLpm) {
    final vol = usableVolume(currentPressure); // L
    if (flowLpm <= 0) return Duration.zero;
    final minutes = vol / flowLpm;
    if (minutes.isNaN || minutes.isInfinite || minutes <= 0) {
      return Duration.zero;
    }
    return Duration(minutes: minutes.floor());
  }
}

class OxygenCalculatorPage extends StatefulWidget {
  const OxygenCalculatorPage({super.key});

  @override
  State<OxygenCalculatorPage> createState() => _OxygenCalculatorPageState();
}

class _OxygenCalculatorPageState extends State<OxygenCalculatorPage> {
  // 預設幾種常用瓶型（數值你可以之後依實際調整）
  static const presetTanks = <OxygenTank>[
    OxygenTank(
      name: 'D瓶',
      fullPressure: 200,
      capacityL: 425,
      reservePressure: 10,
    ),
    OxygenTank(
      name: 'Jumbo',
      fullPressure: 200,
      capacityL: 600,
      reservePressure: 10,
    ),
    OxygenTank(
      name: 'M瓶',
      fullPressure: 200,
      capacityL: 3450,
      reservePressure: 10,
    ),
  ];

  String _selectedTankName = 'D瓶';
  final TextEditingController _pressureController =
      TextEditingController(text: '140');
  final TextEditingController _flowController =
      TextEditingController(text: '10');

  // 自訂瓶型的欄位
  final TextEditingController _customFullPressureController =
      TextEditingController(text: '200');
  final TextEditingController _customCapacityController =
      TextEditingController(text: '600');
  final TextEditingController _customReserveController =
      TextEditingController(text: '10');

  @override
  void dispose() {
    _pressureController.dispose();
    _flowController.dispose();
    _customFullPressureController.dispose();
    _customCapacityController.dispose();
    _customReserveController.dispose();
    super.dispose();
  }

  OxygenTank _currentTank() {
    if (_selectedTankName == '自訂瓶型') {
      final fullP = double.tryParse(_customFullPressureController.text) ?? 200;
      final cap = double.tryParse(_customCapacityController.text) ?? 600;
      final reserve = double.tryParse(_customReserveController.text) ?? 10;
      return OxygenTank(
        name: '自訂瓶型',
        fullPressure: fullP,
        capacityL: cap,
        reservePressure: reserve,
      );
    }
    return presetTanks.firstWhere(
      (t) => t.name == _selectedTankName,
      orElse: () => presetTanks.first,
    );
  }

  double _currentPressure() {
    return double.tryParse(_pressureController.text) ?? 0;
  }

  double _currentFlow() {
    return double.tryParse(_flowController.text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final tank = _currentTank();
    final pressure = _currentPressure();
    final flow = _currentFlow();
    final usableVolume = tank.usableVolume(pressure);
    final remain = tank.remainTime(pressure, flow);

    final hours = remain.inHours;
    final minutes = remain.inMinutes.remainder(60);

    // 顏色提示
    final totalMinutes = remain.inMinutes;
    Color timeColor;
    if (totalMinutes <= 0) {
      timeColor = Colors.grey;
    } else if (totalMinutes < 20) {
      timeColor = Colors.red;
    } else if (totalMinutes < 60) {
      timeColor = Colors.orange;
    } else {
      timeColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('京安救護氧氣計算'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 氧氣瓶種類選擇
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '氧氣瓶種類',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedTankName,
                      isExpanded: true,
                      items: [
                        ...presetTanks
                            .map((t) => DropdownMenuItem(
                                  value: t.name,
                                  child: Text(t.name),
                                ))
                            .toList(),
                        const DropdownMenuItem(
                          value: '自訂瓶型',
                          child: Text('自訂瓶型'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedTankName = value;
                        });
                      },
                    ),
                    if (_selectedTankName == '自訂瓶型') ...[
                      const SizedBox(height: 12),
                      const Text(
                        '自訂瓶型設定',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              label: '滿瓶壓力 (bar)',
                              controller: _customFullPressureController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberField(
                              label: '總容量 (L)',
                              controller: _customCapacityController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildNumberField(
                        label: '預留壓力 (bar)',
                        controller: _customReserveController,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 目前壓力 + 流量
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '當前設定',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: '目前壓力 (bar)',
                            controller: _pressureController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberField(
                            label: '流量 (L/min)',
                            controller: _flowController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '瓶型：${tank.name} | 滿瓶壓力：${tank.fullPressure.toStringAsFixed(0)} bar | 容量：${tank.capacityL.toStringAsFixed(0)} L | 預留：${tank.reservePressure.toStringAsFixed(0)} bar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 結果顯示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '計算結果',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '可用容量：約 ${usableVolume.isNaN || usableVolume.isInfinite ? '-' : usableVolume.toStringAsFixed(0)} L',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      totalMinutes <= 0
                          ? '剩餘時間：--'
                          : '剩餘時間：$hours 小時 $minutes 分鐘',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: timeColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalMinutes <= 0)
                      const Text(
                        '請確認輸入壓力 / 流量是否正確',
                        style: TextStyle(fontSize: 14),
                      )
                    else if (totalMinutes < 20)
                      const Text(
                        '⚠ 氧氣即將用盡，請注意！',
                        style: TextStyle(fontSize: 14),
                      )
                    else if (totalMinutes < 60)
                      const Text(
                        '⚠ 剩餘時間中等，請留意後續使用時間。',
                        style: TextStyle(fontSize: 14),
                      )
                    else
                      const Text(
                        '✅ 氧氣剩餘時間充足。',
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) {
        setState(() {}); // 每次輸入就重新計算
      },
    );
  }
}
