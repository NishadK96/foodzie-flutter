import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/pos/presentation/secondary_screens.dart';
import '../features/auth/presentation/login_screen.dart';
import 'theme.dart';

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    _instantRoute('/login', const LoginScreen()),
    _instantRoute('/pos', const PosScreen()),
    _instantRoute('/orders', const OrdersScreen()),
    _instantRoute('/tables', const TablesScreen()),
    _instantRoute('/kitchen', const KitchenScreen()),
    _instantRoute('/menu', const MenuScreen()),
    _instantRoute('/inventory', const InventoryScreen()),
    _instantRoute('/customers', const CustomersScreen()),
    _instantRoute('/reports', const ReportsScreen()),
    _instantRoute('/settings', const SettingsScreen()),
  ],
);

GoRoute _instantRoute(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: child),
);

class FoodzyApp extends StatelessWidget {
  const FoodzyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Foodzy Restaurant POS',
    debugShowCheckedModeBanner: false,
    theme: FoodzyTheme.light,
    routerConfig: _router,
  );
}
