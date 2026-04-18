import 'package:flutter/material.dart';

import 'core/design_tokens.dart';
import 'core/theme.dart';
import 'core/typography.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4 Cartas BLITZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _BootstrapPlaceholder(),
    );
  }
}

class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgDeepest],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('4 CARTAS', style: AppText.hero),
              SizedBox(height: 8),
              Text('BLITZ', style: AppText.title),
              SizedBox(height: 24),
              Text('construyendo...', style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}
