import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:svenska/features/main/presentation/pages/vehicle_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class MasterManagementModal extends StatefulWidget {
  final VoidCallback onMasterUpdated;
  const MasterManagementModal({super.key, required this.onMasterUpdated});

  @override
  State<MasterManagementModal> createState() => _MasterManagementModalState();
}

class _MasterManagementModalState extends State<MasterManagementModal> {
  final _modelCtrl = TextEditingController();
  final _custPartCtrl = TextEditingController();
  final _partCtrl = TextEditingController();
  final _mfgDateCtrl = TextEditingController();
  final _fixedQrCtrl = TextEditingController();

  final FocusNode _fnModel = FocusNode();
  final FocusNode _fnCust = FocusNode();
  final FocusNode _fnPart = FocusNode();
  final FocusNode _fnDate = FocusNode();
  final FocusNode _fnQr = FocusNode();

  List<VehicleMaster> _items = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _qrValidationError;

  String _selectedLogoKey = 'suprajit';

  final List<Map<String, String>> _availableLogos = [
    {'key': 'suprajit', 'label': 'Suprajit'},
    {'key': 'birla', 'label': 'Birla Tyres'},
    {'key': 'dhoot', 'label': 'Dhoot Transmissions'},
    {'key': 'sansera', 'label': 'Sansera'},
    {'key': 'none', 'label': 'No Logo / Text Only'},
  ];

  /// Logos shown in the dropdown (other assets remain available for existing records).
  static const List<Map<String, String>> visibleLogos = [
    {'key': 'suprajit', 'label': 'Suprajit'},
  ];

  List<Map<String, String>> _logoDropdownItems() {
    final visibleKeys = visibleLogos.map((e) => e['key']).toSet();
    if (visibleKeys.contains(_selectedLogoKey)) return visibleLogos;
    final existing = _availableLogos.firstWhere(
      (e) => e['key'] == _selectedLogoKey,
      orElse: () => {'key': _selectedLogoKey, 'label': _selectedLogoKey},
    );
    return [...visibleLogos, existing];
  }

  @override
  void initState() {
    super.initState();
    _mfgDateCtrl.text = DateFormat('dd.MM.yyyy').format(_selectedDate);
    _loadItems();
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _custPartCtrl.dispose();
    _partCtrl.dispose();
    _mfgDateCtrl.dispose();
    _fixedQrCtrl.dispose();
    _fnModel.dispose();
    _fnCust.dispose();
    _fnPart.dispose();
    _fnDate.dispose();
    _fnQr.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/api/masters');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List raw = res.data['data'] ?? [];
        if (mounted) {
          setState(() => _items = raw.map((e) => VehicleMaster.fromMap(e)).toList());
          widget.onMasterUpdated();
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFormFromModel(VehicleMaster item) {
    setState(() {
      _modelCtrl.text = item.vehicleModel;
      _custPartCtrl.text = item.customerPartNo;
      _partCtrl.text = item.partNo;
      _mfgDateCtrl.text = item.dateOfMfg.isNotEmpty
          ? item.dateOfMfg
          : DateFormat('dd.MM.yyyy').format(DateTime.now());
      _fixedQrCtrl.text = item.fixedQrCode;
      _selectedLogoKey = item.companyLogo.isNotEmpty ? item.companyLogo : 'suprajit';
      _qrValidationError = null;
    });
    _showToast("Loaded: ${item.vehicleModel} into form");
  }

  Future<void> _pickDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _mfgDateCtrl.text = DateFormat('dd.MM.yyyy').format(picked);
      });
      _fnQr.requestFocus();
    }
  }

  Future<void> _saveMaster() async {
    final model = _modelCtrl.text.trim();
    final fixedQr = _fixedQrCtrl.text.trim();

    if (model.isEmpty) {
      _showToast("Vehicle Model is required!");
      _fnModel.requestFocus();
      return;
    }

    if (fixedQr.length != 19) {
      setState(() {
        _qrValidationError = "Fixed QR must be exactly 19 characters (current: ${fixedQr.length})";
      });
      _fnQr.requestFocus();
      _showToast("Validation Failed: Fixed QR must be exactly 19 characters!", isError: true);
      return;
    }

    setState(() => _qrValidationError = null);

    try {
      final res = await sl<ApiClient>().post(
        '/api/masters',
        data: {
          'vehicle_model': model,
          'customer_part_no': _custPartCtrl.text.trim(),
          'part_no': _partCtrl.text.trim(),
          'date_of_mfg': _mfgDateCtrl.text.trim(),
          'fixed_qr_code': fixedQr,
          'company_logo': _selectedLogoKey,
        },
      );

      if (res.statusCode == 200) {
        await _loadItems();
        _modelCtrl.clear();
        _custPartCtrl.clear();
        _partCtrl.clear();
        _mfgDateCtrl.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
        _fixedQrCtrl.clear();
        setState(() {
          _selectedLogoKey = 'suprajit';
          _qrValidationError = null;
        });
        _fnModel.requestFocus();
        _showToast("Master entry saved on Server!");
      }
    } catch (e) {
      _showToast("Failed to save master on server: $e", isError: true);
    }
  }

  Future<void> _deleteMaster(int id) async {
    try {
      final res = await sl<ApiClient>().delete('/api/masters/$id');
      if (res.statusCode == 200) {
        await _loadItems();
        _showToast("Entry removed from server");
      }
    } catch (e) {
      _showToast("Delete failed: $e", isError: true);
    }
  }

  Future<void> _resetSerial(String model) async {
    try {
      final res = await sl<ApiClient>().post(
        '/api/serial/reset',
        data: {'model': model},
      );
      if (res.statusCode == 200) {
        _showToast("Serial reset to 0001 on server!");
      }
    } catch (e) {
      _showToast("Reset failed: $e", isError: true);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFDC2626) : Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 890,
        height: 640,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1)))),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  const Text("VEHICLE MASTER ENTRY",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: isMobile
                  ? DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Color(0xFF2563EB),
                      unselectedLabelColor: Color(0xFF475569),
                      tabs: [
                        Tab(text: "Add / Edit"),
                        Tab(text: "Master Items"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildForm()),
                          _buildMasterList(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : Row(
                children: [
                  Container(
                    width: 380,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFCBD5E1)))),
                    child: SingleChildScrollView(child: _buildForm()),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMasterList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("ADD / EDIT MASTER RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            if (_modelCtrl.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _modelCtrl.clear();
                    _custPartCtrl.clear();
                    _partCtrl.clear();
                    _fixedQrCtrl.clear();
                    _mfgDateCtrl.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
                    _qrValidationError = null;
                  });
                },
                child: const Text("Clear Form", style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildScanField("1. Vehicle Model *", _modelCtrl, _fnModel, _fnCust, "e.g., U261 SPORT"),
        const SizedBox(height: 10),
        _buildScanField("2. Customer Part No", _custPartCtrl, _fnCust, _fnPart, "e.g., N8221260"),
        const SizedBox(height: 10),
        _buildScanField("3. Part No", _partCtrl, _fnPart, _fnDate, "e.g., OFG-SPM-00026"),
        const SizedBox(height: 10),
        const Text("4. Date of MFG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 3),
        SizedBox(
          height: 38,
          child: TextField(
            controller: _mfgDateCtrl,
            focusNode: _fnDate,
            readOnly: true,
            onTap: _pickDateFromCalendar,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_month, size: 16),
              suffixIcon: Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // FIXED QR CODE - STRICT 20 DIGITS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("5. Fixed QR Code (19 Characters) *",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(
              "${_fixedQrCtrl.text.length}/19",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _fixedQrCtrl.text.length == 19 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 38,
          child: TextField(
            controller: _fixedQrCtrl,
            focusNode: _fnQr,
            maxLength: 19,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            inputFormatters: [
              LengthLimitingTextInputFormatter(19),
            ],
            onChanged: (val) {
              setState(() {
                if (val.length != 19) {
                  _qrValidationError = "Must be exactly 19 characters";
                } else {
                  _qrValidationError = null;
                }
              });
            },
            onSubmitted: (_) => _saveMaster(),
            decoration: InputDecoration(
              counterText: "",
              hintText: "Enter 19-character fixed QR code",
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              prefixIcon: const Icon(Icons.qr_code_2, size: 16),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
        if (_qrValidationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _qrValidationError!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),

        const SizedBox(height: 10),
        const Text("6. Company Logo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 3),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            value: _selectedLogoKey,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
            items: _logoDropdownItems().map((item) {
              return DropdownMenuItem<String>(
                value: item['key'],
                child: Text(item['label']!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLogoKey = val);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _saveMaster,
            child: const Text("SAVE TO SERVER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MASTER ITEMS ON SERVER (${_items.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
              const Text("Click item to auto-fill form", style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(
              child: Text("Database empty. Add records to begin.", style: TextStyle(color: Color(0xFF475569), fontSize: 12)))
              : ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final item = _items[i];
              final isSelected = _modelCtrl.text.trim().toLowerCase() == item.vehicleModel.trim().toLowerCase();

              return InkWell(
                onTap: () => _populateFormFromModel(item),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB).withOpacity(0.06) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(item.vehicleModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.blueGrey.shade200),
                                  ),
                                  child: Text(
                                    item.companyLogo.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Cust PN: ${item.customerPartNo}  |  PN: ${item.partNo}  |  MFG: ${item.dateOfMfg}",
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                            ),
                            Row(
                              children: [
                                Text(
                                  "QR: ${item.fixedQrCode}",
                                  style: const TextStyle(fontSize: 10, fontFamily: 'Consolas', color: Colors.blueGrey),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: item.fixedQrCode.length == 19 ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    "${item.fixedQrCode.length} chars",
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: item.fixedQrCode.length == 19 ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: "Reset Serial to 0001",
                        icon: const Icon(Icons.restart_alt, size: 18, color: Colors.orange),
                        onPressed: () => _resetSerial(item.vehicleModel),
                      ),
                      IconButton(
                        tooltip: "Delete from Master",
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () {
                          if (item.id != null) _deleteMaster(item.id!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanField(
      String label,
      TextEditingController ctrl,
      FocusNode currentFn,
      FocusNode? nextFn,
      String hint, {
        VoidCallback? onFinalSubmit,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 3),
        SizedBox(
          height: 38,
          child: TextField(
            controller: ctrl,
            focusNode: currentFn,
            textInputAction: nextFn != null ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) {
              if (nextFn != null) {
                FocusScope.of(context).requestFocus(nextFn);
              } else if (onFinalSubmit != null) {
                onFinalSubmit();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              prefixIcon: const Icon(Icons.barcode_reader, size: 16),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}