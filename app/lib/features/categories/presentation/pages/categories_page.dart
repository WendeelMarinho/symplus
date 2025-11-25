import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/widgets/action_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/widgets/list_item_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/rbac/permission_helper.dart';
import '../../../../core/rbac/permissions_catalog.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_borders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/category_service.dart';
import '../../data/models/category.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String? _filterType; // 'income' or 'expense' or null for all
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['action'] == 'create' && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCreateDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await CategoryService.list(
        type: _filterType,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: _currentPage,
        perPage: 15,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final categoriesData = data['data'] as List<dynamic>;
        final meta = data['meta'] ?? {};

        setState(() {
          if (_currentPage == 1) {
            _categories = categoriesData.map((json) => Category.fromJson(json)).toList();
          } else {
            _categories.addAll(
              categoriesData.map((json) => Category.fromJson(json)).toList(),
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

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'expense');
    final colorController = TextEditingController(text: '#3B82F6');
    final formKey = GlobalKey<FormState>();
    final List<String> presetColors = [
      '#3B82F6', // Blue
      '#10B981', // Green
      '#EF4444', // Red
      '#F59E0B', // Amber
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#06B6D4', // Cyan
      '#84CC16', // Lime
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.category,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova Categoria',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Crie uma categoria personalizada',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                nameController.dispose();
                                typeController.dispose();
                                colorController.dispose();
                              });
                            },
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Conteúdo com scroll
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview de cor/ícone
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _parseColor(colorController.text).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _parseColor(colorController.text),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _parseColor(colorController.text).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _parseColor(colorController.text),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: _parseColor(colorController.text),
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    nameController.text.isEmpty ? 'Preview' : nameController.text,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome da Categoria *',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.label, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                              autofocus: true,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: typeController.text,
                              decoration: InputDecoration(
                                labelText: 'Tipo *',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.swap_horiz, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              items: const [
                                DropdownMenuItem(value: 'income', child: Text('Receita')),
                                DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  typeController.text = value;
                                  setDialogState(() {});
                                }
                              },
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                            ),
                            const SizedBox(height: 20),
                            // Seletor de cores
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cor',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: presetColors.map((color) {
                                    final isSelected = colorController.text == color;
                                    return GestureDetector(
                                      onTap: () {
                                        colorController.text = color;
                                        setDialogState(() {});
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _parseColor(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            width: isSelected ? 3 : 0,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: _parseColor(color).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: colorController,
                                  decoration: InputDecoration(
                                    labelText: 'Cor (hex)',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    prefixIcon: Icon(Icons.palette, color: AppColors.primary),
                                    helperText: 'Ex: #3B82F6',
                                    helperStyle: AppTypography.caption,
                                  ),
                                  style: AppTypography.bodyMedium,
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botões
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                nameController.dispose();
                                typeController.dispose();
                                colorController.dispose();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Cancelar',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final name = nameController.text;
                                final type = typeController.text;
                                final color = colorController.text.isNotEmpty ? colorController.text : null;
                                
                                Navigator.of(context).pop();
                                Future.microtask(() {
                                  nameController.dispose();
                                  typeController.dispose();
                                  colorController.dispose();
                                });
                                await _createCategory(name, type, color);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Criar',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createCategory(String name, String type, String? color) async {
    try {
      await CategoryService.create(
        type: type,
        name: name,
        color: color,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Categoria criada com sucesso!');
        setState(() {
          _currentPage = 1;
        });
        _loadCategories();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao criar categoria',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao criar categoria: ${e.toString()}');
      }
    }
  }

  void _showEditDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    final typeController = TextEditingController(text: category.type);
    final colorController = TextEditingController(text: category.color);
    final formKey = GlobalKey<FormState>();
    final List<String> presetColors = [
      '#3B82F6', // Blue
      '#10B981', // Green
      '#EF4444', // Red
      '#F59E0B', // Amber
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#06B6D4', // Cyan
      '#84CC16', // Lime
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editar Categoria',
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Atualize os dados da categoria',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                nameController.dispose();
                                typeController.dispose();
                                colorController.dispose();
                              });
                            },
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Conteúdo com scroll
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Preview de cor/ícone
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _parseColor(colorController.text).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _parseColor(colorController.text),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _parseColor(colorController.text).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _parseColor(colorController.text),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: _parseColor(colorController.text),
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    nameController.text,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome da Categoria *',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.label, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                              autofocus: true,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: typeController.text,
                              decoration: InputDecoration(
                                labelText: 'Tipo *',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                                ),
                                prefixIcon: Icon(Icons.swap_horiz, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              items: const [
                                DropdownMenuItem(value: 'income', child: Text('Receita')),
                                DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  typeController.text = value;
                                  setDialogState(() {});
                                }
                              },
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                            ),
                            const SizedBox(height: 20),
                            // Seletor de cores
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cor',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: presetColors.map((color) {
                                    final isSelected = colorController.text == color;
                                    return GestureDetector(
                                      onTap: () {
                                        colorController.text = color;
                                        setDialogState(() {});
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _parseColor(color),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                            width: isSelected ? 3 : 0,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: _parseColor(color).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: colorController,
                                  decoration: InputDecoration(
                                    labelText: 'Cor (hex)',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    prefixIcon: Icon(Icons.palette, color: AppColors.primary),
                                    helperText: 'Ex: #3B82F6',
                                    helperStyle: AppTypography.caption,
                                  ),
                                  style: AppTypography.bodyMedium,
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botões
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                nameController.dispose();
                                typeController.dispose();
                                colorController.dispose();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              'Cancelar',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final name = nameController.text;
                                final type = typeController.text;
                                final color = colorController.text.isNotEmpty ? colorController.text : null;
                                
                                Navigator.of(context).pop();
                                Future.microtask(() {
                                  nameController.dispose();
                                  typeController.dispose();
                                  colorController.dispose();
                                });
                                await _updateCategory(category.id, name, type, color);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Salvar',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateCategory(int id, String name, String type, String? color) async {
    try {
      await CategoryService.update(
        id,
        name: name,
        type: type,
        color: color,
      );
      if (mounted) {
        ToastService.showSuccess(context, 'Categoria atualizada com sucesso!');
        _loadCategories();
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao atualizar categoria',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao atualizar categoria');
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Confirmar Exclusão',
      message: 'Deseja realmente excluir a categoria "${category.name}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      icon: Icons.delete,
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await CategoryService.delete(category.id);
        if (mounted) {
          ToastService.showSuccess(context, 'Categoria excluída com sucesso!');
          setState(() {
            _currentPage = 1;
          });
          _loadCategories();
        }
      } on DioException catch (e) {
        if (mounted) {
          final message = e.response?.data['message'] ?? 'Erro ao excluir categoria';
          if (e.response?.statusCode == 422) {
            ToastService.showError(context, message);
          } else {
            ToastService.showError(context, message);
          }
        }
      } catch (e) {
        if (mounted) {
          ToastService.showError(context, 'Erro ao excluir categoria');
        }
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }

  /// Grid de pills coloridas
  Widget _buildCategoriesGrid(BuildContext context, bool canEdit, bool canDelete) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 2 : (MediaQuery.of(context).size.width < 900 ? 3 : 4);
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _categories.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _categories.length) {
          return Card(
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadCategories(showLoading: false);
                },
                child: const Text('Carregar mais'),
              ),
            ),
          );
        }

        final category = _categories[index];
        final categoryColor = _parseColor(category.color);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: canEdit ? () => _showEditDialog(category) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone/Preview de cor
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: categoryColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.category,
                      color: categoryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nome
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tipo e contagem
                  Wrap(
                    spacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          category.isIncome ? 'Receita' : 'Despesa',
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: category.isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (category.transactionsCount != null && category.transactionsCount! > 0)
                        Chip(
                          label: Text(
                            '${category.transactionsCount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  // Menu de ações
                  if (canEdit || canDelete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'edit' && canEdit) {
                            _showEditDialog(category);
                          } else if (value == 'delete' && canDelete) {
                            _deleteCategory(category);
                          }
                        },
                        itemBuilder: (context) => [
                          if (canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canCreate = PermissionHelper.hasPermission(authState, Permission.categoriesCreate);
    final canEdit = PermissionHelper.hasPermission(authState, Permission.categoriesEdit);
    final canDelete = PermissionHelper.hasPermission(authState, Permission.categoriesDelete);

    final hasFilters = _filterType != null;

    return Column(
      children: [
        PageHeader(
          title: 'Categorias',
          subtitle: 'Organize suas transações por categorias personalizadas',
          breadcrumbs: const ['Financeiro', 'Categorias'],
          actions: [
            if (hasFilters)
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _currentPage = 1;
                  });
                  _loadCategories();
                },
                tooltip: 'Remover filtros',
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por tipo',
              onSelected: (value) {
                setState(() {
                  _filterType = value == 'all' ? null : value;
                  _currentPage = 1;
                });
                _loadCategories();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Todas')),
                const PopupMenuItem(value: 'income', child: Text('Receitas')),
                const PopupMenuItem(value: 'expense', child: Text('Despesas')),
              ],
            ),
          ],
        ),
        // Barra de busca
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar categorias...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentPage = 1;
                        });
                        _loadCategories();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  setState(() {
                    _currentPage = 1;
                  });
                  _loadCategories();
                }
              });
            },
          ),
        ),
        ActionBar(
          actions: [
            if (canCreate)
              ActionItem(
                label: 'Adicionar Categoria',
                icon: Icons.add_circle,
                onPressed: _showCreateDialog,
                type: ActionType.primary,
              ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const LoadingState(message: 'Carregando categorias...')
              : _error != null
                  ? ErrorState(
                      message: _error!,
                      onRetry: _loadCategories,
                    )
                  : _categories.isEmpty
                      ? EmptyState(
                          icon: Icons.category,
                          title: 'Nenhuma categoria encontrada',
                          message: _filterType != null || (_searchController.text.isNotEmpty)
                              ? 'Nenhuma categoria corresponde aos filtros aplicados.'
                              : 'Crie categorias para organizar suas receitas e despesas.',
                          actionLabel: 'Criar Categoria',
                          onAction: canCreate ? _showCreateDialog : null,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          child: _buildCategoriesGrid(context, canEdit, canDelete),
                        ),
        ),
      ],
    );
  }
}
