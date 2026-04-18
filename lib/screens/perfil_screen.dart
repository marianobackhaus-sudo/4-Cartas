import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      body: Center(
        child: Text(
          'COMING SOON',
          style: AppText.hero.copyWith(letterSpacing: 6),
        ),
      ),
    );
  }
}
