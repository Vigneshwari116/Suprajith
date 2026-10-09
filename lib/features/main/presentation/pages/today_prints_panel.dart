import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/core/services/print_history_refresh_notifier.dart';
import 'package:svenska/core/utils/print_timestamp_formatter.dart';
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

  String _timeCell(String? raw) {
    final parsed = PrintTimestampFormatter.tryParsePrintedAt(raw);
    if (parsed != null) return DateFormat('HH:mm:ss').format(parsed);
    return PrintTimestampFormatter.displayFromRaw(raw);
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
            if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No prints yet today.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 32,
                  dataRowMinHeight: 30,
                  dataRowMaxHeight: 36,
                  columnSpacing: 16,
                  headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  dataTextStyle: const TextStyle(fontSize: 10, fontFamily: 'Consolas'),
                  columns: const [
                    DataColumn(label: Text('Sl no')),
                    DataColumn(label: Text('Time')),
                    DataColumn(label: Text('Model')),
                    DataColumn(label: Text('Serial')),
                    DataColumn(label: Text('Full QR (29)')),
                  ],
                  rows: List.generate(_rows.length, (index) {
                    final row = _rows[index];
                    final slNo = _rows.length - index;
                    return DataRow(
                      cells: [
                        DataCell(Text('$slNo')),
                        DataCell(Text(_timeCell(row['printed_at']?.toString()))),
                        DataCell(Text(row['vehicle_model']?.toString() ?? '')),
                        DataCell(Text(row['serial_no']?.toString() ?? '')),
                        DataCell(Text(row['full_qr_data']?.toString() ?? '')),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
