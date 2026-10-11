import 'package:billing_system/firebase_options.dart';
import 'package:billing_system/screens/billing_screen.dart';
import 'package:billing_system/services/bill_repository.dart';
import 'package:billing_system/services/shop_profile_store.dart';
import 'package:billing_system/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MyApp(repository: FirestoreBillRepository(), shopStore: ShopProfileStore()),
  );
}

class MyApp extends StatelessWidget {
  final BillRepository repository;
  final ShopProfileStore shopStore;

  const MyApp({super.key, required this.repository, required this.shopStore});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillBlitz',
      theme: AppTheme.light(),
      home: BillingScreen(repository: repository, shopStore: shopStore),
    );
  }
}
