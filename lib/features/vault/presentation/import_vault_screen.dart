import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/vault_provider.dart';

class ImportVaultScreen extends ConsumerStatefulWidget {
  const ImportVaultScreen({super.key});

  @override
  ConsumerState<ImportVaultScreen> createState() => _ImportVaultScreenState();
}

class _ImportVaultScreenState extends ConsumerState<ImportVaultScreen> {
  List<_CsvRow>? _preview;
  String? _filePath;
  bool _importing = false;
  String? _error;
  int _imported = 0;

  Future<void> _pickFile() async {
    setState(() { _error = null; _preview = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    setState(() => _filePath = path);

    try {
      final contents = await File(path).readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(contents);
      if (rows.isEmpty) {
        setState(() => _error = 'CSV file is empty.');
        return;
      }

      // Detect header row
      final header = rows.first.map((c) => c.toString().toLowerCase()).toList();
      final nameIdx     = _findCol(header, ['name', 'service', 'title', 'website']);
      final usernameIdx = _findCol(header, ['username', 'login', 'user', 'email']);
      final passwordIdx = _findCol(header, ['password', 'pass', 'pwd']);
      final urlIdx      = _findCol(header, ['url', 'website', 'domain', 'uri']);
      final notesIdx    = _findCol(header, ['notes', 'note', 'comment']);
      final catIdx      = _findCol(header, ['category', 'folder', 'group', 'type']);

      if (nameIdx < 0 || passwordIdx < 0) {
        setState(() => _error =
            'CSV must have at least "name/service" and "password" columns.');
        return;
      }

      final data = rows.skip(1).map((row) {
        String col(int idx) =>
            idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';
        return _CsvRow(
          name:     col(nameIdx),
          username: col(usernameIdx),
          password: col(passwordIdx),
          url:      col(urlIdx),
          notes:    col(notesIdx),
          category: col(catIdx).isEmpty ? 'personal' : col(catIdx).toLowerCase(),
        );
      }).where((r) => r.name.isNotEmpty && r.password.isNotEmpty).toList();

      setState(() => _preview = data);
    } catch (e) {
      setState(() => _error = 'Failed to parse CSV: $e');
    }
  }

  int _findCol(List<String> header, List<String> candidates) {
    for (final c in candidates) {
      final idx = header.indexOf(c);
      if (idx >= 0) return idx;
    }
    // Partial match
    for (var i = 0; i < header.length; i++) {
      for (final c in candidates) {
        if (header[i].contains(c)) return i;
      }
    }
    return -1;
  }

  Future<void> _import() async {
    if (_preview == null || _preview!.isEmpty) return;
    setState(() { _importing = true; _imported = 0; _error = null; });

    int count = 0;
    final notifier = ref.read(vaultProvider.notifier);

    for (final row in _preview!) {
      try {
        await notifier.create(
          name:          row.name,
          username:      row.username,
          plainPassword: row.password,
          url:           row.url,
          notes:         row.notes,
          category:      row.category,
        );
        count++;
        if (mounted) setState(() => _imported = count);
      } catch (_) {
        // Skip failed entries
      }
    }

    if (mounted) {
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count passwords successfully.')),
      );
      if (count > 0) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Vault')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info card ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.info, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('CSV Format',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your CSV file should have these columns (header row required):\n'
                      '• name / service / title\n'
                      '• username / login / email\n'
                      '• password\n'
                      '• url / website (optional)\n'
                      '• notes (optional)\n'
                      '• category / folder (optional)\n\n'
                      'Compatible with: Apple Passwords, 1Password, Bitwarden, '
                      'LastPass, Chrome, and most other managers.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── File picker ──────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _importing ? null : _pickFile,
              icon: const Icon(Symbols.upload_file),
              label: Text(_filePath == null
                  ? 'Choose CSV File'
                  : 'Choose Another File'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Symbols.error,
                      color: theme.colorScheme.error),
                  title: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ],

            // ── Preview ──────────────────────────────────────────────────
            if (_preview != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_preview!.length} passwords found',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...(_preview!.take(5).map((row) => Card(
                    child: ListTile(
                      leading: const Icon(Symbols.key),
                      title: Text(row.name),
                      subtitle: Text(row.username.isEmpty
                          ? row.url
                          : row.username),
                      trailing: Text(
                        row.category,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ))),
              if (_preview!.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '+ ${_preview!.length - 5} more…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              _importing
                  ? Column(
                      children: [
                        LinearProgressIndicator(
                          value: _preview!.isEmpty
                              ? null
                              : _imported / _preview!.length,
                        ),
                        const SizedBox(height: 8),
                        Text('Importing $_imported / ${_preview!.length}…'),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: _import,
                      icon: const Icon(Symbols.download),
                      label:
                          Text('Import ${_preview!.length} Passwords'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CsvRow {
  final String name;
  final String username;
  final String password;
  final String url;
  final String notes;
  final String category;

  const _CsvRow({
    required this.name,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.category,
  });
}
