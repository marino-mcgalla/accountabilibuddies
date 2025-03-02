import 'package:auth_test/features/core/themes/app_theme.dart';
import 'package:auth_test/features/core/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/core/routing/app_router.dart';
import 'package:provider/provider.dart';
import 'features/goals/providers/goals_provider.dart';
import 'features/party/providers/party_provider.dart';
import 'features/time_machine/providers/time_machine_provider.dart';
import 'features/core/utils/responsive_wrapper.dart';

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
        // Add the ThemeProvider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ResponsiveWrapper(
            child: MaterialApp.router(
              title: 'Accountabilibuddies',
              theme: AppTheme.lightTheme, // Light theme
              darkTheme: AppTheme.darkTheme, // Dark theme
              themeMode: themeProvider.isDarkMode
                  ? ThemeMode.dark
                  : ThemeMode.light, // Use stored preference
              routerConfig: appRouter,
            ),
          );
        },
      ),
    );
  }
}
