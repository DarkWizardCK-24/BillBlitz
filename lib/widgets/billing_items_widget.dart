import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/widgets/section_card.dart';
import 'package:flutter/material.dart';

class BillingItemsWidget extends StatelessWidget {
  final List<BillingItem> items;
  final ValueChanged<int> onRemoveItem;
  final void Function(int index, int quantity) onQuantityChanged;

  const BillingItemsWidget({
    super.key,
    required this.items,
    required this.onRemoveItem,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.list_alt,
      title: 'Items',
      trailing: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
      child: items.isEmpty
          ? const _EmptyItems()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ItemRow(
                index: index,
                item: items[index],
                onRemove: () => onRemoveItem(index),
                onQuantityChanged: (q) => onQuantityChanged(index, q),
              ),
            ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 30,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'No items yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Add an item above to start the bill',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final BillingItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Two lines so long names get the full width, even on a phone:
    //   [1] Item name ........................ [delete]
    //       ₹640.00 each      [- 2 +]          ₹1,280.00
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.danger,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 38, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${Fmt.money(item.price)} each',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                _QuantityStepper(
                  quantity: item.quantity,
                  onChanged: onQuantityChanged,
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 84),
                  child: Text(
                    Fmt.money(item.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tip, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: tip,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? AppColors.border : AppColors.primary,
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            Icons.remove,
            'Decrease quantity',
            quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          button(Icons.add, 'Increase quantity', () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}
