import 'package:flutter/material.dart';

class CategoryPill extends StatelessWidget {
  final String category;
  const CategoryPill(this.category, {Key? key}) : super(key: key);

  Color get _color {
    if (category.contains('Siaga')) return Colors.redAccent;
    if (category.contains('Standar')) return Colors.orange;
    if (category.contains('Ideal')) return Colors.teal;
    if (category.contains('Agresif')) return Colors.purpleAccent;
    return Colors.pinkAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(category, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}