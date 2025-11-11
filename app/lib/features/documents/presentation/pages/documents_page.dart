import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/action_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../data/services/document_service.dart';
import '../../data/models/document.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  List<Document> _documents = [];
  bool _isLoading = true;
  String? _error;
  String? _filterCategory;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['action'] == 'upload' && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickAndUploadFiles();
        }
      });
    }
  }

  Future<void> _loadDocuments({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await DocumentService.list(
        category: _filterCategory,
        page: _currentPage,
        perPage: 15,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final documentsData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _documents = documentsData
                .map((json) => Document.fromJson(json))
                .toList();
          } else {
            _documents.addAll(
              documentsData.map((json) => Document.fromJson(json)).toList(),
            );
          }
          _totalPages = meta['last_page'] ?? 1;
          _hasMore = _currentPage < (_totalPages);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          await _uploadFile(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao selecionar arquivo: ${e.toString()}');
      }
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    if (file.size > 10 * 1024 * 1024) {
      // 10MB
      ToastService.showError(context, 'Arquivo muito grande. Máximo: 10MB');
      return;
    }

    final nameController = TextEditingController(text: file.name);
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController(text: 'other');
    final formKey = GlobalKey<FormState>();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload de Documento'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Arquivo: ${file.name} (${_formatBytes(file.size)})',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'other', child: Text('Outro')),
                    DropdownMenuItem(value: 'invoice', child: Text('Nota Fiscal')),
                    DropdownMenuItem(value: 'receipt', child: Text('Recibo')),
                    DropdownMenuItem(value: 'contract', child: Text('Contrato')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      categoryController.text = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              descriptionController.dispose();
              categoryController.dispose();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        await DocumentService.upload(
          file: file,
          name: nameController.text,
          description: descriptionController.text.isNotEmpty
              ? descriptionController.text
              : null,
          category: categoryController.text,
          onSendProgress: (sent, total) {
            setState(() {
              _uploadProgress = sent / total;
            });
          },
        );

        if (mounted) {
          ToastService.showSuccess(context, 'Documento enviado com sucesso!');
          setState(() {
            _currentPage = 1;
            _isUploading = false;
            _uploadProgress = 0.0;
          });
          _loadDocuments();
        }
      } on DioException catch (e) {
        if (mounted) {
          ToastService.showError(
            context,
            e.response?.data['message'] ?? 'Erro ao fazer upload',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao fazer upload: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
        }
      }

      nameController.dispose();
      descriptionController.dispose();
      categoryController.dispose();
    }
  }

  Future<void> _downloadDocument(Document document) async {
    try {
      // Obter URL temporária
      final urlResponse = await DocumentService.getUrl(document.id);
      if (urlResponse.statusCode == 200) {
        final url = urlResponse.data['url'] as String;
        // Abrir URL no navegador (para web)
        if (mounted) {
          // Para web, usar url_launcher seria ideal, mas por enquanto apenas mostrar a URL
          ToastService.showInfo(context, 'URL de download obtida. Implementar download direto em breve.');
          // TODO: Implementar download direto com url_launcher ou similar
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao fazer download');
      }
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir o documento "${document.name}"?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await DocumentService.delete(document.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Documento excluído!');
          setState(() {
            _currentPage = 1;
          });
          _loadDocuments();
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir documento');
        }
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canEdit = authState.role == 'owner' || authState.role == 'admin';

    final hasFilters = _filterCategory != null;

    return Column(
      children: [
        PageHeader(
          title: 'Documentos',
          subtitle: 'Armazene e organize seus documentos financeiros',
          breadcrumbs: const ['Vault', 'Documentos'],
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  setState(() {
                    _filterCategory = null;
                    _currentPage = 1;
                  });
                  _loadDocuments();
                },
                tooltip: 'Remover filtros',
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por categoria',
              onSelected: (value) {
                setState(() {
                  _filterCategory = value == 'all' ? null : value;
                  _currentPage = 1;
                });
                _loadDocuments();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Todas')),
                const PopupMenuItem(value: 'invoice', child: Text('Notas Fiscais')),
                const PopupMenuItem(value: 'receipt', child: Text('Recibos')),
                const PopupMenuItem(value: 'contract', child: Text('Contratos')),
                const PopupMenuItem(value: 'other', child: Text('Outros')),
              ],
            ),
          ],
        ),
        ActionBar(
          actions: [
            if (canEdit)
              ActionItem(
                label: 'Upload',
                icon: Icons.upload,
                onPressed: _isUploading ? null : _pickAndUploadFiles,
                type: ActionType.primary,
              ),
          ],
        ),
        if (_isUploading)
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando documentos...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadDocuments,
                    )
                  : _documents.isEmpty
                      ? EmptyState(
                          icon: Icons.folder,
                          title: 'Nenhum documento encontrado',
                          message: 'Faça upload de seus documentos para mantê-los organizados e acessíveis.',
                          actionLabel: 'Upload de Documento',
                          onAction: canEdit ? _pickAndUploadFiles : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadDocuments();
                          },
                          child: ListView.builder(
                            itemCount: _documents.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _documents.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _loadDocuments(showLoading: false);
                                      },
                                      child: const Text('Carregar mais'),
                                    ),
                                  ),
                                );
                              }

                              final document = _documents[index];
                              return ListItemCard(
                                title: document.name,
                                subtitle:
                                    '${document.sizeHuman} • ${document.category != null ? _formatCategory(document.category!) : "Sem categoria"} • ${DateFormat('dd/MM/yyyy').format(document.createdAt)}',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      document.icon,
                                      color: document.color,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    if (canEdit)
                                      IconButton(
                                        icon: const Icon(Icons.download, size: 20),
                                        onPressed: () => _downloadDocument(document),
                                        tooltip: 'Download',
                                      ),
                                  ],
                                ),
                                leadingIcon: document.icon,
                                leadingColor: document.color,
                                onTap: () => _downloadDocument(document),
                                actions: [
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteDocument(document),
                                      tooltip: 'Excluir',
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'invoice':
        return 'Nota Fiscal';
      case 'receipt':
        return 'Recibo';
      case 'contract':
        return 'Contrato';
      case 'other':
        return 'Outro';
      default:
        return category;
    }
  }
}
