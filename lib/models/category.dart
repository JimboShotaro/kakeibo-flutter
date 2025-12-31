import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isExpense;
  final int sortOrder;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.sortOrder = 0,
  });

  /// アイコン名からIconDataを取得
  IconData get iconData {
    return _iconMap[icon] ?? Icons.category;
  }

  /// カラーコードからColorを取得
  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// データベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_expense': isExpense ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// MapからAppCategoryを生成
  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      isExpense: map['is_expense'] == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// コピーを作成
  AppCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isExpense,
    int? sortOrder,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isExpense: isExpense ?? this.isExpense,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// アイコン名とIconDataのマッピング
  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_cart': Icons.shopping_cart,
    'sports_esports': Icons.sports_esports,
    'local_hospital': Icons.local_hospital,
    'phone': Icons.phone,
    'bolt': Icons.bolt,
    'more_horiz': Icons.more_horiz,
    'account_balance_wallet': Icons.account_balance_wallet,
    'attach_money': Icons.attach_money,
    'home': Icons.home,
    'school': Icons.school,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'fitness_center': Icons.fitness_center,
    'local_cafe': Icons.local_cafe,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'card_giftcard': Icons.card_giftcard,
    'work': Icons.work,
    'savings': Icons.savings,
  };

  /// 利用可能なアイコン一覧
  static List<String> get availableIcons => _iconMap.keys.toList();

  /// 利用可能な色一覧
  static const List<String> availableColors = [
    '#FF5722', // Deep Orange
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#FFC107', // Amber
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
    '#3F51B5', // Indigo
    '#8BC34A', // Light Green
    '#FF9800', // Orange
  ];
}
