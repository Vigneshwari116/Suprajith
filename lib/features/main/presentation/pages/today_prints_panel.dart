import 'package:flutter/material.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/core/services/print_history_refresh_notifier.dart';
import 'package:svenska/core/widgets/excel_style_table.dart';
import 'package:svenska/injection.dart';

class TodayPrintsPanel extends StatefulWidget {
  const TodayPrintsPanel({super.key});

  @override
  State<TodayPrintsPanel> createState() => _TodayPrintsPanelState();
}

class _TodayPrintsPanelState extends State<TodayPrintsPanel> {
  List<Map<String, dynamic>> _rows = [];
  late final PrintHistoryRefreshNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = sl<PrintHistoryRefreshNotifier>();
    _notifier.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _notifier.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _rows = sl<LocalLabelService>().queryPrintHistory(
        todayOnly: true,
        todayReference: DateTime.now(),
        limit: 500,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tableRows = List.generate(_rows.length, (index) {
      final row = _rows[index];
      final slNo = '${_rows.length - index}';
      return [
        slNo,
        row['vehicle_model']?.toString() ?? '',
        row['serial_no']?.toString() ?? '',
        row['full_qr_data']?.toString() ?? '',
      ];
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's prints",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            ExcelStyleTable(
              columns: const ['S.No', 'Model', 'Serial', 'QR'],
              rows: tableRows,
              columnWidths: const [48, 72, 56, 280],
              emptyMessage: 'No prints yet today.',
            ),
          ],
        ),
      ),
    );
  }
}
