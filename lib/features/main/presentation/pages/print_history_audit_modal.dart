import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:svenska/features/main/presentation/pages/vehicle_models.dart';
import '../../../../core/constants/app_mode.dart';
import '../../../../core/constants/label_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_label_service.dart';
import '../../../../injection.dart';
import 'frontend_label_engine.dart';
import 'logo_assets_resolver.dart';
import 'dart:typed_data';


class PrintHistoryAuditModal extends StatefulWidget {
  const PrintHistoryAuditModal({super.key});

  @override
  State<PrintHistoryAuditModal> createState() => _PrintHistoryAuditModalState();
}

class _PrintHistoryAuditModalState extends State<PrintHistoryAuditModal> {
  List<PrintHistoryRecord> _rawHistoryList = [];
  Map<String, List<PrintHistoryRecord>> _groupedHistory = {};
  bool _isLoading = true;
  int _totalCount = 0;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadGroupedHistory();
  }

  Future<void> _loadGroupedHistory() async {
    setState(() => _isLoading = true);
    try {
      final List raw = kUseLocalDataStore
          ? sl<LocalLabelService>().getPrintHistory()
          : (await sl<ApiClient>().get('/api/history')).data['data'] as List? ?? [];
      _rawHistoryList = raw.map((e) => PrintHistoryRecord.fromMap(e as Map<String, dynamic>)).toList();
      _applyDateFilters();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyDateFilters() {
    List<PrintHistoryRecord> filtered = List.from(_rawHistoryList);

    if (_fromDate != null || _toDate != null) {
      filtered = filtered.where((item) {
        final datePart = item.printedAt.split(' ').first;
        try {
          final recordDate = DateFormat('dd.MM.yyyy').parse(datePart);
          if (_fromDate != null && _toDate == null) {
            return !recordDate.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
          }
          if (_fromDate == null && _toDate != null) {
            return !recordDate.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59));
          }
          return !recordDate.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day)) &&
              !recordDate.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59));
        } catch (_) {
          return false;
        }
      }).toList();
    }

    Map<String, List<PrintHistoryRecord>> groups = {};
    for (var item in filtered) {
      String dateKey = item.printedAt.split(' ').first;
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(item);
    }

    groups.forEach((key, records) {
      records.sort((a, b) => b.serialNo.compareTo(a.serialNo));
    });

    if (mounted) {
      setState(() {
        _groupedHistory = groups;
        _totalCount = filtered.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "SELECT FROM DATE",
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      });
      _applyDateFilters();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "SELECT TO DATE",
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _applyDateFilters();
    }
  }

  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyDateFilters();
  }

  Future<void> _triggerReprint(PrintHistoryRecord item) async {
    final chosenSize = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reprint Label", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Select target size for Model ${item.vehicleModel} (#${item.serialNo}):"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, '50x25'),
            child: const Text("Small (50x25 mm)"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(ctx, '100x50'),
            child: const Text("Large (100x50 mm)", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (chosenSize == null) return;

    try {
      final logoImage = await LogoAssetResolver.getLogoImage(item.companyLogo);
      final reprintMfgDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
      final Uint8List pdfBytes;
      if (chosenSize == '100x50') {
        pdfBytes = await FrontendLabelEngine.build100x50Pdf(
          model: item.vehicleModel,
          custPart: item.customerPartNo,
          partNo: item.partNo,
          mfgDate: reprintMfgDate,
          serial: item.serialNo,
          qrPayload: item.fullQrData,
          logoImage: logoImage,
        );
      } else {
        pdfBytes = await FrontendLabelEngine.build50x25Pdf(
          model: item.vehicleModel,
          customerPartNo: item.customerPartNo,
          partNo: item.partNo,
          mfgDate: reprintMfgDate,
          qrPayload: item.fullQrData,
          logoImage: logoImage,
        );
      }

      await FrontendLabelEngine.directHardwareDispatch(
        pdfBytes: pdfBytes,
        printerName: 'TSC TTP-244 Plus',
        jobName: 'Reprint_${item.vehicleModel}_${item.serialNo}',
        pageFormat: chosenSize == '100x50' ? kLabel100x50PageFormat : kLabel50x25PageFormat,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reprinted #${item.serialNo} on $chosenSize successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reprint failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printAuditSummaryReport() async {
    final doc = pw.Document();
    final allRows = _groupedHistory.values.expand((element) => element).toList();

    String filterSummary = "All Records";
    if (_fromDate != null && _toDate != null) {
      filterSummary = "${DateFormat('dd.MM.yy').format(_fromDate!)} to ${DateFormat('dd.MM.yy').format(_toDate!)}";
    } else if (_fromDate != null) {
      filterSummary = "From ${DateFormat('dd.MM.yy').format(_fromDate!)}";
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("SVENSKA AUTOMOTIVE - AUDIT LOGS",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text("Filter: $filterSummary | Total: $_totalCount",
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Serial', 'Model', 'Part No', 'Customer PN', 'MFG Date', 'Printed At'],
              data: allRows
                  .map((r) => [
                '#${r.serialNo}',
                r.vehicleModel,
                r.partNo,
                r.customerPartNo,
                r.dateOfMfg,
                r.printedAt,
              ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Print_Audit_Report_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _fromDate != null || _toDate != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 960,
          height: 640,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1)))),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 22, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PRINT AUDIT & REPRINT VAULT",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black)),
                              Text("Showing $_totalCount records",
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _groupedHistory.isEmpty ? null : _printAuditSummaryReport,
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text("PRINT REPORT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Filter Date:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _pickFromDate,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: _fromDate != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 13, color: _fromDate != null ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  _fromDate != null ? "From: ${DateFormat('dd.MM.yyyy').format(_fromDate!)}" : "From Date",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _fromDate != null ? const Color(0xFF2563EB) : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _pickToDate,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: _toDate != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 13, color: _toDate != null ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                                const SizedBox(width: 6),
                                Text(
                                  _toDate != null ? "To: ${DateFormat('dd.MM.yyyy').format(_toDate!)}" : "To Date",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _toDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _toDate != null ? const Color(0xFF2563EB) : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasFilter) ...[
                          const SizedBox(width: 10),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.clear_rounded, size: 15),
                            label: const Text("Clear Filter", style: TextStyle(fontSize: 11)),
                            onPressed: _clearFilter,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _groupedHistory.isEmpty
                    ? const Center(
                  child: Text("No records found for selected date range.",
                      style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _groupedHistory.keys.length,
                  itemBuilder: (ctx, index) {
                    final dateKey = _groupedHistory.keys.elementAt(index);
                    final records = _groupedHistory[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Date: $dateKey (${records.length} Labels Printed)",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black),
                          ),
                        ),
                        ...records.map((item) {
                          final timeStr = item.printedAt.split(' ').length > 1
                              ? item.printedAt.split(' ')[1]
                              : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    "#${item.serialNo}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF2563EB)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.vehicleModel,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                                      const SizedBox(height: 2),
                                      Text(
                                          "PN: ${item.partNo}  |  Cust PN: ${item.customerPartNo}  |  MFG: ${item.dateOfMfg}",
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                      Text(item.fullQrData,
                                          style: const TextStyle(
                                              fontFamily: 'Consolas', fontSize: 9.5, color: Colors.blueGrey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(timeStr,
                                        style: const TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const SizedBox(height: 4),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        side: const BorderSide(color: Color(0xFF2563EB), width: 1),
                                      ),
                                      icon: const Icon(Icons.print_rounded, size: 14, color: Color(0xFF2563EB)),
                                      label: const Text("Reprint",
                                          style: TextStyle(
                                              fontSize: 10.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                      onPressed: () => _triggerReprint(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}