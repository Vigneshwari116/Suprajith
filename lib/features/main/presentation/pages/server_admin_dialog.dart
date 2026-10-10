import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _isProcessing = false;
  late bool _isRunning;

  @override
  void initState() {
    super.initState();
    _isRunning = widget.isCurrentlyRunning;
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
          ],
        ),
      ),
    );
  }
}