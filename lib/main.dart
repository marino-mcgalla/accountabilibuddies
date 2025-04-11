// fix for main.dart:
import 'package:auth_test/features/core/themes/app_theme.dart';
import 'package:auth_test/features/core/themes/theme_provider.dart';
import 'package:auth_test/features/notifications/notifications_provider.dart';
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
        ChangeNotifierProvider(create: (context) => ThemeProvider()),

        ChangeNotifierProvider(create: (context) => NotificationsProvider()),

        // TimeMachineProvider first (dependency of GoalsProvider)
        ChangeNotifierProvider(create: (context) => TimeMachineProvider()),

        // Set up GoalsProvider with TimeMachineProvider dependency
        ChangeNotifierProxyProvider<TimeMachineProvider, GoalsProvider>(
          create: (context) => GoalsProvider(
            Provider.of<TimeMachineProvider>(context, listen: false),
          ),
          update: (context, timeMachineProvider, goalsProvider) =>
              goalsProvider!..updateTimeMachineProvider(timeMachineProvider),
        ),

        // Set up PartyProvider with GoalsProvider dependency
        ChangeNotifierProxyProvider<GoalsProvider, PartyProvider>(
          create: (context) => PartyProvider(
            goalsProvider: Provider.of<GoalsProvider>(context, listen: false),
          ),
          update: (context, goalsProvider, partyProvider) =>
              partyProvider ?? PartyProvider(goalsProvider: goalsProvider),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ResponsiveWrapper(
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
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
