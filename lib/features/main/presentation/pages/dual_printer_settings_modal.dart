import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class DualPrinterSettingsModal extends StatefulWidget {
  final String? currentPrinter50;
  final String? currentPrinter100;
  final VoidCallback onPrinterConfigured;

  const DualPrinterSettingsModal({
    super.key,
    this.currentPrinter50,
    this.currentPrinter100,
    required this.onPrinterConfigured,
  });

  @override
  State<DualPrinterSettingsModal> createState() => _DualPrinterSettingsModalState();
}

class _DualPrinterSettingsModalState extends State<DualPrinterSettingsModal> {
  List<Printer> _availablePrinters = [];
  String? _selected50;
  String? _selected100;
  bool _isLoadingPrinters = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selected50 = widget.currentPrinter50;
    _selected100 = widget.currentPrinter100;
    _fetchPrinters();
  }

  Future<void> _fetchPrinters() async {
    setState(() => _isLoadingPrinters = true);
    try {
      final list = await Printing.listPrinters();
      setState(() {
        _availablePrinters = list;
      });
    } catch (e) {
      debugPrint("Failed to fetch printers: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPrinters = false);
    }
  }

  Future<void> _saveSelection() async {
    setState(() => _isSaving = true);
    try {
      final res = await sl<ApiClient>().post(
        '/api/printer',
        data: {
          'printer_50x25': _selected50 ?? '',
          'printer_100x50': _selected100 ?? '',
        },
      );

      if (res.statusCode == 200) {
        widget.onPrinterConfigured();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerNames = _availablePrinters.map((p) => p.name).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.print_outlined, color: Color(0xFF0F172A), size: 20),
                  SizedBox(width: 8),
                  Text("DUAL THERMAL PRINTER CONFIGURATION",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Map dedicated physical hardware for both sticker profiles:",
                style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              if (_isLoadingPrinters)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
                const Text("1. Small Label Printer (50x25 mm)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: printerNames.contains(_selected50) ? _selected50 : null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                  hint: const Text("Select Printer for 50x25 mm", style: TextStyle(fontSize: 12)),
                  items: printerNames
                      .map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (v) => setState(() => _selected50 = v),
                ),
                const SizedBox(height: 14),
                const Text("2. Large Label Printer (100x50 mm)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: printerNames.contains(_selected100) ? _selected100 : null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                  hint: const Text("Select Printer for 100x50 mm", style: TextStyle(fontSize: 12)),
                  items: printerNames
                      .map((name) => DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (v) => setState(() => _selected100 = v),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                    onPressed: _isSaving ? null : _saveSelection,
                    child: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("SAVE PRINTERS",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}