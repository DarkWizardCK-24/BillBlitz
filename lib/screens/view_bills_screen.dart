import 'package:billing_system/models/bill_model.dart';
import 'package:billing_system/services/bill_repository.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/widgets/bill_detail_sheet.dart';
import 'package:flutter/material.dart';

class ViewBillsScreen extends StatefulWidget {
  final BillRepository repository;
  final ShopProfileStore shopStore;

  const ViewBillsScreen({
    super.key,
    required this.repository,
    required this.shopStore,
  });

  @override
  State<ViewBillsScreen> createState() => _ViewBillsScreenState();
}

class _ViewBillsScreenState extends State<ViewBillsScreen> {
  final _searchController = TextEditingController();
  late final Stream<List<Bill>> _stream = widget.repository.watchBills();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bill> _filter(List<Bill> bills) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return bills;
    return bills.where((b) {
      return (b.id ?? '').toLowerCase().contains(q) ||
          b.customerName.toLowerCase().contains(q) ||
          b.customerPhone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const GradientHeader(),
        title: const Text('Saved bills'),
      ),
      body: StreamBuilder<List<Bill>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load bills',
              subtitle: '${snapshot.error}',
              color: AppColors.danger,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          if (all.isEmpty) {
            return const _Message(
              icon: Icons.receipt_long_outlined,
              title: 'No bills yet',
              subtitle: 'Bills you save will show up here.',
            );
          }

          final bills = _filter(all);
          final revenue = bills.fold<double>(0, (sum, b) => sum + b.total);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by customer, phone or bill ID',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.white,
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _StatsRow(count: bills.length, revenue: revenue),
                  ),
                  Expanded(
                    child: bills.isEmpty
                        ? const _Message(
                            icon: Icons.search_off,
                            title: 'No matching bills',
                            subtitle: 'Try a different name, phone or ID.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: bills.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) => _BillTile(
                              bill: bills[i],
                              onTap: () => showBillDetailSheet(
                                context,
                                bill: bills[i],
                                repository: widget.repository,
                                shopStore: widget.shopStore,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int count;
  final double revenue;

  const _StatsRow({required this.count, required this.revenue});

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, IconData icon) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        stat('Bills', '$count', Icons.receipt_long_outlined),
        const SizedBox(width: 12),
        stat(
          'Total value',
          Fmt.money(revenue),
          Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;

  const _BillTile({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = bill.customerName.isEmpty
        ? '?'
        : bill.customerName[0].toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${bill.id ?? ''} · ${Fmt.shortDateTime(bill.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.money(bill.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bill.paymentMethod.icon,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bill.items.length} ${bill.items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
