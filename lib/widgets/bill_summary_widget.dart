import 'package:billing_system/models/payment_method.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/bill_calculator.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Discount / tax inputs, payment method and the live totals.
class BillSummaryWidget extends StatelessWidget {
  final BillTotals totals;
  final double taxPercent;
  final double discountPercent;
  final TextEditingController discountController;
  final TextEditingController taxController;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onRatesChanged;

  const BillSummaryWidget({
    super.key,
    required this.totals,
    required this.taxPercent,
    required this.discountPercent,
    required this.discountController,
    required this.taxController,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onRatesChanged,
  });

  static final _percentFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,3}\.?\d{0,2}'),
  );

  @override
  Widget build(BuildContext context) {
    final discountField = TextField(
      controller: discountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_percentFormatter],
      onChanged: (_) => onRatesChanged(),
      decoration: const InputDecoration(
        labelText: 'Discount',
        hintText: '0',
        suffixText: '%',
        prefixIcon: Icon(Icons.local_offer_outlined),
      ),
    );
    final taxField = TextField(
      controller: taxController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_percentFormatter],
      onChanged: (_) => onRatesChanged(),
      decoration: const InputDecoration(
        labelText: 'Tax',
        hintText: '0',
        suffixText: '%',
        prefixIcon: Icon(Icons.account_balance_outlined),
      ),
    );

    return SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: discountField),
              const SizedBox(width: 12),
              Expanded(child: taxField),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final method in PaymentMethod.values)
                ChoiceChip(
                  avatar: Icon(
                    method.icon,
                    size: 18,
                    color: method == paymentMethod
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  label: Text(method.label),
                  selected: method == paymentMethod,
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: method == paymentMethod
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: method == paymentMethod
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (_) => onPaymentMethodChanged(method),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TotalsBox(
            totals: totals,
            taxPercent: taxPercent,
            discountPercent: discountPercent,
          ),
        ],
      ),
    );
  }
}

/// The subtotal -> total breakdown. Also used on the saved-bill sheet.
class TotalsBox extends StatelessWidget {
  final BillTotals totals;
  final double taxPercent;
  final double discountPercent;

  const TotalsBox({
    super.key,
    required this.totals,
    required this.taxPercent,
    required this.discountPercent,
  });

  Widget _row(String label, String value, {bool muted = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: muted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Subtotal', Fmt.money(totals.subtotal), muted: true),
          if (totals.discount > 0)
            _row(
              'Discount (${Fmt.percent(discountPercent)}%)',
              '- ${Fmt.money(totals.discount)}',
              muted: true,
            ),
          _row('Taxable amount', Fmt.money(totals.taxableAmount), muted: true),
          _row(
            'Tax (${Fmt.percent(taxPercent)}%)',
            Fmt.money(totals.tax),
            muted: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                Fmt.money(totals.total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
