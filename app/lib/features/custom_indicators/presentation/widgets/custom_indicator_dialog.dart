import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/services/category_service.dart';
import '../../data/models/custom_indicator.dart';
import '../../../../core/widgets/toast_service.dart';

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
    return AlertDialog(
      title: Text(
        widget.indicator == null
            ? 'Criar Indicador Personalizado'
            : 'Editar Indicador',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo Nome
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Indicador',
                          hintText: 'Ex: Alimentação',
                          border: OutlineInputBorder(),
                        ),
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Lista de categorias (MultiSelect)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _allCategories.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text('Nenhuma categoria disponível'),
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
                                    title: Text(category.name),
                                    subtitle: Text(
                                      category.type == 'income'
                                          ? 'Receita'
                                          : 'Despesa',
                                      ),
                                    ),
                                    value: isSelected,
                                    onChanged: (_) => _toggleCategory(category.id),
                                    dense: true,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategoryIds.isEmpty
                                    ? 'Selecione categorias para ver o preview'
                                    : '${_selectedCategoryIds.length} ${_selectedCategoryIds.length == 1 ? 'categoria selecionada' : 'categorias selecionadas'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.indicator == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }
}

