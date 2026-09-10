import 'package:flutter/material.dart';

import '../theme.dart';
import './dashboard_user.dart';

/// Tela inicial (home) acessada ao tocar no logo "bookface" na dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Text(
          'bookface',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardUser(),
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_outline,
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.home_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Bem-vindo ao bookface',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Esta é a tela inicial.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
