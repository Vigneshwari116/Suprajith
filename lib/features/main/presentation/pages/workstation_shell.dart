import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/routes_name.dart';

class WorkstationShell extends StatelessWidget {
  final Widget child;

  const WorkstationShell({super.key, required this.child});

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.workstationMasters)) return 1;
    if (location.startsWith(AppRoutes.workstationTransactions)) return 2;
    if (location.startsWith(AppRoutes.workstationReports)) return 3;
    if (location.startsWith(AppRoutes.workstationBackup)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F172A), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'SVENSKA AUTOMOTIVE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigoAccent),
                  ),
                  const SizedBox(width: 24),
                  _NavTab(
                    label: 'Main screen',
                    selected: selected == 0,
                    onTap: () => context.go(AppRoutes.workstationMain),
                  ),
                  _NavTab(
                    label: 'Masters',
                    selected: selected == 1,
                    onTap: () => context.go(AppRoutes.workstationMasters),
                  ),
                  _NavTab(
                    label: 'Transactions',
                    selected: selected == 2,
                    onTap: () => context.go(AppRoutes.workstationTransactions),
                  ),
                  _NavTab(
                    label: 'Reports',
                    selected: selected == 3,
                    onTap: () => context.go(AppRoutes.workstationReports),
                  ),
                  _NavTab(
                    label: 'Backup',
                    selected: selected == 4,
                    onTap: () => context.go(AppRoutes.workstationBackup),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
          backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.w600, fontSize: 11.5)),
      ),
    );
  }
}
