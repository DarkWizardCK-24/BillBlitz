import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/services/bill_repository.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/bill_calculator.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';
import 'package:billing_system/utils/snackbar.dart';
import 'package:billing_system/widgets/bill_summary_widget.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with the full details of a saved bill and print / share / delete.
Future<void> showBillDetailSheet(
  BuildContext context, {
  required Bill bill,
  required BillRepository repository,
  required ShopProfileStore shopStore,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BillDetailSheet(
      bill: bill,
      repository: repository,
      shopStore: shopStore,
    ),
  );
}

class BillDetailSheet extends StatelessWidget {
  final Bill bill;
  final BillRepository repository;
  final ShopProfileStore shopStore;

  const BillDetailSheet({
    super.key,
    required this.bill,
    required this.repository,
    required this.shopStore,
  });

  Future<void> _print(BuildContext context, {required bool share}) async {
    try {
      final shop = await shopStore.load();
      if (share) {
        await PdfBillGenerator.shareBill(bill, shop);
      } else {
        await PdfBillGenerator.printBill(bill, shop);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnack(
          context,
          'Could not create PDF: $e',
          kind: SnackKind.error,
        );
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${bill.id}?'),
        content: const Text('This bill will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || bill.id == null) return;

    try {
      await repository.deleteBill(bill.id!);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${bill.id} deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = BillTotals(
      subtotal: bill.subtotal,
      discount: bill.discount,
      taxableAmount: bill.taxableAmount,
      tax: bill.tax,
      total: bill.total,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.id ?? 'Bill',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Fmt.dateTime(bill.date),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bill.paymentMethod.icon,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bill.paymentMethod.label,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              bill.customerPhone.isEmpty
                                  ? 'No phone number'
                                  : bill.customerPhone,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < bill.items.length; i++) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bill.items[i].name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${Fmt.money(bill.items[i].price)} × ${bill.items[i].quantity}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Fmt.money(bill.items[i].total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TotalsBox(
                  totals: totals,
                  taxPercent: bill.taxPercent,
                  discountPercent: bill.discountPercent,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _print(context, share: true),
                        icon: const Icon(Icons.share_outlined, size: 20),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _print(context, share: false),
                        icon: const Icon(Icons.print_outlined, size: 20),
                        label: const Text('Print'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _delete(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Delete bill'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
