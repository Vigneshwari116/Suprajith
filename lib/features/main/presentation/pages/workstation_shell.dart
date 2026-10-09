import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:svenska/core/constants/app_mode.dart';
import 'package:svenska/core/services/auth_service.dart';
import 'package:svenska/injection.dart';
import '../../../../core/utils/routes_name.dart';

class WorkstationShell extends StatefulWidget {
  final Widget child;

  const WorkstationShell({super.key, required this.child});

  @override
  State<WorkstationShell> createState() => _WorkstationShellState();
}

class _WorkstationShellState extends State<WorkstationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.workstationMasters)) return 1;
    if (location.startsWith(AppRoutes.workstationReports)) return 2;
    if (location.startsWith(AppRoutes.workstationBackup)) return 3;
    return 0;
  }

  String _pageTitle(int selected) {
    switch (selected) {
      case 1:
        return 'Masters';
      case 2:
        return 'Reports';
      case 3:
        return 'Backup';
      default:
        return 'Transaction';
    }
  }

  void _navigate(BuildContext context, String route) {
    context.go(route);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    if (kUseLocalDataStore) {
      sl<AuthService>().logout();
    }
    _scaffoldKey.currentState?.closeDrawer();
    context.go(AppRoutes.login);
  }

  Widget _drawerNav(BuildContext context, int selected) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F172A), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SVENSKA AUTOMOTIVE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigoAccent),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  _SideNavItem(
                    label: 'Transaction',
                    icon: Icons.print_outlined,
                    selected: selected == 0,
                    onTap: () => _navigate(context, AppRoutes.workstationMain),
                  ),
                  _SideNavItem(
                    label: 'Masters',
                    icon: Icons.storage_outlined,
                    selected: selected == 1,
                    onTap: () => _navigate(context, AppRoutes.workstationMasters),
                  ),
                  _SideNavItem(
                    label: 'Reports',
                    icon: Icons.assessment_outlined,
                    selected: selected == 2,
                    onTap: () => _navigate(context, AppRoutes.workstationReports),
                  ),
                  _SideNavItem(
                    label: 'Backup',
                    icon: Icons.backup_outlined,
                    selected: selected == 3,
                    onTap: () => _navigate(context, AppRoutes.workstationBackup),
                  ),
                ],
              ),
            ),
            if (kUseLocalDataStore) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _SideNavItem(
                  label: 'Logout',
                  icon: Icons.logout,
                  selected: false,
                  onTap: () => _confirmLogout(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: _drawerNav(context, selected),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu, size: 22),
                    color: const Color(0xFF2563EB),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: Text(
                      _pageTitle(selected),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
