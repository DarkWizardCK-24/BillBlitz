import 'package:billing_system/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerInfoWidget extends StatelessWidget {
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;

  const CustomerInfoWidget({
    super.key,
    required this.customerNameController,
    required this.customerPhoneController,
  });

  /// Phone is optional, but when given it must look like a phone number.
  static String? validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nameField = TextFormField(
      controller: customerNameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      maxLength: 60,
      buildCounter: _noCounter,
      decoration: const InputDecoration(
        labelText: 'Customer name',
        hintText: 'Walk-in Customer',
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
    final phoneField = TextFormField(
      controller: customerPhoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validatePhone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
      ],
      maxLength: 20,
      buildCounter: _noCounter,
      decoration: const InputDecoration(
        labelText: 'Phone (optional)',
        hintText: '98765 43210',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );

    return SectionCard(
      icon: Icons.person_outline,
      title: 'Customer',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              children: [nameField, const SizedBox(height: 12), phoneField],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nameField),
              const SizedBox(width: 12),
              Expanded(child: phoneField),
            ],
          );
        },
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
