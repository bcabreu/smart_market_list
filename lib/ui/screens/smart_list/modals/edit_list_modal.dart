import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/data/models/shopping_list.dart';
import 'package:smart_market_list/providers/shopping_list_provider.dart';
import 'package:uuid/uuid.dart';

class EditListModal extends ConsumerStatefulWidget {
  final ShoppingList? list; // If null, create new list

  const EditListModal({super.key, this.list});

  @override
  ConsumerState<EditListModal> createState() => _EditListModalState();
}

class _EditListModalState extends ConsumerState<EditListModal> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedEmoji = '🛒';

  final List<String> _emojis = ['🛒', '🏠', '🎉', '🥩', '🥦', '💊', '🎁', '✈️'];

  @override
  void initState() {
    super.initState();
    if (widget.list != null) {
      _nameController.text = widget.list!.name;
      _budgetController.text = widget.list!.budget.toStringAsFixed(2);
      _selectedEmoji = widget.list!.emoji;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.isNotEmpty) {
      final name = _nameController.text;
      final budget = double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0.0;
      
      final service = ref.read(shoppingListServiceProvider);

      if (widget.list != null) {
        // Update
        final updatedList = ShoppingList(
          id: widget.list!.id,
          name: name,
          emoji: _selectedEmoji,
          budget: budget,
          items: widget.list!.items,
          createdAt: widget.list!.createdAt,
        );
        service.updateList(updatedList);
      } else {
        // Create
        final newList = ShoppingList(
          id: Uuid().v4(),
          name: name,
          emoji: _selectedEmoji,
          budget: budget,
          items: [],
          createdAt: DateTime.now(),
        );
        service.createList(newList);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.list != null ? 'Editar Lista' : 'Nova Lista',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Emoji Selector
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da Lista',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Orçamento (R\$)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(widget.list != null ? 'Salvar Alterações' : 'Criar Lista'),
            ),
          ),
        ],
      ),
    );
  }
}
