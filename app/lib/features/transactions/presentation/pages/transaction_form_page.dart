import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/toast_service.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/accessibility/responsive_utils.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_borders.dart';
import '../../../../core/accessibility/accessible_widgets.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction.dart';
import '../../../accounts/data/services/account_service.dart';
import '../../../accounts/data/models/account.dart';
import '../../../categories/data/services/category_service.dart';
import '../../../categories/data/models/category.dart';
import '../../../documents/data/services/document_service.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/transaction_document_upload.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final Transaction? transaction; // null = criar, não-null = editar
  final int? transactionId; // ID para carregar transação em modo edição

  const TransactionFormPage({
    super.key,
    this.transaction,
    this.transactionId,
  });

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'expense';
  DateTime? _selectedDate;
  int? _selectedAccountId;
  int? _selectedCategoryId;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  bool _isRecurring = false;

  List<Account> _accounts = [];
  List<Category> _categories = [];
  bool _isLoadingData = true;

  Transaction? _loadedTransaction;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.transaction != null) {
      // Modo edição - transação já fornecida
      _descriptionController.text = widget.transaction!.description;
      _amountController.text = widget.transaction!.amount.toString();
      _type = widget.transaction!.type;
      _selectedDate = widget.transaction!.occurredAt;
      _selectedAccountId = widget.transaction!.accountId;
      _selectedCategoryId = widget.transaction!.categoryId;
      _loadedTransaction = widget.transaction;
    } else if (widget.transactionId != null) {
      // Modo edição - precisa carregar transação
      _loadTransaction();
    } else {
      // Modo criação
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final response = await TransactionService.get(widget.transactionId!);
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final transaction = Transaction.fromJson(data);
        if (mounted) {
          setState(() {
            _loadedTransaction = transaction;
            _descriptionController.text = transaction.description;
            _amountController.text = transaction.amount.toString();
            _type = transaction.type;
            _selectedDate = transaction.occurredAt;
            _selectedAccountId = transaction.accountId;
            _selectedCategoryId = transaction.categoryId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao carregar transação');
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final accountsResponse = await AccountService.list();
      final categoriesResponse = await CategoryService.list();

      if (accountsResponse.statusCode == 200) {
        final accountsData = accountsResponse.data['data'] as List<dynamic>;
        _accounts = accountsData.map((json) => Account.fromJson(json)).toList();
      }

      if (categoriesResponse.statusCode == 200) {
        final categoriesData = categoriesResponse.data['data'] as List<dynamic>;
        _categories = categoriesData.map((json) => Category.fromJson(json)).toList();
      }
    } catch (e) {
      // Silently fail
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  bool get _isIncome => _type == 'income';
  Color get _headerColor => _isIncome ? AppColors.income : AppColors.expense;

  String _formatCurrency(double value) {
    final currencyState = ref.read(currencyProvider);
    return CurrencyFormatter.format(value, currencyState);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DateTime? _getDateForChip(String chipType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (chipType) {
      case 'today':
        return today;
      case 'yesterday':
        return today.subtract(const Duration(days: 1));
      default:
        return null;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountId == null) {
      ToastService.showError(context, 'Selecione uma conta');
      return;
    }

    if (_selectedDate == null) {
      ToastService.showError(context, 'Selecione uma data');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final description = _descriptionController.text.trim();

      final transactionToUpdate = _loadedTransaction ?? widget.transaction;
      if (transactionToUpdate != null) {
        // Editar
        await TransactionService.update(
          transactionToUpdate.id,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
          type: _type,
          amount: amount,
          occurredAt: _selectedDate!,
          description: description,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Transação atualizada com sucesso!');
          Navigator.of(context).pop(true);
        }
      } else {
        // Criar
        String? documentPath;
        int? documentId;

        if (_selectedFile != null) {
          try {
            final uploadResponse = await DocumentService.upload(
              file: _selectedFile!,
              name: _selectedFile!.name,
              description: 'Documento da transação: $description',
              category: 'transaction',
              documentableType: 'transaction',
            );

            if (uploadResponse.statusCode == 201) {
              final documentData = uploadResponse.data['data'] as Map<String, dynamic>;
              documentPath = documentData['path'] as String?;
              documentId = documentData['id'] as int;
            }
          } catch (e) {
            // Se o upload falhar, continuar sem anexo
            if (mounted) {
              ToastService.showWarning(
                context,
                'Aviso: Não foi possível fazer upload do anexo. A transação será criada sem anexo.',
              );
            }
          }
        }

        final transactionResponse = await TransactionService.create(
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
          type: _type,
          amount: amount,
          occurredAt: _selectedDate!,
          description: description,
          attachmentPath: documentPath, // Pode ser null se não houver arquivo
        );

        if (_selectedFile != null && documentId != null && transactionResponse.statusCode == 201) {
          final transactionData = transactionResponse.data['data'] as Map<String, dynamic>;
          final transactionId = transactionData['id'] as int;
          await DocumentService.update(
            documentId,
            description: 'Documento da transação #$transactionId: $description',
          );
        }

        if (mounted) {
          ToastService.showSuccess(context, 'Transação criada com sucesso!');
          Navigator.of(context).pop(true);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ToastService.showError(
          context,
          e.response?.data['message'] ?? 'Erro ao salvar transação',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Erro ao salvar transação: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se está carregando dados iniciais ou transação para edição
    if (_isLoadingData || (widget.transactionId != null && _loadedTransaction == null)) {
      return Container(
        constraints: const BoxConstraints(minHeight: 400),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header colorido
          _buildHeader(),
          // Conteúdo
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        padding: AppSpacing.pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: AppSpacing.lg),
                            // Campo de valor em destaque
                            _buildAmountField(),
                            SizedBox(height: AppSpacing.xl),
                            // Chips de data
                            _buildDateChips(),
                            SizedBox(height: AppSpacing.lg),
                            // Campos Material 3
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Descrição *',
                                hintText: 'Digite a descrição',
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
                                prefixIcon: Icon(Icons.description, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Descrição é obrigatória' : null,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Categoria',
                                hintText: 'Selecione uma categoria',
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
                                prefixIcon: Icon(Icons.category, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              items: [
                                DropdownMenuItem<int>(
                                  value: null,
                                  child: Text(
                                    'Sem categoria',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ..._categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<int>(
                              value: _selectedAccountId,
                              decoration: InputDecoration(
                                labelText: 'Conta *',
                                hintText: 'Selecione uma conta',
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
                                prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                              ),
                              style: AppTypography.bodyMedium,
                              items: _accounts.map((account) {
                                return DropdownMenuItem(
                                  value: account.id,
                                  child: Text(account.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccountId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Conta é obrigatória' : null,
                            ),
                            const SizedBox(height: 20),
                            // Anexo
                            TransactionDocumentUpload(
                              required: false,
                              onFileSelected: (file) {
                                setState(() {
                                  _selectedFile = file;
                                });
                              },
                            ),
                            Divider(height: AppSpacing.xl),
                            // Recorrente
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recorrente',
                                  style: AppTypography.bodyLarge,
                                ),
                                Switch(
                                  value: _isRecurring,
                                  onChanged: (value) {
                                    setState(() {
                                      _isRecurring = value;
                                    });
                                  },
                                  activeColor: _headerColor,
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
                    // Botão Salvar fixo
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _headerColor,
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _type == 'income' ? Icons.trending_up : Icons.trending_down,
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
                  widget.transaction != null ? 'Editar Transação' : 'Nova Transação',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                // Toggle Receita/Despesa
                Row(
                  children: [
                    _buildTypeToggle('income', 'Receita'),
                    const SizedBox(width: 8),
                    _buildTypeToggle('expense', 'Despesa'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cancelar',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(String type, String label) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? _headerColor : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    final currencyState = ref.watch(currencyProvider);
    final currencySymbol = currencyState.symbol;

    return TextFormField(
      controller: _amountController,
      style: AppTypography.headlineLarge.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Valor *',
        hintText: '0,00',
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
        prefixText: '$currencySymbol ',
        prefixStyle: AppTypography.headlineLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: AppTypography.headlineLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Valor é obrigatório';
        }
        final amount = double.tryParse(value.replaceAll(',', '.'));
        if (amount == null || amount <= 0) {
          return 'Valor deve ser maior que zero';
        }
        return null;
      },
    );
  }

  Widget _buildDateChips() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDateOnly = _selectedDate != null
        ? DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
        : null;

    final isToday = selectedDateOnly == today;
    final isYesterday = selectedDateOnly == yesterday;
    final isOther = !isToday && !isYesterday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data *',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildDateChip(
              label: 'Hoje',
              isSelected: isToday,
              onTap: () {
                setState(() {
                  _selectedDate = today;
                });
              },
            ),
            _buildDateChip(
              label: 'Ontem',
              isSelected: isYesterday,
              onTap: () {
                setState(() {
                  _selectedDate = yesterday;
                });
              },
            ),
            _buildDateChip(
              label: isOther && _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : 'Outro',
              isSelected: isOther,
              onTap: _selectDate,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLineField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildSaveButton() {
    final padding = AppSpacing.pagePadding(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding.horizontal,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: AccessibleFilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.transaction != null ? 'Salvar' : 'Criar Transação',
                    style: AppTypography.labelLarge.copyWith(color: Colors.white),
                  ),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(_headerColor),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

