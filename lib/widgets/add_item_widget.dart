import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form that creates a [BillingItem]. It owns its controllers and validates
/// inline, so the billing screen only receives finished, valid items.
class AddItemWidget extends StatefulWidget {
  final ValueChanged<BillingItem> onAddItem;

  const AddItemWidget({super.key, required this.onAddItem});

  @override
  State<AddItemWidget> createState() => _AddItemWidgetState();
}

class _AddItemWidgetState extends State<AddItemWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onAddItem(
      BillingItem(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
      ),
    );

    _nameController.clear();
    _priceController.clear();
    _quantityController.text = '1';
    _formKey.currentState?.reset();
    _nameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final nameField = TextFormField(
      controller: _nameController,
      focusNode: _nameFocus,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 60,
      buildCounter: _noCounter,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Enter an item name' : null,
      decoration: const InputDecoration(
        labelText: 'Item name',
        hintText: 'e.g. Basmati Rice 5kg',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
    );

    final priceField = TextFormField(
      controller: _priceController,
      textInputAction: TextInputAction.next,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,8}\.?\d{0,2}')),
      ],
      validator: (v) {
        final value = double.tryParse(v ?? '');
        if (value == null || value <= 0) return 'Enter a price';
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Price',
        hintText: '0.00',
        prefixIcon: Icon(Icons.currency_rupee),
      ),
    );

    final quantityField = TextFormField(
      controller: _quantityController,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 5,
      buildCounter: _noCounter,
      onFieldSubmitted: (_) => _submit(),
      validator: (v) {
        final value = int.tryParse(v ?? '');
        if (value == null || value <= 0) return 'Min 1';
        return null;
      },
      decoration: const InputDecoration(
        labelText: 'Qty',
        prefixIcon: Icon(Icons.numbers),
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: _submit,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add'),
    );

    return SectionCard(
      icon: Icons.add_shopping_cart,
      title: 'Add item',
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: priceField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: quantityField),
                    ],
                  ),
                  const SizedBox(height: 14),
                  addButton,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: nameField),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: priceField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: quantityField),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SizedBox(height: 48, child: addButton),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget? _noCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
