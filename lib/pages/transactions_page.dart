import 'package:flutter/material.dart';
import '../models/transaction_data.dart';
import '../components/add_transaction_dialog.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
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
        backgroundColor: const Color(0xFF4A90E2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Transactions",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage your finances",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
            size: 24,
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "\$${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddTransactionDialog = true;
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4A90E2),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF4A90E2),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Expenses"),
              Tab(text: "Revenue"),
            ],
          ),
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
      return const Center(
        child: Text(
          "No transactions found",
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isRevenue = transaction.type == TransactionType.revenue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(transaction.color.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.icon,
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
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${transaction.category} • ${transaction.date}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${isRevenue ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isRevenue
                  ? const Color(0xFF65C4A3)
                  : const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(width: 8),

          // 👁️ Bouton "voir les détails" (seulement pour revenue)
          if (isRevenue)
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.grey),
              onPressed: () {
                showTransactionDetails(transaction);
              },
            ),
          if (isRevenue)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                showEditTransactionDialog(transaction);
              },
            ),
        ],
      ),
    );
  }


  void showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(transaction.icon, color: Color(int.parse(transaction.color.replaceAll('#', '0xFF')))),
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
                _buildDetailRow("Amount", "\$${transaction.amount.toStringAsFixed(2)}"),
                _buildDetailRow("Color", transaction.color),

                // ✅ Afficher les champs dynamiques supplémentaires
                if (transaction.extraFields != null && transaction.extraFields!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Additional Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ...transaction.extraFields!.entries.map((e) => _buildDetailRow(e.key, e.value.toString())),
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
