import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 设置为横屏模式
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // 隐藏状态栏，获得全屏体验
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const ProviderScope(child: LegoStudioApp()));
}

class LegoStudioApp extends StatelessWidget {
  const LegoStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '积木工坊',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomePage(),
      },
    );
  }
}