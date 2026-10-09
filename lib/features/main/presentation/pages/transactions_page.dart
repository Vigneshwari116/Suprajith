import 'package:flutter/material.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/core/utils/print_timestamp_formatter.dart';
import 'package:svenska/core/widgets/excel_style_table.dart';
import 'package:svenska/injection.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _modelFilter;
  final _qrSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  List<String> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
    _applyFilters();
  }

  @override
  void dispose() {
    _qrSearchCtrl.dispose();
    super.dispose();
  }

  void _loadModels() {
    final masters = sl<LocalLabelService>().listMasters();
    _models = masters.map((m) => m['vehicle_model']?.toString() ?? '').where((m) => m.isNotEmpty).toSet().toList();
    _models.sort();
  }

  void _applyFilters() {
    setState(() {
      _rows = sl<LocalLabelService>().queryPrintHistory(
        fromLocalDate: _fromDate,
        toLocalDate: _toDate,
        vehicleModel: _modelFilter,
        qrContains: _qrSearchCtrl.text.trim().isEmpty ? null : _qrSearchCtrl.text.trim(),
        limit: 10000,
      );
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _applyFilters();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(onPressed: _pickFromDate, child: Text(_fromDate == null ? 'From date' : 'From: ${_fromDate!.toString().split(' ').first}')),
                OutlinedButton(onPressed: _pickToDate, child: Text(_toDate == null ? 'To date' : 'To: ${_toDate!.toString().split(' ').first}')),
                DropdownButton<String?>(
                  value: _modelFilter,
                  hint: const Text('Model', style: TextStyle(fontSize: 12)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All models')),
                    ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (v) {
                    setState(() => _modelFilter = v);
                    _applyFilters();
                  },
                ),
                SizedBox(
                  width: 220,
                  height: 40,
                  child: TextField(
                    controller: _qrSearchCtrl,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Search QR text',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                ElevatedButton(onPressed: _applyFilters, child: const Text('Apply')),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _modelFilter = null;
                      _qrSearchCtrl.clear();
                    });
                    _applyFilters();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ExcelStyleTable(
                    columns: const ['S.No', 'Printed at', 'Model', 'Serial', 'Full QR'],
                    columnWidths: const [48, 140, 72, 56, 300],
                    rows: List.generate(_rows.length, (i) {
                      final row = _rows[i];
                      return [
                        '${_rows.length - i}',
                        PrintTimestampFormatter.displayFromRaw(row['printed_at']?.toString()),
                        row['vehicle_model']?.toString() ?? '',
                        row['serial_no']?.toString() ?? '',
                        row['full_qr_data']?.toString() ?? '',
                      ];
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
