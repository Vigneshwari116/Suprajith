import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/server_process_service.dart';
import '../../../../injection.dart';

class ServerStatusBadge extends StatefulWidget {
  const ServerStatusBadge({super.key});

  @override
  State<ServerStatusBadge> createState() => _ServerStatusBadgeState();
}

class _ServerStatusBadgeState extends State<ServerStatusBadge> {
  bool _isRunning = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _check();
    // Har 3 second me live API ping check karega
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  /// REST API ke zariye live check karega (Cross-platform compatible)
  Future<void> _check() async {
    bool active = false;
    try {
      final res = await sl<ApiClient>().get('/api/ping');
      active = (res.statusCode == 200 && res.data['status'] == 'online');
    } catch (_) {
      active = false;
    }

    if (mounted && _isRunning != active) {
      setState(() => _isRunning = active);
    }
  }

  void _onBadgeTapped() async {
    final isHost = ServerProcessService.isHostMachine();
    if (!isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access Denied: Server process can only be started/stopped from Host PC."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServerAdminDialog(
        isCurrentlyRunning: _isRunning,
        onStateChanged: _check,
      ),
    );

    // Dialog band hote hi instant re-check
    _check();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Print Server Status (Tap to Manage)",
      child: InkWell(
        onTap: _onBadgeTapped,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _isRunning ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isRunning ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRunning ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isRunning ? "SERVER OK" : "SERVER DOWN",
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: _isRunning ? const Color(0xFF166534) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServerAdminDialog extends StatefulWidget {
  final bool isCurrentlyRunning;
  final VoidCallback onStateChanged;

  const ServerAdminDialog({
    super.key,
    required this.isCurrentlyRunning,
    required this.onStateChanged,
  });

  @override
  State<ServerAdminDialog> createState() => _ServerAdminDialogState();
}

class _ServerAdminDialogState extends State<ServerAdminDialog> {
  final _pinCtrl = TextEditingController();

  final _oldPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _isUnlocked = false;
  bool _isChangingPin = false;
  bool _isProcessing = false;
  late bool _isRunning;
  String? _errorMsg;
  String? _pinChangeMsg;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isCurrentlyRunning;
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _oldPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final entered = _pinCtrl.text.trim();
    if (entered.length != 6) {
      setState(() => _errorMsg = "Please enter full 6-digit PIN");
      return;
    }

    final isValid = await ServerProcessService.verifyPin(entered);
    if (isValid) {
      setState(() {
        _isUnlocked = true;
        _errorMsg = null;
      });
    } else {
      setState(() => _errorMsg = "Incorrect PIN!");
    }
  }

  Future<void> _handleToggle() async {
    setState(() => _isProcessing = true);
    if (_isRunning) {
      final stopped = await ServerProcessService.stopServer();
      if (mounted) setState(() => _isRunning = !stopped);
    } else {
      final started = await ServerProcessService.startServer();
      if (mounted) setState(() => _isRunning = started);
    }

    // Process change ke baad 500ms delay taaki server socket release/bind ho jaye
    await Future.delayed(const Duration(milliseconds: 600));

    widget.onStateChanged();
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _submitPinChange() async {
    final oldP = _oldPinCtrl.text.trim();
    final newP = _newPinCtrl.text.trim();
    final confP = _confirmPinCtrl.text.trim();

    if (newP.length != 6 || int.tryParse(newP) == null) {
      setState(() => _pinChangeMsg = "New PIN must be exactly 6 digits.");
      return;
    }
    if (newP != confP) {
      setState(() => _pinChangeMsg = "New PIN and Confirmation do not match!");
      return;
    }

    final isOldCorrect = await ServerProcessService.verifyPin(oldP);
    if (!isOldCorrect) {
      setState(() => _pinChangeMsg = "Current PIN is incorrect!");
      return;
    }

    final saved = await ServerProcessService.updatePin(newP);
    if (saved) {
      setState(() {
        _isChangingPin = false;
        _pinChangeMsg = null;
        _oldPinCtrl.clear();
        _newPinCtrl.clear();
        _confirmPinCtrl.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Supervisor PIN updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.blueGrey.shade800, size: 22),
                const SizedBox(width: 8),
                const Text(
                  "SUPERVISOR PANEL",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),
            if (!_isUnlocked) ...[
              const Text(
                "Enter 6-digit Supervisor PIN to control print server:",
                style: TextStyle(fontSize: 11.5, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _verifyPin(),
                decoration: InputDecoration(
                  labelText: "6-Digit PIN",
                  counterText: "",
                  errorText: _errorMsg,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                  onPressed: _verifyPin,
                  child: const Text("UNLOCK CONTROLS", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (_isChangingPin) ...[
              const Text("CHANGE 6-DIGIT SUPERVISOR PIN", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _oldPinCtrl,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Current PIN (or Master PIN)", counterText: "", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPinCtrl,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "New 6-Digit PIN", counterText: "", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPinCtrl,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Confirm New PIN", counterText: "", border: OutlineInputBorder()),
              ),
              if (_pinChangeMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_pinChangeMsg!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isChangingPin = false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: _submitPinChange,
                      child: const Text("SAVE PIN", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isRunning ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _isRunning ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(_isRunning ? Icons.check_circle : Icons.error, color: _isRunning ? Colors.green : Colors.red),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRunning ? "SERVICE RUNNING" : "SERVICE OFFLINE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _isRunning ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          ),
                        ),
                        const Text("Host Process (Port 8080)", style: TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.red.shade600 : Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isProcessing ? null : _handleToggle,
                  icon: Icon(_isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: _isProcessing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isRunning ? "STOP SERVER" : "START SERVER"),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _isChangingPin = true),
                  icon: const Icon(Icons.key_rounded, size: 16),
                  label: const Text("Change Supervisor PIN", style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}