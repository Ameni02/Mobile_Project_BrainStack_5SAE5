import 'package:flutter/material.dart';
import '../models/transaction_data.dart';
import '../components/add_transaction_dialog.dart';
import '../services/exchange_rate_service.dart';
import '../constants/currency.dart';
import '../theme/app_colors.dart';


class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showAddTransactionDialog = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Transactions List
                    _buildTransactionsList(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
          AddTransactionDialog(
            isOpen: _showAddTransactionDialog,
            onClose: () {
              setState(() {
                _showAddTransactionDialog = false;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showAddTransactionDialog = true;
          });
        },
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Transactions",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Manage your finances",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_down,
            title: "Expenses",
            amount: TransactionData.totalExpenses,
            color: const Color(0xFFE53E3E),
            backgroundColor: const Color(0xFFFED7D7),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_up,
            title: "Revenue",
            amount: TransactionData.totalRevenue,
            color: const Color(0xFF65C4A3),
            backgroundColor: const Color(0xFFD1FAE5),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required double amount,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatTnd(amount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "All Transactions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddTransactionDialog = true;
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
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
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Expenses"),
                Tab(text: "Revenue"),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(TransactionData.allTransactions),
                _buildTransactionList(TransactionData.expenseTransactions),
                _buildTransactionList(TransactionData.revenueTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "No transactions found",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isRevenue = transaction.type == TransactionType.revenue;
    final transactionColor = Color(int.parse(transaction.color.replaceAll('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: transactionColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: transactionColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              transaction.icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "• ${transaction.date}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isRevenue ? '+' : '-'}${formatTnd(transaction.amount)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isRevenue ? AppColors.revenue : AppColors.expense,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        showTransactionDetails(transaction);
                      },
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        showEditTransactionDialog(transaction);
                      },
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  void showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedCurrency = "EUR";
        double? convertedAmount;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> convert() async {
              setState(() => isLoading = true);
              final result = await ExchangeRateService.convertCurrency(
                transaction.amount,
                "TND", // devise source par défaut modifiée de USD à TND
                selectedCurrency,
              );
              setState(() {
                convertedAmount = result;
                isLoading = false;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    transaction.icon,
                    color: Color(int.parse(transaction.color.replaceAll('#', '0xFF'))),
                  ),
                  const SizedBox(width: 8),
                  Text(transaction.name),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Category", transaction.category),
                    _buildDetailRow("Date", transaction.date),
                    _buildDetailRow("Amount", "${CurrencyConfig.symbol}${transaction.amount.toStringAsFixed(2)}"),
                    const SizedBox(height: 16),

                    // ✅ Section conversion de devise
                    const Text(
                      "Currency Conversion",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown responsive
                    DropdownButton<String>(
                      isExpanded: true, // prend toute la largeur
                      value: selectedCurrency,
                      items: const [
                        DropdownMenuItem(value: "EUR", child: Text("🇪🇺 EUR - Euro")),
                        DropdownMenuItem(value: "TND", child: Text("🇹🇳 TND - Dinar tunisien")),
                        DropdownMenuItem(value: "GBP", child: Text("🇬🇧 GBP - Livre sterling")),
                        DropdownMenuItem(value: "JPY", child: Text("🇯🇵 JPY - Yen japonais")),
                        DropdownMenuItem(value: "USD", child: Text("🇺🇸 USD - Dollar américain")),
                        DropdownMenuItem(value: "CAD", child: Text("🇨🇦 CAD - Dollar canadien")),
                        DropdownMenuItem(value: "CHF", child: Text("🇨🇭 CHF - Franc suisse")),
                        DropdownMenuItem(value: "SEK", child: Text("🇸🇪 SEK - Couronne suédoise")),
                        DropdownMenuItem(value: "SAR", child: Text("🇸🇦 SAR - Riyal saoudien")),
                        DropdownMenuItem(value: "MAD", child: Text("🇲🇦 MAD - Dirham marocain")),
                        DropdownMenuItem(value: "DZD", child: Text("🇩🇿 DZD - Dinar algérien")),
                        DropdownMenuItem(value: "EGP", child: Text("🇪🇬 EGP - Livre égyptienne")),
                        DropdownMenuItem(value: "CNY", child: Text("🇨🇳 CNY - Yuan chinois")),
                        DropdownMenuItem(value: "INR", child: Text("🇮🇳 INR - Roupie indienne")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCurrency = value;
                            convertedAmount = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    // Bouton Convert sur nouvelle ligne, full width
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: convert,
                        child: const Text("Convert"),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Résultat conversion
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (convertedAmount != null)
                      Text(
                        "→ ${convertedAmount!.toStringAsFixed(2)} $selectedCurrency",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void showEditTransactionDialog(Transaction transaction) {
    final nameController = TextEditingController(text: transaction.name);
    final categoryController = TextEditingController(text: transaction.category);
    final amountController = TextEditingController(text: transaction.amount.toString());
    final dateController = TextEditingController(text: transaction.date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Transaction"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: "Date"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedTransaction = Transaction(
                  id: transaction.id,
                  name: nameController.text,
                  category: categoryController.text,
                  date: dateController.text,
                  amount: double.tryParse(amountController.text) ?? transaction.amount,
                  icon: transaction.icon,
                  color: transaction.color,
                  type: transaction.type,
                  extraFields: transaction.extraFields,
                );

                await TransactionData.updateTransaction(updatedTransaction);

                setState(() {}); // Refresh UI
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }


  void updateRevenueExample() async {
    // Cherche la transaction à modifier
    final transaction = TransactionData.revenueTransactions.firstWhere(
          (t) => t.id == 4, // ex : l’ID du salaire
    );

    // Crée une nouvelle version mise à jour
    final updatedTransaction = Transaction(
      id: transaction.id, // garder le même ID
      name: "Updated Salary Deposit",
      category: "Income",
      date: DateTime.now().toString(),
      amount: 5000.0, // nouveau montant
      icon: Icons.work,
      color: "#65C4A3",
      type: TransactionType.revenue,
    );

    // Appelle la méthode d’update
    await TransactionData.updateTransaction(updatedTransaction);
  }



  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



}
