import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:svenska/features/main/presentation/pages/print_history_audit_modal.dart';
import 'package:svenska/features/main/presentation/pages/vehicle_models.dart';
import '../../../../core/constants/app_mode.dart';
import '../../../../core/services/local_label_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';
import 'dual_printer_settings_modal.dart';
import 'frontend_label_engine.dart';
import 'logo_assets_resolver.dart';
import 'master_management_modal.dart';
import '../../../../core/constants/label_config.dart';
import 'today_prints_panel.dart';
import 'u350_label_preview.dart';

// THEME & COLOR PALETTE
const Color kAppBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kPrimary = Color(0xFF0F172A);
const Color kAccent = Color(0xFF2563EB);
const Color kBorder = Color(0xFFCBD5E1);
const Color kTextPrimary = Color(0xFF000000);
const Color kTextSecondary = Color(0xFF475569);
const Color kLightTint = Color(0xFFF8FAFC);
const Color kErrorRed = Color(0xFFDC2626);

class VehicleQRWorkstationPage extends StatefulWidget {
  const VehicleQRWorkstationPage({super.key});

  @override
  State<VehicleQRWorkstationPage> createState() => _VehicleQRWorkstationPageState();
}

class _VehicleQRWorkstationPageState extends State<VehicleQRWorkstationPage> {
  List<VehicleMaster> _masterList = [];

  final _modelInputCtrl = TextEditingController();
  final _fixedQrDisplayCtrl = TextEditingController();
  final FocusNode _scannerFocusNode = FocusNode();

  DateTime _displayToday = DateTime.now();
  Timer? _midnightRefreshTimer;

  VehicleMaster? _selectedMaster;
  Map<String, String>? _activeLabelData;
  bool _isPrintingInProgress = false;
  String? _validationError;

  String _selectedLabelSize = '50x25';
  String? _printer50x25 = 'TSC TTP-244 Plus';
  String? _printer100x50;

  bool get _isHostMachine {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  @override
  void initState() {
    super.initState();
    _loadMasterRecords();
    _loadPrinterConfig();
    _startTodayDateRefreshTimer();
  }

  void _startTodayDateRefreshTimer() {
    _syncDisplayToday();
    _midnightRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncDisplayToday();
    });
  }

  void _syncDisplayToday() {
    final now = DateTime.now();
    if (now.year != _displayToday.year ||
        now.month != _displayToday.month ||
        now.day != _displayToday.day) {
      if (mounted) {
        setState(() => _displayToday = now);
      }
    }
  }

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
    _modelInputCtrl.dispose();
    _fixedQrDisplayCtrl.dispose();
    _scannerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMasterRecords() async {
    try {
      final List raw = kUseLocalDataStore
          ? sl<LocalLabelService>().listMasters()
          : (await sl<ApiClient>().get('/api/masters')).data['data'] as List? ?? [];
      if (mounted) {
        final list = raw.map((e) => VehicleMaster.fromMap(e as Map<String, dynamic>)).toList();

        final uniqueMap = <String, VehicleMaster>{};
        for (var item in list) {
          uniqueMap[item.vehicleModel.trim().toLowerCase()] = item;
        }

        setState(() {
          _masterList = uniqueMap.values.toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPrinterConfig() async {
    try {
      if (kUseLocalDataStore) {
        final data = sl<LocalLabelService>().getPrinterConfig();
        if (mounted) {
          setState(() {
            _printer50x25 = data['printer_50x25']?.toString().isNotEmpty == true
                ? data['printer_50x25']?.toString()
                : 'TSC TTP-244 Plus';
            _printer100x50 = data['printer_100x50']?.toString();
          });
        }
        return;
      }
      final res = await sl<ApiClient>().get('/api/printer');
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _printer50x25 = res.data['printer_50x25']?.toString().isNotEmpty == true
              ? res.data['printer_50x25']?.toString()
              : 'TSC TTP-244 Plus';
          _printer100x50 = res.data['printer_100x50']?.toString();
        });
      }
    } catch (_) {}
  }

  void _onModelSelectedFromDropdown(String val) {
    setState(() {
      _modelInputCtrl.text = val;
      _modelInputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: val.length));
      _validationError = null;
      try {
        _selectedMaster = _masterList.firstWhere(
              (m) => m.vehicleModel.toLowerCase().trim() == val.toLowerCase().trim(),
        );
        _fixedQrDisplayCtrl.text = _selectedMaster?.fixedQrCode ?? '';
      } catch (_) {
        _selectedMaster = null;
        _fixedQrDisplayCtrl.clear();
      }
    });
    _scannerFocusNode.requestFocus();
  }

  void _onSearchTextChanged(String val) {
    final query = val.trim().toLowerCase();
    setState(() {
      _validationError = null;
      try {
        _selectedMaster = _masterList.firstWhere(
              (m) =>
          m.vehicleModel.toLowerCase().trim() == query ||
              m.customerPartNo.toLowerCase().trim() == query ||
              m.partNo.toLowerCase().trim() == query,
        );
        _fixedQrDisplayCtrl.text = _selectedMaster?.fixedQrCode ?? '';
      } catch (_) {
        _selectedMaster = null;
        _fixedQrDisplayCtrl.clear();
      }
    });
  }

  String? _resolveAssetLogoPath(String logoKey) {
    final key = logoKey.toLowerCase().trim();
    if (key == 'suprajit') return 'assets/logos/suprajit.png';
    if (key == 'birla') return 'assets/logos/birla.png';
    if (key == 'dhoot') return 'assets/logos/dhoot.png';
    if (key == 'sansera') return 'assets/logos/sansera.png';
    return null;
  }

  Future<void> _handleEnterAndPrint() async {
    final query = _modelInputCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _validationError = "Please scan or enter a Vehicle Model!");
      _scannerFocusNode.requestFocus();
      return;
    }

    if (_isPrintingInProgress) return;

    VehicleMaster? matched;
    try {
      matched = _masterList.firstWhere(
            (m) =>
        m.vehicleModel.toLowerCase().trim() == query.toLowerCase() ||
            m.customerPartNo.toLowerCase().trim() == query.toLowerCase() ||
            m.partNo.toLowerCase().trim() == query.toLowerCase(),
      );
    } catch (_) {
      matched = null;
    }

    if (matched == null) {
      setState(() => _validationError = "Model '$query' not found in Master Database!");
      _scannerFocusNode.requestFocus();
      return;
    }

    final masterFixedQr = matched.fixedQrCode.trim();
    if (masterFixedQr.length != 19) {
      setState(() => _validationError =
      "Fixed QR must be exactly 19 characters! Current has ${masterFixedQr.length}. Edit in Master Entry.");
      _showToast("Invalid Master QR length: Expected exactly 19 characters", isError: true);
      _scannerFocusNode.requestFocus();
      return;
    }

    setState(() {
      _validationError = null;
      _isPrintingInProgress = true;
      _fixedQrDisplayCtrl.text = masterFixedQr;
    });

    final printMoment = DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy').format(printMoment);
    final targetPrinter = _selectedLabelSize == '100x50'
        ? (_printer100x50 ?? 'TSC TTP-244 Plus')
        : (_printer50x25 ?? 'TSC TTP-244 Plus');

    try {
      final Map<String, dynamic> data;
      if (kUseLocalDataStore) {
        data = sl<LocalLabelService>().preparePrint(
          modelQuery: matched.vehicleModel,
          labelSize: _selectedLabelSize,
        );
      } else {
        final response = await sl<ApiClient>().post(
          '/api/print',
          data: {
            'model': matched.vehicleModel,
            'date': formattedDate,
            'label_size': _selectedLabelSize,
          },
        );
        data = Map<String, dynamic>.from(response.data as Map);
        if (response.statusCode != 200 || data['status'] != 'success') {
          final err = data['message'] ?? 'Server could not prepare serial payload.';
          _showToast("PRINT FAILED: $err", isError: true);
          return;
        }
      }

      if (data['status'] == 'success') {
        final String serialStr = data['serial']?.toString() ?? '0001';
        final String fullPayload = data['full_payload']?.toString() ?? '';

        final logoImage = await LogoAssetResolver.getLogoImage(matched.companyLogo);

        final Uint8List pdfBytes;
        if (_selectedLabelSize == '100x50') {
          pdfBytes = await FrontendLabelEngine.build100x50Pdf(
            model: matched.vehicleModel,
            custPart: matched.customerPartNo,
            partNo: matched.partNo,
            mfgDate: formattedDate,
            serial: serialStr,
            qrPayload: fullPayload,
            logoImage: logoImage,
          );
        } else {
          pdfBytes = await FrontendLabelEngine.build50x25Pdf(
            model: matched.vehicleModel,
            customerPartNo: matched.customerPartNo,
            partNo: matched.partNo,
            mfgDate: formattedDate,
            qrPayload: fullPayload,
            logoImage: logoImage,
          );
        }

        await FrontendLabelEngine.directHardwareDispatch(
          pdfBytes: pdfBytes,
          printerName: targetPrinter,
          jobName: 'Label_${matched.vehicleModel}_$serialStr',
          pageFormat: _selectedLabelSize == '100x50'
              ? kLabel100x50PageFormat
              : kLabel50x25PageFormat,
        );

        final labelMap = {
          'model': matched.vehicleModel,
          'customer_part_no': matched.customerPartNo,
          'part_no': matched.partNo,
          'date_of_mfg': formattedDate,
          'qr_data': fullPayload,
          'sn': serialStr,
          'size': _selectedLabelSize,
          'logo': matched.companyLogo,
        };

        if (mounted) {
          setState(() {
            _selectedMaster = matched;
            _activeLabelData = labelMap;
          });
        }
        _showToast("Printed Successfully: #$serialStr to $targetPrinter", isError: false);
      } else {
        final err = data['message'] ?? 'Server could not prepare serial payload.';
        _showToast("PRINT FAILED: $err", isError: true);
      }
    } catch (e) {
      _showToast("Print Error: ${e.toString().replaceAll("Exception: ", "")}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPrintingInProgress = false);
        _scannerFocusNode.requestFocus();
        _modelInputCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _modelInputCtrl.text.length),
        );
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? kErrorRed : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _openMasterModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MasterManagementModal(
        onMasterUpdated: () => _loadMasterRecords(),
      ),
    );
  }

  void _openPrinterSettingsModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DualPrinterSettingsModal(
        currentPrinter50: _printer50x25,
        currentPrinter100: _printer100x50,
        onPrinterConfigured: () => _loadPrinterConfig(),
      ),
    );
  }

  void _openHistoryModal() {
    showDialog(
      context: context,
      builder: (ctx) => const PrintHistoryAuditModal(),
    );
  }

  Widget _buildFixedQrReadOnlyField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _fixedQrDisplayCtrl,
        readOnly: true,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Consolas',
          fontWeight: FontWeight.bold,
          color: kAccent,
        ),
        decoration: InputDecoration(
          labelText: "Fixed QR Code (19 Digits)",
          labelStyle: const TextStyle(fontSize: 11, color: kTextSecondary),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: "[Select Model to View QR]",
          hintStyle: const TextStyle(fontSize: 10.5, color: Colors.grey),
          prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 18, color: kAccent),
          fillColor: kLightTint,
          filled: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildSearchAndDropdown({required bool isMobile}) {
    final uniqueModels = _masterList.map((m) => m.vehicleModel.trim()).toSet().toList();

    final String? currentDropdownValue = uniqueModels.firstWhere(
          (m) => m.toLowerCase() == _modelInputCtrl.text.trim().toLowerCase(),
      orElse: () => '',
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _modelInputCtrl,
              focusNode: _scannerFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: _onSearchTextChanged,
              onSubmitted: (_) => _handleEnterAndPrint(),
              decoration: InputDecoration(
                hintText: "Scan Model Barcode or Type...",
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.barcode_reader, size: 20, color: kPrimary),
                suffixIcon: _modelInputCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _modelInputCtrl.clear();
                      _fixedQrDisplayCtrl.clear();
                      _selectedMaster = null;
                      _activeLabelData = null;
                      _validationError = null;
                    });
                    _scannerFocusNode.requestFocus();
                  },
                )
                    : null,
                border: OutlineInputBorder(borderSide: BorderSide(color: _validationError != null ? kErrorRed : kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _validationError != null ? kErrorRed : kAccent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text(isMobile ? "Select" : "Select Dropdown", style: const TextStyle(fontSize: 12)),
              value: currentDropdownValue != null && currentDropdownValue.isNotEmpty ? currentDropdownValue : null,
              items: uniqueModels.map((modelName) {
                return DropdownMenuItem<String>(
                  value: modelName,
                  child: Text(
                    modelName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) _onModelSelectedFromDropdown(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTodayDate(String formattedDate) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kLightTint,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 18, color: kAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Date (QR & Label)",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: kTextSecondary),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: _handleEnterAndPrint,
      icon: const Icon(Icons.print_rounded, size: 18),
      label: Text("PRINT ($_selectedLabelSize)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
    );
  }

  Widget _buildLargeStickerCard(Map<String, String> item) {
    final String qrData = item['qr_data'] ?? '';
    final String model = item['model'] ?? '';
    final String custPart = item['customer_part_no'] ?? '';
    final String part = item['part_no'] ?? '';
    final String mfg = item['date_of_mfg'] ?? '';
    final String sn = item['sn'] ?? '';
    final String logoKey = item['logo'] ?? 'none';
    final String? logoPath = _resolveAssetLogoPath(logoKey);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1.4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              logoPath != null
                  ? Container(
                height: 24,
                width: 110,
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    logoKey.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Colors.black),
                  ),
                ),
              )
                  : const Row(
                children: [
                  Icon(Icons.rotate_right_rounded, size: 16, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    "SVENSKA AUTOMOTIVE",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: Colors.black),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kLightTint,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text("#$sn", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kAccent)),
              ),
            ],
          ),
          const Divider(thickness: 0.8, color: Colors.black, height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                QrImageView(
                  data: qrData,
                  size: 92,
                  padding: EdgeInsets.zero,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExactLine("Model", model),
                      const SizedBox(height: 3),
                      _buildExactLine("Cust PN", custPart),
                      const SizedBox(height: 3),
                      _buildExactLine("Part No", part),
                      const SizedBox(height: 3),
                      _buildExactLine("MFG", mfg),
                      const SizedBox(height: 3),
                      _buildExactLine("Serial No", sn),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 0.8, color: Colors.black, height: 10),
          Center(
            child: Text(
              qrData,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'Consolas',
                letterSpacing: 1.1,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStickerCard(Map<String, String> item) {
    final String qrData = item['qr_data'] ?? '';
    final String model = item['model'] ?? '';
    final String custPart = item['customer_part_no'] ?? '';
    final String part = item['part_no'] ?? '';
    final String mfg = item['date_of_mfg'] ?? '';
    final String logoKey = item['logo'] ?? 'none';
    final String? logoPath = _resolveAssetLogoPath(logoKey);

    if (showKeepUpExtras(model)) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: U350LabelPreview(
          model: model,
          customerPartNo: custPart,
          partNo: part,
          mfgDate: mfg,
          qrData: qrData,
          logoAssetPath: logoPath,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // LEFT: LOGO + TIGHT GAP + CLEAN QR
          SizedBox(
            width: 78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 20,
                  width: 74,
                  alignment: Alignment.center,
                  child: logoPath != null
                      ? Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      logoKey.toUpperCase(),
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  )
                      : Text(
                    logoKey.toUpperCase(),
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 3),
                QrImageView(
                  data: qrData,
                  size: 64,
                  padding: EdgeInsets.zero,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // RIGHT: SPECS
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExactLine("Vehicle Model", model),
                const SizedBox(height: 3),
                _buildExactLine("Customer Part No", custPart),
                const SizedBox(height: 3),
                _buildExactLine("Part No", part),
                const SizedBox(height: 3),
                _buildExactLine("Date of MFG", mfg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExactLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black),
          ),
        ),
        const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black)),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    if (!kEnableLargeLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kAccent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'Small (50x25 mm)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: kLightTint,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sizeOptionBtn('50x25', 'Small (50x25 mm)'),
          _sizeOptionBtn('100x50', 'Large (100x50 mm)'),
        ],
      ),
    );
  }

  Widget _sizeOptionBtn(String sizeKey, String label) {
    final isSelected = _selectedLabelSize == sizeKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedLabelSize = sizeKey);
        _scannerFocusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : kTextSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1024;
    final formattedActiveDate = DateFormat('dd.MM.yyyy').format(_displayToday);
    final activeTargetPrinter = _selectedLabelSize == '100x50' ? _printer100x50 : _printer50x25;

    return Scaffold(
      backgroundColor: kAppBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kCardBg,
        titleSpacing: isMobile ? 12 : 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: kLightTint, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.qr_code_2_rounded, size: 20, color: kPrimary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMobile ? "SVENSKA WORKSTATION" : "SVENSKA AUTOMOTIVE — INDUSTRIAL WORKSTATION",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.indigoAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Print History",
            onPressed: _openHistoryModal,
            icon: const Icon(Icons.history_rounded, color: kTextSecondary),
          ),
          if (_isHostMachine)
            IconButton(
              tooltip: "Dual Printer Settings",
              onPressed: _openPrinterSettingsModal,
              icon: Icon(
                Icons.print_outlined,
                color: (_printer50x25 != null && _printer100x50 != null) ? kAccent : Colors.orange,
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
            color: kCardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Vehicle Model",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                      _buildSizeSelector(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.print, size: 13, color: kTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activeTargetPrinter != null && activeTargetPrinter.isNotEmpty
                              ? "Target ($_selectedLabelSize): $activeTargetPrinter"
                              : "Target ($_selectedLabelSize): [Unconfigured]",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: activeTargetPrinter != null ? kAccent : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Text(
                        "Vehicle Model",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                      const SizedBox(width: 14),
                      _buildSizeSelector(),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          activeTargetPrinter != null && activeTargetPrinter.isNotEmpty
                              ? "Target ($_selectedLabelSize): $activeTargetPrinter"
                              : "Target ($_selectedLabelSize): [Unconfigured]",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: activeTargetPrinter != null ? kAccent : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (isMobile) ...[
                  _buildSearchAndDropdown(isMobile: true),
                  const SizedBox(height: 8),
                  _buildFixedQrReadOnlyField(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(flex: 5, child: _buildReadOnlyTodayDate(formattedActiveDate)),
                      const SizedBox(width: 8),
                      Expanded(flex: 5, child: _buildPrintButton()),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 4, child: _buildSearchAndDropdown(isMobile: false)),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _buildFixedQrReadOnlyField()),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: isTablet ? 130 : 160,
                        child: _buildReadOnlyTodayDate(formattedActiveDate),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        child: _buildPrintButton(),
                      ),
                    ],
                  ),
                ],
                if (_validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: kErrorRed, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(color: kErrorRed, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Center(
                child: Column(
                  children: [
                    if (_activeLabelData == null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          Icon(Icons.print_outlined, size: isMobile ? 48 : 64, color: kTextSecondary.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text("Ready for Scanning",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            "Scan or select Model and press ENTER to print directly to $_selectedLabelSize hardware.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextSecondary, fontSize: isMobile ? 12 : 13),
                          ),
                        ],
                      )
                    else
                      Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("ACTIVE LABEL [${_activeLabelData!['size'] ?? _selectedLabelSize}]",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextSecondary)),
                        const SizedBox(width: 8),
                        if (_isPrintingInProgress)
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kAccent))
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text("PRINTED DIRECTLY",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _selectedLabelSize == '100x50' ? 460 : 380,
                        maxHeight: _selectedLabelSize == '100x50'
                            ? 240
                            : (showKeepUpExtras(_activeLabelData!['model'] ?? '') ? 200 : 160),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _selectedLabelSize == '100x50'
                            ? SizedBox(width: 440, height: 230, child: _buildLargeStickerCard(_activeLabelData!))
                            : SizedBox(
                                width: 360,
                                height: showKeepUpExtras(_activeLabelData!['model'] ?? '')
                                    ? U350LabelPreview.heightPx
                                    : 140,
                                child: _buildSmallStickerCard(_activeLabelData!),
                              ),
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 20),
                    const TodayPrintsPanel(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}