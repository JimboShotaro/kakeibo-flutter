import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('カテゴリ管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出'),
              Tab(text: '収入'),
            ],
          ),
        ),
        body: Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildCategoryList(
                  context,
                  categoryProvider.expenseCategories,
                  true,
                ),
                _buildCategoryList(
                  context,
                  categoryProvider.incomeCategories,
                  false,
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddCategory(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<AppCategory> categories,
    bool isExpense,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isExpense ? '支出カテゴリがありません' : '収入カテゴリがありません'),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        // リオーダー処理（将来実装）
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          key: Key(category.id),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category.colorValue.withAlpha(51),
              child: Icon(
                category.iconData,
                color: category.colorValue,
              ),
            ),
            title: Text(category.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openEditCategory(context, category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(context, category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CategoryFormSheet(),
    );
  }

  void _openEditCategory(BuildContext context, AppCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormSheet(category: category),
    );
  }

  Future<void> _deleteCategory(BuildContext context, AppCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${category.name}」を削除しますか？\nこのカテゴリに関連する取引も影響を受ける可能性があります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<CategoryProvider>().deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カテゴリを削除しました')),
        );
      }
    }
  }
}

class CategoryFormSheet extends StatefulWidget {
  final AppCategory? category;

  const CategoryFormSheet({super.key, this.category});

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isExpense = true;
  String _selectedIcon = 'restaurant';
  String _selectedColor = '#FF5722';
  bool _isLoading = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _isExpense = widget.category!.isExpense;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'カテゴリを編集' : 'カテゴリを追加',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 支出/収入切り替え
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('支出'),
                      selected: _isExpense,
                      onSelected: (selected) {
                        setState(() => _isExpense = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('収入'),
                      selected: !_isExpense,
                      onSelected: (selected) {
                        setState(() => _isExpense = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 名前入力
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ名',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'カテゴリ名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // アイコン選択
              Text('アイコン', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppCategory.availableIcons.length,
                  itemBuilder: (context, index) {
                    final iconName = AppCategory.availableIcons[index];
                    final isSelected = _selectedIcon == iconName;
                    final iconData = _getIconData(iconName);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: isSelected
                            ? Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')))
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedIcon = iconName);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: Icon(
                              iconData,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 色選択
              Text('色', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppCategory.availableColors.map((colorHex) {
                  final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                  final isSelected = _selectedColor == colorHex;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = colorHex);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveCategory,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? '更新' : '追加'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
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
    return iconMap[iconName] ?? Icons.category;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoryProvider = context.read<CategoryProvider>();
      const uuid = Uuid();

      final category = AppCategory(
        id: isEditing ? widget.category!.id : uuid.v4(),
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
        isExpense: _isExpense,
        sortOrder: isEditing ? widget.category!.sortOrder : 0,
      );

      if (isEditing) {
        await categoryProvider.updateCategory(category);
      } else {
        await categoryProvider.addCategory(category);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'カテゴリを更新しました' : 'カテゴリを追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
