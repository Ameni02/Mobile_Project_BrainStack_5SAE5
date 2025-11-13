import 'dart:io';

import 'package:flutter/material.dart';
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
          // Note: configure TwilioService.* static fields with real credentials
          await TwilioService.sendExpenseNotification(newTransaction);
        } catch (e) {
          debugPrint('Failed to send Twilio SMS: $e');
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
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Add Transaction',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close, color: Colors.grey),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tabs (styled pill indicator, equal width)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SizedBox(
                            height: 44,
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelPadding: EdgeInsets.zero,
                              indicatorPadding: const EdgeInsets.all(4),
                              labelColor: AppColors.primaryForeground,
                              unselectedLabelColor: AppColors.textSecondary,
                              tabs: [
                                Tab(child: Center(child: Text('Expense', style: const TextStyle(fontWeight: FontWeight.w600)))),
                                Tab(child: Center(child: Text('Revenue', style: const TextStyle(fontWeight: FontWeight.w600)))),
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
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: '0.00',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'What did you spend on?',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ElevatedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.receipt_long),
                label: Text(_receiptPath == null ? 'Add Receipt' : 'Change Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text(
              'Add Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an amount';
              if (double.tryParse(value) == null) return 'Invalid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What did you earn from?',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) =>
            value == null || value.isEmpty ? 'Please enter a description' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _revenueCategories.contains(_selectedCategory) ? _selectedCategory : null,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              onPressed: () => _handleSubmit('revenue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Revenue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            decoration: const InputDecoration(
              labelText: 'Company Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['company'] = value,
          ),
        ];
      case 'Freelance':
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Client Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['client'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Project Title',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['project'] = value,
          ),
        ];
      case 'Investment':
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Investment Type',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['type'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Return Rate (%)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _extraFields['rate'] = value,
          ),
        ];
      case 'Business':
        return [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Business Name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['business'] = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Transaction ID',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _extraFields['transactionId'] = value,
          ),
        ];
      default:
        return [];
    }
  }
}
