import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/theme.dart';
import 'core/services/billing_service.dart';
import 'core/services/database_service.dart';
import 'views/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent AR tracing experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Local SQLite Database
  await DatabaseService.instance.database;

  // Initialize Billing (In-App Purchase listener)
  final billing = BillingService.instance;
  billing.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BillingService>.value(value: billing),
      ],
      child: const TraceARApp(),
    ),
  );
}

class TraceARApp extends StatelessWidget {
  const TraceARApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TraceAR Studio',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeView(),
    );
  }
}
