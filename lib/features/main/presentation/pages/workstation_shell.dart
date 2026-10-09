import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/routes_name.dart';

class WorkstationShell extends StatefulWidget {
  final Widget child;

  const WorkstationShell({super.key, required this.child});

  @override
  State<WorkstationShell> createState() => _WorkstationShellState();
}

class _WorkstationShellState extends State<WorkstationShell> {
  bool _menuExpanded = false;

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.workstationMasters)) return 1;
    if (location.startsWith(AppRoutes.workstationTransactions)) return 2;
    if (location.startsWith(AppRoutes.workstationReports)) return 3;
    if (location.startsWith(AppRoutes.workstationBackup)) return 4;
    return 0;
  }

  String _pageTitle(int selected) {
    switch (selected) {
      case 1:
        return 'Masters';
      case 2:
        return 'Transactions';
      case 3:
        return 'Reports';
      case 4:
        return 'Backup';
      default:
        return 'Main screen';
    }
  }

  void _navigate(BuildContext context, String route) {
    context.go(route);
    final onMain = route == AppRoutes.workstationMain;
    setState(() => _menuExpanded = !onMain);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);
    final onMainScreen = selected == 0;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F172A), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'SVENSKA AUTOMOTIVE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigoAccent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_menuExpanded) ...[
                        Text(
                          _pageTitle(selected),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton.icon(
                        onPressed: () => setState(() => _menuExpanded = !_menuExpanded),
                        icon: Icon(_menuExpanded ? Icons.expand_less : Icons.menu, size: 18),
                        label: Text(
                          _menuExpanded ? 'Close menu' : 'Menu',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  if (_menuExpanded) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _NavTab(
                          label: 'Main screen',
                          selected: selected == 0,
                          onTap: () => _navigate(context, AppRoutes.workstationMain),
                        ),
                        _NavTab(
                          label: 'Masters',
                          selected: selected == 1,
                          onTap: () => _navigate(context, AppRoutes.workstationMasters),
                        ),
                        _NavTab(
                          label: 'Transactions',
                          selected: selected == 2,
                          onTap: () => _navigate(context, AppRoutes.workstationTransactions),
                        ),
                        _NavTab(
                          label: 'Reports',
                          selected: selected == 3,
                          onTap: () => _navigate(context, AppRoutes.workstationReports),
                        ),
                        _NavTab(
                          label: 'Backup',
                          selected: selected == 4,
                          onTap: () => _navigate(context, AppRoutes.workstationBackup),
                        ),
                      ],
                    ),
                  ],
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
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF2563EB) : const Color(0xFF475569),
        backgroundColor: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onTap,
      child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.w600, fontSize: 11.5)),
    );
  }
}
