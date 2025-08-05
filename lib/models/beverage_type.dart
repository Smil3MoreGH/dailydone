import 'package:flutter/material.dart';

enum BeverageType {
  water('Water', Icons.water_drop, Color(0xFF4FC3F7)),
  tea('Tea', Icons.emoji_food_beverage, Color(0xFF81C784)),
  coffee('Coffee', Icons.coffee, Color(0xFF8D6E63)),
  sugarFreeDrink('Sugar-free', Icons.local_drink, Color(0xFFBA68C8)),
  sugaryDrink('Sugary', Icons.local_bar, Color(0xFFFF8A65));

  final String label;
  final IconData icon;
  final Color color;

  const BeverageType(this.label, this.icon, this.color);
}