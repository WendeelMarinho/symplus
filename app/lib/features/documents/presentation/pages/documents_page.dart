import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import '../../data/services/document_service.dart';
import '../../data/models/document.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> with SingleTickerProviderStateMixin {
  List<Document> _documents = [];
  bool _isLoading = true;
  String? _error;
  String? _filterCategory;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  late TabController _tabController;
  int _selectedTab = 0; // 0: All, 1: By Tag, 2: Recent

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _currentPage = 1;
        });
        _loadDocuments();
      }
    });
    _loadDocuments();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text.isEmpty ? null : _searchController.text;
          _currentPage = 1;
        });
        _loadDocuments();
      }
    });
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
      // Aplicar filtros baseados na aba selecionada
      String? category;
      String? documentableType;
      bool recent = false;
      
      if (_selectedTab == 1) {
        // By Tag - usar _filterCategory se definido
        category = _filterCategory;
      } else if (_selectedTab == 2) {
        // Recent - últimos 30 dias
        recent = true;
      }
      
      final response = await DocumentService.list(
        category: category,
        page: _currentPage,
        perPage: 15,
        search: _searchQuery,
      );
      
      List<Document> documents = (response.data['data'] as List<dynamic>)
          .map((json) => Document.fromJson(json))
          .toList();
      
      // Filtrar recentes se necessário
      if (recent) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        documents = documents.where((doc) => doc.createdAt.isAfter(thirtyDaysAgo)).toList();
      }

      if (response.statusCode == 200) {
        final data = response.data;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _documents = documents;
          } else {
            _documents.addAll(documents);
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
    // Mostrar bottom sheet com opções
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Adicionar Documento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('Selecionar Arquivo'),
              onTap: () {
                Navigator.pop(context);
                _pickFiles();
              },
            ),
            // Para web, não mostrar opção de câmera
            // Em mobile, poderia ter: ListTile com Icons.camera
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
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

  Future<void> _copyTemporaryUrl(Document document) async {
    try {
      final urlResponse = await DocumentService.getUrl(document.id);
      if (urlResponse.statusCode == 200) {
        final url = urlResponse.data['url'] as String;
        // Copiar para clipboard (web)
        // Em Flutter web, podemos usar Clipboard.setData
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ToastService.showSuccess(context, 'URL copiada para a área de transferência!');
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao copiar URL');
      }
    }
  }

  Future<void> _downloadDocument(Document document) async {
    try {
      // Obter URL temporária e abrir no navegador
      final urlResponse = await DocumentService.getUrl(document.id);
      if (urlResponse.statusCode == 200) {
        final url = urlResponse.data['url'] as String;
        // Para web, abrir URL em nova aba
        // html.window.open(url, '_blank'); // Seria necessário import 'dart:html' mas não funciona em todos os contextos
        // Por enquanto, copiar URL
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ToastService.showInfo(context, 'URL copiada. Abra em nova aba para fazer download.');
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
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filterCategory = null;
                    _currentPage = 1;
                  });
                  _loadDocuments();
                },
                tooltip: 'Remover filtros',
                color: AppColors.textSecondary,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por categoria',
              color: AppColors.textSecondary,
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
        // Barra de busca
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding(context).horizontal,
            vertical: AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar documentos por nome ou tipo...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = null;
                          _currentPage = 1;
                        });
                        _loadDocuments();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorders.inputRadius),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ),
        // Abas modernizadas
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding(context).horizontal,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppBorders.smallRadius),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppBorders.smallRadius),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Todos', icon: Icon(Icons.folder, size: 18)),
              Tab(text: 'Por Tag', icon: Icon(Icons.label, size: 18)),
              Tab(text: 'Recentes', icon: Icon(Icons.access_time, size: 18)),
            ],
          ),
        ),
        ActionBar(
          actions: [
            if (canEdit)
              ActionItem(
                label: 'Adicionar Documento',
                icon: Icons.add_circle,
                onPressed: _isUploading ? null : _pickAndUploadFiles,
                type: ActionType.primary,
              ),
          ],
        ),
        if (_isUploading)
          Container(
            padding: EdgeInsets.all(AppSpacing.pagePadding(context).horizontal),
            child: AccessibleCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.backgroundLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enviando... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
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
                          message: (_searchQuery != null || _filterCategory != null)
                              ? 'Nenhum documento corresponde aos filtros aplicados.'
                              : 'Faça upload de seus documentos para mantê-los organizados e acessíveis.',
                          actionLabel: 'Adicionar Documento',
                          onAction: canEdit ? _pickAndUploadFiles : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () {
                            setState(() {
                              _currentPage = 1;
                            });
                            return _loadDocuments();
                          },
                          child: CustomScrollView(
                            slivers: [
                              // Card de upload (se não houver documentos ou no final)
                              if (_documents.isEmpty && canEdit)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.pagePadding(context).horizontal),
                                    child: _buildUploadCard(),
                                  ),
                                ),
                              // Lista de documentos
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.pagePadding(context).horizontal,
                                  vertical: AppSpacing.md,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (index == _documents.length) {
                                        return Column(
                                          children: [
                                            if (canEdit) ...[
                                              const SizedBox(height: AppSpacing.md),
                                              _buildUploadCard(),
                                            ],
                                            if (_hasMore) ...[
                                              const SizedBox(height: AppSpacing.md),
                                              Center(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _currentPage++;
                                                    });
                                                    _loadDocuments(showLoading: false);
                                                  },
                                                  icon: const Icon(Icons.expand_more),
                                                  label: Text(
                                                    'Carregar mais',
                                                    style: AppTypography.label,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      }

                                      final document = _documents[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: _buildDocumentCard(context, document, canEdit),
                                      );
                                    },
                                    childCount: _documents.length + (_hasMore || canEdit ? 1 : 0),
                                  ),
                                ),
                              ),
                            ],
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

  /// Card de upload de documento
  Widget _buildUploadCard() {
    return AccessibleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: _isUploading ? null : _pickAndUploadFiles,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorders.cardRadius),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isUploading ? 'Enviando documento...' : 'Fazer Upload de Documento',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Clique para selecionar e enviar arquivos',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, Document document, bool canEdit) {
    return AccessibleCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorders.cardRadius),
          onTap: () => _downloadDocument(document),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Ícone do documento
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: document.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                  ),
                  child: Icon(
                    document.icon,
                    color: document.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: AppTypography.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs / 2,
                        children: [
                          if (document.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(AppBorders.smallRadius),
                              ),
                              child: Text(
                                _formatCategory(document.category!),
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Text(
                            document.sizeHuman,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(document.createdAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu de ações
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                  tooltip: 'Ações',
                  onSelected: (value) {
                    switch (value) {
                      case 'copy_url':
                        _copyTemporaryUrl(document);
                        break;
                      case 'download':
                        _downloadDocument(document);
                        break;
                      case 'delete':
                        if (canEdit) {
                          _deleteDocument(document);
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy_url',
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Copiar URL temporária', style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          const Icon(Icons.download, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Download', style: AppTypography.bodyMedium),
                        ],
                      ),
                    ),
                    if (canEdit) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: AppColors.error),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Excluir',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
