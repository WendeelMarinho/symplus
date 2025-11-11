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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: typeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Receita')),
                    DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      typeController.text = value;
                    }
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Cor (hex)',
                    border: OutlineInputBorder(),
                    helperText: 'Ex: #3B82F6',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Dispose controllers após fechar o diálogo
              Future.microtask(() {
                nameController.dispose();
                typeController.dispose();
                colorController.dispose();
              });
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Salvar valores antes de fechar
                final name = nameController.text;
                final type = typeController.text;
                final color = colorController.text.isNotEmpty ? colorController.text : null;
                
                // Fechar diálogo primeiro
                Navigator.of(context).pop();
                // Dispose controllers após fechar
                Future.microtask(() {
                  nameController.dispose();
                  typeController.dispose();
                  colorController.dispose();
                });
                // Criar categoria com valores salvos
                await _createCategory(name, type, color);
              }
            },
            child: const Text('Criar'),
          ),
        ],
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoria'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Categoria *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Nome é obrigatório' : null,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: typeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Receita')),
                    DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      typeController.text = value;
                    }
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Tipo é obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Cor (hex)',
                    border: OutlineInputBorder(),
                    helperText: 'Ex: #3B82F6',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Dispose controllers após fechar o diálogo
              Future.microtask(() {
                nameController.dispose();
                typeController.dispose();
                colorController.dispose();
              });
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Salvar valores antes de fechar
                final name = nameController.text;
                final type = typeController.text;
                final color = colorController.text.isNotEmpty ? colorController.text : null;
                
                // Fechar diálogo primeiro
                Navigator.of(context).pop();
                // Dispose controllers após fechar
                Future.microtask(() {
                  nameController.dispose();
                  typeController.dispose();
                  colorController.dispose();
                });
                // Atualizar categoria com valores salvos
                await _updateCategory(category.id, name, type, color);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
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
        ActionBar(
          actions: [
            if (canCreate)
              ActionItem(
                label: 'Nova Categoria',
                icon: Icons.add,
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
                          message: _filterType != null
                              ? 'Nenhuma categoria do tipo selecionado foi encontrada.'
                              : 'Crie categorias para organizar suas receitas e despesas.',
                          actionLabel: 'Criar Categoria',
                          onAction: canCreate ? _showCreateDialog : null,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          child: ListView.builder(
                            itemCount: _categories.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _categories.length) {
                                // Load more button
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                              return ListItemCard(
                                title: category.name,
                                subtitle: '${category.isIncome ? "Receita" : "Despesa"} • ${category.transactionsCount ?? 0} transações',
                                leadingIcon: Icons.category,
                                leadingColor: _parseColor(category.color),
                                trailing: category.isIncome
                                    ? const Icon(Icons.trending_up, color: Colors.green, size: 20)
                                    : const Icon(Icons.trending_down, color: Colors.red, size: 20),
                                onTap: null, // Categories don't have detail pages
                                actions: [
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEditDialog(category),
                                      tooltip: 'Editar',
                                    ),
                                  if (canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteCategory(category),
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
}
