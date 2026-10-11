import 'package:billing_system/models/shop_profile_model.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:billing_system/utils/formatters.dart';
import 'package:billing_system/utils/snackbar.dart';
import 'package:billing_system/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lets the owner set the shop details that appear on every printed bill.
class SettingsScreen extends StatefulWidget {
  final ShopProfileStore store;

  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _footer = TextEditingController();
  final _tax = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _footer.dispose();
    _tax.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final shop = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _name.text = shop.name;
      _address.text = shop.address;
      _phone.text = shop.phone;
      _footer.text = shop.footerNote;
      _tax.text = Fmt.percent(shop.defaultTaxPercent);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.store.save(
        ShopProfile(
          name: _name.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          footerNote: _footer.text.trim(),
          defaultTaxPercent: (double.tryParse(_tax.text) ?? 0)
              .clamp(0, 100)
              .toDouble(),
        ),
      );
      if (!mounted) return;
      showAppSnack(context, 'Shop details saved', kind: SnackKind.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Could not save: $e', kind: SnackKind.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const GradientHeader(),
        title: const Text('Shop settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionCard(
                        icon: Icons.storefront_outlined,
                        title: 'Shop details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Shop name is required'
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Shop name',
                                prefixIcon: Icon(Icons.store_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _address,
                              textInputAction: TextInputAction.next,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        icon: Icons.tune,
                        title: 'Billing defaults',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _tax,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d{0,3}\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Default tax rate',
                                suffixText: '%',
                                prefixIcon: Icon(Icons.percent),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _footer,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Bill footer message',
                                prefixIcon: Icon(Icons.notes),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
