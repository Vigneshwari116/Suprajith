import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:svenska/core/services/database_backup_service.dart';
import 'package:svenska/core/utils/app_restart.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  String? _status;

  Future<void> _backup() async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose backup folder');
    if (dir == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final path = await DatabaseBackupService.backupToDirectory(dir);
      setState(() => _status = 'Backup saved: $path');
    } catch (e) {
      setState(() => _status = 'Backup failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['db'],
      dialogTitle: 'Select database to restore',
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore database?'),
        content: const Text(
          'A safety copy of the current database will be created first. The app will reload data automatically.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final safety = await DatabaseBackupService.restoreFromFile(path);
      setState(() => _status = 'Restored. Safety copy: $safety');
      AppRestart.restart(context);
    } catch (e) {
      setState(() => _status = 'Restore failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            const Text(
              'Backup copies svenska_vehicle_yyyyMMdd_HHmmss.db to a folder you choose. '
              'Restore validates required tables, keeps a safety copy, then reloads the app.',
              style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _backup,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Backup database'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restore database'),
                ),
              ],
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator(strokeWidth: 2)),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_status!, style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
