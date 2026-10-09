import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:svenska/core/services/local_label_service.dart';
import 'package:svenska/core/services/report_export_service.dart';
import 'package:svenska/core/utils/print_timestamp_formatter.dart';
import 'package:svenska/core/widgets/excel_style_table.dart';
import 'package:svenska/injection.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _modelFilter;
  List<Map<String, dynamic>> _rows = [];
  List<String> _models = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final masters = sl<LocalLabelService>().listMasters();
    _models = masters.map((m) => m['vehicle_model']?.toString() ?? '').where((m) => m.isNotEmpty).toSet().toList();
    _models.sort();
    _runReport();
  }

  void _runReport() {
    setState(() {
      _rows = sl<LocalLabelService>().queryPrintHistory(
        fromLocalDate: _fromDate,
        toLocalDate: _toDate,
        vehicleModel: _modelFilter,
        limit: 20000,
      );
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final bytes = ReportExportService.buildCsvUtf8Bom(_rows);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save report CSV',
        fileName: 'svenska_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (path != null) {
        await File(path).writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved: $path')));
        }
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final summary = 'Rows: ${_rows.length}';
      final bytes = await ReportExportService.buildReportPdf(
        rows: _rows,
        title: 'Svenska Print Report',
        filterSummary: summary,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: 'svenska_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
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
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _fromDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) {
                      setState(() => _fromDate = d);
                      _runReport();
                    }
                  },
                  child: Text(_fromDate == null ? 'From' : DateFormat('dd-MM-yyyy').format(_fromDate!)),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _toDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) {
                      setState(() => _toDate = d);
                      _runReport();
                    }
                  },
                  child: Text(_toDate == null ? 'To' : DateFormat('dd-MM-yyyy').format(_toDate!)),
                ),
                DropdownButton<String?>(
                  value: _modelFilter,
                  hint: const Text('Model'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All models')),
                    ..._models.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (v) {
                    setState(() => _modelFilter = v);
                    _runReport();
                  },
                ),
                ElevatedButton(onPressed: _isExporting ? null : _exportPdf, child: const Text('Export PDF')),
                ElevatedButton(onPressed: _isExporting ? null : _exportCsv, child: const Text('Export CSV')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ExcelStyleTable(
                    columns: const [
                      'S.No',
                      'Printed at',
                      'Model',
                      'Serial',
                      'Customer part',
                      'Part no',
                      'Full QR',
                    ],
                    columnWidths: const [48, 130, 64, 52, 100, 100, 280],
                    rows: List.generate(_rows.length, (index) {
                      final row = _rows[index];
                      return [
                        '${index + 1}',
                        PrintTimestampFormatter.displayFromRaw(row['printed_at']?.toString()),
                        row['vehicle_model']?.toString() ?? '',
                        row['serial_no']?.toString() ?? '',
                        row['customer_part_no']?.toString() ?? '',
                        row['part_no']?.toString() ?? '',
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
