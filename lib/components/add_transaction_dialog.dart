import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transaction_data.dart';
import '../theme/app_colors.dart';
import '../services/twilio_service.dart';

// OCR/Mindee removed — receipt picker stores image path only.
class AddTransactionDialog extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const AddTransactionDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '';

  // Champs dynamiques supplémentaires
  Map<String, dynamic> _extraFields = {};
  final ImagePicker _picker = ImagePicker();
  String? _receiptPath;
  bool _isSubmitting = false;

  final List<String> _expenseCategories = [
    'Shopping',
    'Food & Drink',
    'Utilities',
    'Transportation',
    'Entertainment',
    'Other',
  ];

  final List<String> _revenueCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this); // ⚡ important
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = '';
          _extraFields.clear();
          _amountController.clear();
          _descriptionController.clear();
        });
      }
    });

    // Charger les transactions
    TransactionData.loadTransactions().then((_) {
      setState(() {});
    });
  }



  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit(String type) async {
    if (_formKey.currentState!.validate() && _selectedCategory.isNotEmpty) {
      setState(() => _isSubmitting = true);

      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch, // ID unique
        name: _descriptionController.text,
        category: _selectedCategory,
        date: DateTime.now().toString(), // ou formatte comme "Today, 2:30 PM"
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        icon: type == 'expense' ? Icons.shopping_bag : Icons.attach_money,
        color: type == 'expense' ? "#FF0000" : "#00FF00",
        type: type == 'expense' ? TransactionType.expense : TransactionType.revenue,
        extraFields: _extraFields.isNotEmpty ? Map.from(_extraFields) : {}, // ✅ Ajouté
      );

      // Ajout dans TransactionData et sauvegarde
      await TransactionData.addTransaction(newTransaction);

      // Send Twilio notification for expenses (best-effort)
      if (newTransaction.type == TransactionType.expense) {
        try {
          if (kDebugMode) {
            debugPrint('Attempting to send Twilio notification for expense...');
          }
          
          final smsSent = await TwilioService.sendExpenseNotification(newTransaction);
          
          if (mounted) {
            if (smsSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Expense notification sent via SMS'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              // Always show error so user knows SMS failed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Failed to send SMS notification. Check console for details.'),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 4),
                ),
              );
              if (kDebugMode) {
                debugPrint('❌ SMS notification failed - check Twilio credentials and network connection');
              }
            }
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Exception sending Twilio SMS: $e');
            debugPrint('❌ Stack trace: $stackTrace');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error sending SMS: ${e.toString()}'),
                backgroundColor: AppColors.expense,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Réinitialiser les champs
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = '';
        _extraFields.clear();
        _receiptPath = null;
        _isSubmitting = false;
      });

      // Fermer le dialog
      widget.onClose();
    }
  }

  Future<void> _pickReceipt() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _receiptPath = picked.path;
      _extraFields['receiptPath'] = picked.path;
    });

    // No OCR: just keep the picked receipt path in extraFields
    // (All OCR-related functionality has been removed)
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    // Render as an inline component (overlay) so it can be used inside a Stack
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black54),
          ),
          // Centered card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
              child: Material(
                color: AppColors.card,
                elevation: 16,
                borderRadius: BorderRadius.circular(24),
                shadowColor: Colors.black.withOpacity(0.2),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight, width: 1),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    AppColors.accent.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Add Transaction',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: widget.onClose,
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tabs (styled pill indicator, equal width)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            height: 44,
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelPadding: EdgeInsets.zero,
                              indicatorPadding: const EdgeInsets.all(4),
                              labelColor: AppColors.textPrimary,
                              unselectedLabelColor: AppColors.textSecondary,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(child: Center(child: Text('Expense'))),
                                Tab(child: Center(child: Text('Revenue'))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(child: _buildExpenseForm()),
                              SingleChildScrollView(child: _buildRevenueForm()),
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
        ],
      ),
    );
  }

  // ---------- FORMULAIRE EXPENSE ----------
  Widget _buildExpenseForm() {
    return Column(
      children: [
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (TND)',
            hintText: '0.00',
            prefixIcon: const Icon(Icons.attach_money, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.muted.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter an amount';
            final parsed = double.tryParse(value.replaceAll(',', '.'));
            if (parsed == null) return 'Invalid amount';
            if (parsed <= 0) return 'Amount must be greater than 0';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'What did you spend on?',
            prefixIcon: const Icon(Icons.description, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.muted.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a description';
            if (value.length > 100) return 'Description too long (max 100 chars)';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: (_tabController.index == 0
              ? _expenseCategories.contains(_selectedCategory)
              : _revenueCategories.contains(_selectedCategory))
              ? _selectedCategory
              : null,
          decoration: InputDecoration(
            labelText: 'Category',
            prefixIcon: const Icon(Icons.category, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.muted.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          hint: const Text('Select category'),
          items: (_tabController.index == 0
              ? _expenseCategories
              : _revenueCategories)
              .map((category) => DropdownMenuItem(value: category, child: Text(category)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value ?? '';
              _extraFields.clear();
            });
          },
          validator: (value) =>
          value == null || value.isEmpty ? 'Please select a category' : null,
        ),

        const SizedBox(height: 16),

        // Receipt picker for expenses
        if (_tabController.index == 0) ...[
          Row(
            children: [
              if (_receiptPath != null)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_receiptPath!), fit: BoxFit.cover),
                  ),
                ),
              if (_receiptPath != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text(_receiptPath == null ? 'Add Receipt' : 'Change Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isSubmitting)
                ? null
                : () {
              // Final validation including category
              if (!_formKey.currentState!.validate() || _selectedCategory.isEmpty) {
                if (_selectedCategory.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
                }
                return;
              }
              _handleSubmit('expense');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- FORMULAIRE REVENUE ----------
  Widget _buildRevenueForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (TND)',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.attach_money, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an amount';
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null) return 'Invalid amount';
              if (parsed <= 0) return 'Amount must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'What did you earn from?',
              prefixIcon: const Icon(Icons.description, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (value) =>
            value == null || value.isEmpty ? 'Please enter a description' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _revenueCategories.contains(_selectedCategory) ? _selectedCategory : null,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            hint: const Text('Select category'),
            items: _revenueCategories
                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
                _extraFields.clear();
              });
            },
            validator: (value) =>
            value == null || value.isEmpty ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16),

          // Champs supplémentaires dynamiques selon la catégorie
          ..._buildExtraFields(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                if (!_formKey.currentState!.validate() || _selectedCategory.isEmpty) {
                  if (_selectedCategory.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
                  }
                  return;
                }
                _handleSubmit('revenue');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.revenue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add Revenue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- CHAMPS SUPPLÉMENTAIRES ----------
  List<Widget> _buildExtraFields() {
    switch (_selectedCategory) {
      case 'Salary':
        return [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Company Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['company'] = value,
          ),
        ];
      case 'Freelance':
        return [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Client Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['client'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Project Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['project'] = value,
          ),
        ];
      case 'Investment':
        return [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Investment Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['type'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Return Rate (%)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _extraFields['rate'] = value,
          ),
        ];
      case 'Business':
        return [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['business'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Transaction ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.muted.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => _extraFields['transactionId'] = value,
          ),
        ];
      default:
        return [];
    }
  }
}
