// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart' show BulkImportResult;

/// Signature for the per-content-type bulk-import call. Matches the shape of
/// ProductService.bulkImport / CategoryService.bulkImport.
typedef BulkImportRequest = Future<BulkImportResult> Function({
  required String token,
  required Uint8List xlsxBytes,
  required String xlsxFilename,
  Uint8List? zipBytes,
  String? zipFilename,
  bool dryRun,
});

/// Reusable Download Template / Export / Upload + Import dialog. Both the
/// products and categories admin screens drive it with their own endpoints
/// and import callbacks.
class AdminBulkImportDialog extends StatefulWidget {
  final String dialogTitle;
  final String instructions;
  final String templateEndpoint;
  final String exportEndpoint;
  final String templateFilename;
  final String exportFilenamePrefix;
  final String exportButtonLabel;
  final BulkImportRequest importFn;
  final VoidCallback onComplete;

  const AdminBulkImportDialog({
    super.key,
    required this.dialogTitle,
    required this.instructions,
    required this.templateEndpoint,
    required this.exportEndpoint,
    required this.templateFilename,
    required this.exportFilenamePrefix,
    required this.exportButtonLabel,
    required this.importFn,
    required this.onComplete,
  });

  @override
  State<AdminBulkImportDialog> createState() => _AdminBulkImportDialogState();
}

class _AdminBulkImportDialogState extends State<AdminBulkImportDialog> {
  bool _busy = false;
  bool _downloadingTemplate = false;
  bool _exportingCatalog = false;
  String _phaseLabel = '';
  String? _xlsxName;
  Uint8List? _xlsxBytes;
  String? _zipName;
  Uint8List? _zipBytes;
  String? _error;
  BulkImportResult? _result;

  Future<void> _downloadTemplate() => _downloadXlsx(
        endpoint: widget.templateEndpoint,
        filename: widget.templateFilename,
        busyFlagSetter: (v) => setState(() => _downloadingTemplate = v),
      );

  Future<void> _exportCurrent() => _downloadXlsx(
        endpoint: widget.exportEndpoint,
        filename:
            '${widget.exportFilenamePrefix}-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
        busyFlagSetter: (v) => setState(() => _exportingCatalog = v),
      );

  Future<void> _downloadXlsx({
    required String endpoint,
    required String filename,
    required void Function(bool) busyFlagSetter,
  }) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _error = 'Not signed in');
      return;
    }
    busyFlagSetter(true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      _saveBytesToBrowser(
        response.bodyBytes,
        filename,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = 'Download failed: '
            '${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) busyFlagSetter(false);
    }
  }

  void _saveBytesToBrowser(Uint8List bytes, String filename, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Future<({Uint8List bytes, String name})?> _pickSingle(String accept) async {
    final input = html.FileUploadInputElement()..accept = accept;
    input.click();
    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return null;
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = Uint8List.fromList(reader.result as List<int>);
    return (bytes: bytes, name: file.name);
  }

  Future<void> _pickXlsx() async {
    final picked = await _pickSingle('.xlsx');
    if (picked == null) return;
    setState(() {
      _xlsxBytes = picked.bytes;
      _xlsxName = picked.name;
      _error = null;
      _result = null;
    });
  }

  Future<void> _pickZip() async {
    final picked = await _pickSingle('.zip');
    if (picked == null) return;
    setState(() {
      _zipBytes = picked.bytes;
      _zipName = picked.name;
      _error = null;
      _result = null;
    });
  }

  Future<void> _runImport() async {
    if (_xlsxBytes == null || _xlsxName == null) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _error = 'Not signed in');
      return;
    }

    setState(() {
      _busy = true;
      _phaseLabel = 'Validating $_xlsxName...';
      _result = null;
      _error = null;
    });

    try {
      final preview = await widget.importFn(
        token: token,
        xlsxBytes: _xlsxBytes!,
        xlsxFilename: _xlsxName!,
        zipBytes: _zipBytes,
        zipFilename: _zipName,
        dryRun: true,
      );
      if (!mounted) return;
      if (preview.errors.isNotEmpty) {
        setState(() {
          _busy = false;
          _phaseLabel = '';
          _result = preview;
          _error = 'Fix the rows below and re-upload.';
        });
        return;
      }

      setState(() {
        _phaseLabel = 'Importing ${preview.total} rows '
            '(image uploads can take ~1s each)...';
      });

      final imported = await widget.importFn(
        token: token,
        xlsxBytes: _xlsxBytes!,
        xlsxFilename: _xlsxName!,
        zipBytes: _zipBytes,
        zipFilename: _zipName,
        dryRun: false,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _phaseLabel = '';
        _result = imported;
      });
      if (imported.created > 0) widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _phaseLabel = '';
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.instructions,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || _downloadingTemplate
                          ? null
                          : _downloadTemplate,
                      icon: _downloadingTemplate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.document_download, size: 18),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Download Template'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || _exportingCatalog
                          ? null
                          : _exportCurrent,
                      icon: _exportingCatalog
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Iconsax.export_1, size: 18),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(widget.exportButtonLabel),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _BulkFileSlot(
                label: 'Template (.xlsx)',
                required: true,
                fileName: _xlsxName,
                disabled: _busy,
                onPick: _pickXlsx,
                onClear: () => setState(() {
                  _xlsxBytes = null;
                  _xlsxName = null;
                  _result = null;
                }),
              ),
              const SizedBox(height: 8),
              _BulkFileSlot(
                label: 'Images (.zip)',
                required: false,
                fileName: _zipName,
                disabled: _busy,
                onPick: _pickZip,
                onClear: () => setState(() {
                  _zipBytes = null;
                  _zipName = null;
                  _result = null;
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    _busy || _xlsxBytes == null ? null : _runImport,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.document_upload, size: 18),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_busy ? 'Working...' : 'Import'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                Text(
                  _phaseLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _result!.errors.isEmpty
                        ? AppColors.cardGreen
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.errors.isEmpty
                            ? 'Imported ${_result!.created} of ${_result!.total} rows'
                            : 'Found ${_result!.errors.length} error(s) '
                                'in ${_result!.total} rows',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (_result!.rowsRequestingImage > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Images: ${_result!.imagesAttached} '
                          'of ${_result!.rowsRequestingImage} attached'
                          '${!_result!.zipProvided ? "  (no .zip uploaded)" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (_result!.rowsRequestingImage == 0 &&
                          _result!.created > 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'No image_filename or image_url values were '
                            'set on any row, so no images were attached.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (_result!.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._result!.errors.take(20).map(
                              (e) => Text(
                                'Row ${e.row}: ${e.error}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        if (_result!.errors.length > 20)
                          Text(
                            '...and ${_result!.errors.length - 20} more',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                      if (_result!.unusedZipFiles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Images in zip not referenced by any row: '
                          '${_result!.unusedZipFiles.join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _BulkFileSlot extends StatelessWidget {
  final String label;
  final bool required;
  final String? fileName;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _BulkFileSlot({
    required this.label,
    required this.required,
    required this.fileName,
    required this.disabled,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(10),
        color: hasFile ? AppColors.cardGreen : AppColors.grey50,
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Iconsax.tick_circle : Iconsax.document_upload,
            size: 18,
            color: hasFile ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label + (required ? ' *' : ' (optional)'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName ?? 'No file selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasFile
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              tooltip: 'Remove',
              onPressed: disabled ? null : onClear,
              icon: const Icon(Iconsax.close_circle, size: 18),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          TextButton.icon(
            onPressed: disabled ? null : onPick,
            icon: const Icon(Iconsax.folder_open, size: 16),
            label: Text(hasFile ? 'Replace' : 'Pick'),
          ),
        ],
      ),
    );
  }
}
