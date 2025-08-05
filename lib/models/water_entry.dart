import 'beverage_type.dart';

class WaterEntry {
  final int? id;
  final DateTime timestamp;
  final int amount; // in milliliters
  final BeverageType type;

  WaterEntry({
    this.id,
    required this.timestamp,
    required this.amount,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'amount': amount,
      'type': type.index,
    };
  }

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      amount: map['amount'],
      type: BeverageType.values[map['type']],
    );
  }
}