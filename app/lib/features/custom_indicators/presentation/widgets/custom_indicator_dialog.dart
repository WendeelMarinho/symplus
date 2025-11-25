import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/services/category_service.dart';
import '../../data/models/custom_indicator.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/design/app_spacing.dart';

/// Dialog para criar ou editar um indicador personalizado
class CustomIndicatorDialog extends ConsumerStatefulWidget {
  final CustomIndicator? indicator; // null = criar, não-null = editar

  const CustomIndicatorDialog({
    super.key,
    this.indicator,
  });

  @override
  ConsumerState<CustomIndicatorDialog> createState() =>
      _CustomIndicatorDialogState();
}

class _CustomIndicatorDialogState
    extends ConsumerState<CustomIndicatorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<Category> _allCategories = [];
  List<int> _selectedCategoryIds = [];
  bool _isLoading = true;
  double _previewTotal = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.indicator != null) {
      _nameController.text = widget.indicator!.name;
      _selectedCategoryIds = List.from(widget.indicator!.categoryIds);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar apenas categorias de despesas (expense)
      final response = await CategoryService.list(type: 'expense');
      if (response.statusCode == 200) {
        final data = response.data;
        final categoriesData = data['data'] as List<dynamic>;
        setState(() {
          _allCategories =
              categoriesData.map((json) => Category.fromJson(json)).toList();
          _isLoading = false;
        });
        _updatePreview();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastService.showError(context, 'Erro ao carregar categorias');
      }
    }
  }

  void _updatePreview() {
    // Preview será calculado quando o backend estiver pronto
    // Por enquanto, apenas mostra quantas categorias foram selecionadas
    setState(() {
      _previewTotal = _selectedCategoryIds.length.toDouble();
    });
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
      _updatePreview();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      ToastService.showWarning(
        context,
        'Selecione pelo menos uma categoria',
      );
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'categoryIds': _selectedCategoryIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                        Icons.analytics,
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
                            widget.indicator == null
                                ? 'Criar Indicador Personalizado'
                                : 'Editar Indicador',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecione as categorias para o indicador',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Conteúdo com scroll
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo Nome
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nome do Indicador *',
                                  hintText: 'Ex: Alimentação',
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'O nome é obrigatório';
                                  }
                                  return null;
                                },
                                autofocus: true,
                              ),
                              const SizedBox(height: 24),
                              // Título de categorias
                              Text(
                                'Selecione as Categorias',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Lista de categorias (MultiSelect)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 300),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _allCategories.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Text(
                                            'Nenhuma categoria disponível',
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _allCategories.length,
                                        itemBuilder: (context, index) {
                                          final category = _allCategories[index];
                                          final isSelected =
                                              _selectedCategoryIds.contains(category.id);

                                          return CheckboxListTile(
                                            value: isSelected,
                                            onChanged: (_) => _toggleCategory(category.id),
                                            title: Text(
                                              category.name,
                                              style: AppTypography.bodyMedium,
                                            ),
                                            subtitle: Text(
                                              category.type == 'income'
                                                  ? 'Receita'
                                                  : 'Despesa',
                                              style: AppTypography.caption,
                                            ),
                                            dense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 16),
                              // Preview
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.info.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedCategoryIds.isEmpty
                                            ? 'Selecione categorias para ver o preview'
                                            : '${_selectedCategoryIds.length} ${_selectedCategoryIds.length == 1 ? 'categoria selecionada' : 'categorias selecionadas'}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w500,
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
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.indicator == null ? 'Criar' : 'Salvar',
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
    );
  }
}

