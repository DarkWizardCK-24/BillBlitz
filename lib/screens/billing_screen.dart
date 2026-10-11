import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/models/billing_item_model.dart';
import 'package:billing_system/models/payment_method.dart';
import 'package:billing_system/models/shop_profile_model.dart';
import 'package:billing_system/screens/settings_screen.dart';
import 'package:billing_system/screens/view_bills_screen.dart';
import 'package:billing_system/services/bill_repository.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/bill_calculator.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/utils/pdf_bill_generator.dart';
import 'package:billing_system/utils/snackbar.dart';
import 'package:billing_system/widgets/add_item_widget.dart';
import 'package:billing_system/widgets/app_logo.dart';
import 'package:billing_system/widgets/bill_summary_widget.dart';
import 'package:billing_system/widgets/billing_items_widget.dart';
import 'package:billing_system/widgets/customer_info_widget.dart';
import 'package:flutter/material.dart';

class BillingScreen extends StatefulWidget {
  final BillRepository repository;
  final ShopProfileStore shopStore;

  const BillingScreen({
    super.key,
    required this.repository,
    required this.shopStore,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<BillingItem> _items = [];
  final _customerFormKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  ShopProfile _shop = const ShopProfile();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _taxController.text = Fmt.percent(_shop.defaultTaxPercent);
    _loadShop();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _loadShop() async {
    final shop = await widget.shopStore.load();
    if (!mounted) return;
    setState(() {
      // Only apply the default tax if the user hasn't typed their own yet.
      if (_taxController.text == Fmt.percent(_shop.defaultTaxPercent)) {
        _taxController.text = Fmt.percent(shop.defaultTaxPercent);
      }
      _shop = shop;
    });
  }

  double get _taxPercent =>
      (double.tryParse(_taxController.text) ?? 0).clamp(0, 100).toDouble();
  double get _discountPercent =>
      (double.tryParse(_discountController.text) ?? 0).clamp(0, 100).toDouble();

  BillTotals get _totals => BillCalculator.compute(
    _items,
    taxPercent: _taxPercent,
    discountPercent: _discountPercent,
  );

  bool get _hasContent =>
      _items.isNotEmpty ||
      _customerNameController.text.isNotEmpty ||
      _customerPhoneController.text.isNotEmpty ||
      _discountController.text.isNotEmpty;

  void _addItem(BillingItem item) {
    setState(() => _items.add(item));
    showAppSnack(context, '${item.name} added', kind: SnackKind.success);
  }

  void _removeItem(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    showAppSnack(
      context,
      '${removed.name} removed',
      actionLabel: 'UNDO',
      onAction: () {
        if (!mounted) return;
        setState(() => _items.insert(index.clamp(0, _items.length), removed));
      },
    );
  }

  void _changeQuantity(int index, int quantity) {
    setState(() => _items[index] = _items[index].copyWith(quantity: quantity));
  }

  void _resetForm() {
    setState(() {
      _items.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _discountController.clear();
      _taxController.text = Fmt.percent(_shop.defaultTaxPercent);
      _paymentMethod = PaymentMethod.cash;
    });
    _customerFormKey.currentState?.reset();
  }

  Future<void> _confirmClear() async {
    if (!_hasContent) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this bill?'),
        content: const Text(
          'All items and customer details on this bill will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _resetForm();
    showAppSnack(context, 'Bill cleared');
  }

  /// Saves the current bill. Returns the saved bill (with its id) or `null`.
  Future<Bill?> _save() async {
    if (_saving) return null;
    if (_items.isEmpty) {
      showAppSnack(
        context,
        'Add at least one item first',
        kind: SnackKind.warning,
      );
      return null;
    }
    if (!(_customerFormKey.currentState?.validate() ?? true)) {
      showAppSnack(
        context,
        'Please fix the customer details',
        kind: SnackKind.warning,
      );
      return null;
    }

    final totals = _totals;
    final name = _customerNameController.text.trim();
    final bill = Bill(
      customerName: name.isEmpty ? 'Walk-in Customer' : name,
      customerPhone: _customerPhoneController.text.trim(),
      items: List.of(_items),
      subtotal: totals.subtotal,
      discount: totals.discount,
      taxableAmount: totals.taxableAmount,
      tax: totals.tax,
      total: totals.total,
      taxPercent: _taxPercent,
      discountPercent: _discountPercent,
      paymentMethod: _paymentMethod,
      date: DateTime.now(),
    );

    setState(() => _saving = true);
    try {
      final saved = await widget.repository.saveBill(bill);
      if (!mounted) return null;
      _resetForm();
      showAppSnack(context, 'Saved as ${saved.id}', kind: SnackKind.success);
      return saved;
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          kind: SnackKind.error,
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndPrint() async {
    final shop = _shop;
    final saved = await _save();
    if (saved == null || !mounted) return;
    try {
      await PdfBillGenerator.printBill(saved, shop);
    } catch (e) {
      if (mounted) {
        showAppSnack(
          context,
          'Could not open print dialog: $e',
          kind: SnackKind.error,
        );
      }
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(store: widget.shopStore),
      ),
    );
    if (mounted) _loadShop();
  }

  void _openSavedBills() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewBillsScreen(
          repository: widget.repository,
          shopStore: widget.shopStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        flexibleSpace: const GradientHeader(),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 32),
            SizedBox(width: 10),
            Text('BillBlitz'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Saved bills',
            onPressed: _openSavedBills,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Shop settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final customer = Form(
            key: _customerFormKey,
            child: CustomerInfoWidget(
              customerNameController: _customerNameController,
              customerPhoneController: _customerPhoneController,
            ),
          );
          final addItem = AddItemWidget(onAddItem: _addItem);
          final items = BillingItemsWidget(
            items: _items,
            onRemoveItem: _removeItem,
            onQuantityChanged: _changeQuantity,
          );
          final summary = BillSummaryWidget(
            totals: totals,
            taxPercent: _taxPercent,
            discountPercent: _discountPercent,
            discountController: _discountController,
            taxController: _taxController,
            paymentMethod: _paymentMethod,
            onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
            onRatesChanged: () => setState(() {}),
          );

          // Desktop / wide web: customer + items on the left, the running
          // summary stays in view on the right. Phones keep one column.
          if (box.maxWidth >= _wideBreakpoint) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
                        children: [
                          customer,
                          const SizedBox(height: 14),
                          addItem,
                          const SizedBox(height: 14),
                          items,
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
                        children: [summary],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                children: [
                  customer,
                  const SizedBox(height: 14),
                  addItem,
                  const SizedBox(height: 14),
                  items,
                  const SizedBox(height: 14),
                  summary,
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _ActionBar(
        itemCount: _items.length,
        total: totals.total,
        saving: _saving,
        canClear: _hasContent,
        onClear: _confirmClear,
        onSave: _save,
        onSaveAndPrint: _saveAndPrint,
      ),
    );
  }
}

/// Width at which the bill editor switches to its two-column desktop layout.
const double _wideBreakpoint = 960;

class _ActionBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool saving;
  final bool canClear;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _ActionBar({
    required this.itemCount,
    required this.total,
    required this.saving,
    required this.canClear,
    required this.onClear,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = itemCount > 0 && !saving;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width >= _wideBreakpoint
                  ? 1240
                  : 760,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        itemCount == 0
                            ? 'No items'
                            : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Total  ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Text(
                        Fmt.money(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Clear bill',
                        onPressed: canClear && !saving ? onClear : null,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(50, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: enabled ? onSave : null,
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: enabled ? onSaveAndPrint : null,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.print_outlined, size: 20),
                          label: Text(saving ? 'Saving...' : 'Save & Print'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
