import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

/// Widget para upload de documento em transações
class TransactionDocumentUpload extends StatefulWidget {
  final Function(PlatformFile?)? onFileSelected;
  final PlatformFile? initialFile;
  final bool required;

  const TransactionDocumentUpload({
    super.key,
    this.onFileSelected,
    this.initialFile,
    this.required = false,
  });

  @override
  State<TransactionDocumentUpload> createState() =>
      _TransactionDocumentUploadState();
}

class _TransactionDocumentUploadState
    extends State<TransactionDocumentUpload> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validar tamanho (5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Arquivo muito grande. Máximo: 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });

        widget.onFileSelected?.call(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar arquivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
    widget.onFileSelected?.call(null);
  }

  bool _isImage(String? extension) {
    return extension != null &&
        ['jpg', 'jpeg', 'png'].contains(extension.toLowerCase());
  }

  bool _isPdf(String? extension) {
    return extension != null && extension.toLowerCase() == 'pdf';
  }

  String _getFileExtension(String filename) {
    return filename.split('.').last;
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) return const SizedBox.shrink();

    final extension = _getFileExtension(_selectedFile!.name);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Preview ou ícone
          if (_isImage(extension) && _selectedFile!.bytes != null)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: MemoryImage(_selectedFile!.bytes!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _isPdf(extension) ? Icons.picture_as_pdf : Icons.image,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 32,
              ),
            ),
          const SizedBox(width: 12),
          // Nome do arquivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(_selectedFile!.size),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          // Botão remover
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _removeFile,
            tooltip: 'Remover arquivo',
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              'Documento ${widget.required ? '*' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (widget.required)
              Text(
                ' (obrigatório)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Botão de upload ou área de drag-and-drop
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedFile == null && widget.required
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: _selectedFile == null && widget.required ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedFile == null
                      ? 'Selecionar arquivo (PNG, JPG, PDF)'
                      : 'Trocar arquivo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
        // Preview do arquivo
        _buildFilePreview(),
        // Ajuda
        if (_selectedFile == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Formatos aceitos: PNG, JPG, PDF. Tamanho máximo: 5MB',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
      ],
    );
  }
}

