import 'package:billing_system/models/shop_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the [ShopProfile] on the device.
class ShopProfileStore {
  static const _name = 'shop.name';
  static const _address = 'shop.address';
  static const _phone = 'shop.phone';
  static const _footer = 'shop.footer';
  static const _tax = 'shop.defaultTax';

  Future<ShopProfile> load() async {
    const defaults = ShopProfile();
    try {
      final prefs = await SharedPreferences.getInstance();
      return ShopProfile(
        name: prefs.getString(_name) ?? defaults.name,
        address: prefs.getString(_address) ?? defaults.address,
        phone: prefs.getString(_phone) ?? defaults.phone,
        footerNote: prefs.getString(_footer) ?? defaults.footerNote,
        defaultTaxPercent: prefs.getDouble(_tax) ?? defaults.defaultTaxPercent,
      );
    } catch (_) {
      return defaults;
    }
  }

  Future<void> save(ShopProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_name, profile.name);
    await prefs.setString(_address, profile.address);
    await prefs.setString(_phone, profile.phone);
    await prefs.setString(_footer, profile.footerNote);
    await prefs.setDouble(_tax, profile.defaultTaxPercent);
  }
}
