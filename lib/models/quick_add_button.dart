import 'beverage_type.dart';

class QuickAddButton {
  final int? id;
  final int amount;
  final BeverageType type;
  final int position;

  QuickAddButton({
    this.id,
    required this.amount,
    required this.type,
    required this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index,
      'position': position,
    };
  }

  factory QuickAddButton.fromMap(Map<String, dynamic> map) {
    return QuickAddButton(
      id: map['id'],
      amount: map['amount'],
      type: BeverageType.values[map['type']],
      position: map['position'],
    );
  }
}