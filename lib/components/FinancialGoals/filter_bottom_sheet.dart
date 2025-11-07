import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String currentCategory;
  final String currentSort;
  final Function(String, String) onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentCategory,
    required this.currentSort,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedCategory;
  late String _selectedSort;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Travel',
    'Savings',
    'Health',
    'Education',
    'Entertainment',
    'Other'
  ];

  final Map<String, String> _sortOptions = {
    'deadline': 'Deadline',
    'progress': 'Progress',
    'priority': 'Priority',
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _selectedSort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter & Sort",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Category Filter
          const Text(
            "Category",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) => ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: const Color(0xFF4A90E2),
              labelStyle: TextStyle(
                color: _selectedCategory == category ? Colors.white : Colors.black,
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Sort Options
          const Text(
            "Sort By",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._sortOptions.entries.map((entry) => RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _selectedSort,
            onChanged: (value) {
              setState(() => _selectedSort = value!);
            },
            activeColor: const Color(0xFF4A90E2),
          )),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCategory, _selectedSort);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Apply Filters"),
            ),
          ),
        ],
      ),
    );
  }
}