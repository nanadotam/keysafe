import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../crypto/crypto_service.dart';
import '../../../crypto/key_store.dart';
import '../../vault/data/vault_repository.dart';
import '../../vault/domain/vault_entry.dart';
import '../../vault/providers/vault_provider.dart';

class VaultExportService {
  const VaultExportService(this._vaultRepository);

  final VaultRepository _vaultRepository;

  Future<File> buildProtectedExport(String password) async {
    final entries = await _vaultRepository.fetchAll();
    final csv = await _buildCsv(entries);
    if (csv.trim().isEmpty) {
      throw 'Your vault is empty.';
    }

    final archive = Archive();
    final csvFileName =
        'keysafe-vault-${DateTime.now().toIso8601String().split('T').first}.csv';
    final csvBytes = utf8.encode(csv);
    archive.addFile(
      ArchiveFile(csvFileName, csvBytes.length, csvBytes),
    );

    final zipBytes = ZipEncoder(password: password).encode(archive);
    if (zipBytes.isEmpty) {
      throw 'Failed to build export archive.';
    }

    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, '$csvFileName.zip'));
    await file.writeAsBytes(zipBytes, flush: true);
    return file;
  }

  Future<void> emailProtectedExport(String password) async {
    final recipient = await KeyStore.getUserEmail();
    if (recipient == null || recipient.isEmpty) {
      throw 'No account email found. Please log in again.';
    }

    final file = await buildProtectedExport(password);
    await FlutterEmailSender.send(
      Email(
        recipients: [recipient],
        subject: 'KeySafe Vault Export',
        body:
            'Your vault export is attached as a password-protected ZIP containing a CSV file. Use the export password you just chose in KeySafe to open it.',
        attachmentPaths: [file.path],
      ),
    );
  }

  Future<String> _buildCsv(List<VaultEntry> entries) async {
    if (entries.isEmpty) {
      return '';
    }

    final key = await KeyStore.getAesKey();
    if (key == null) {
      throw 'Vault key not found. Please log in again.';
    }

    final buffer = StringBuffer()
      ..writeln(
        [
          'name',
          'username',
          'password',
          'url',
          'notes',
          'category',
          'strengthScore',
          'createdAt',
          'updatedAt',
        ].join(','),
      );

    for (final entry in entries) {
      final plainPassword = CryptoService.decrypt(entry.encryptedPassword, key);
      buffer.writeln(
        [
          _escapeCsv(entry.name),
          _escapeCsv(entry.username),
          _escapeCsv(plainPassword),
          _escapeCsv(entry.url),
          _escapeCsv(entry.notes),
          _escapeCsv(entry.category),
          '${entry.strengthScore}',
          _escapeCsv(entry.createdAt.toIso8601String()),
          _escapeCsv(entry.updatedAt.toIso8601String()),
        ].join(','),
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

final vaultExportServiceProvider = Provider<VaultExportService>(
  (ref) => VaultExportService(ref.watch(vaultRepositoryProvider)),
);
