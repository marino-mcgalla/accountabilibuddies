import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/core/routing/app_router.dart';
import 'package:provider/provider.dart';
import 'features/goals/providers/goals_provider.dart';
import 'features/party/providers/party_provider.dart';
import 'features/time_machine/providers/time_machine_provider.dart';
import 'features/core/utils/responsive_wrapper.dart'; // Import the new wrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimeMachineProvider()),
        ChangeNotifierProxyProvider<TimeMachineProvider, GoalsProvider>(
          create: (context) => GoalsProvider(
            Provider.of<TimeMachineProvider>(context, listen: false),
          ),
          update: (context, timeMachineProvider, goalsProvider) =>
              goalsProvider!..updateTimeMachineProvider(timeMachineProvider),
        ),
        ChangeNotifierProvider(create: (context) => PartyProvider()),
        ChangeNotifierProvider(
          create: (context) => GoalsProvider(
            Provider.of<TimeMachineProvider>(context, listen: false),
          ),
        ),
      ],
      child: ResponsiveWrapper(
        child: MaterialApp.router(
          title: 'Accountabilibuddies',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            // Optimize for mobile
            visualDensity: VisualDensity.adaptivePlatformDensity,
            // Make sure input fields have sufficient height
            inputDecorationTheme: const InputDecorationTheme(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(44, 44), // Make buttons more tappable
              ),
            ),
            // More generous space for dialogs
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentTextStyle: const TextStyle(fontSize: 16),
            ),
          ),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
