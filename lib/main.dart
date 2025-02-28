import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/core/routing/app_router.dart';
import 'package:provider/provider.dart';
import 'features/goals/providers/goals_provider.dart';
import 'features/party/providers/party_provider.dart';
import 'features/time_machine/providers/time_machine_provider.dart'; // Import TimeMachineProvider

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
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
