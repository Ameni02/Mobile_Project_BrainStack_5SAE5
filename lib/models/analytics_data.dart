class MonthlyData {
  final String month;
  final double expenses;
  final double revenue;

  MonthlyData({
    required this.month,
    required this.expenses,
    required this.revenue,
  });
}

class CategoryData {
  final String name;
  final double value;
  final String color;

  CategoryData({
    required this.name,
    required this.value,
    required this.color,
  });
}

class WeeklySpending {
  final String day;
  final double amount;

  WeeklySpending({
    required this.day,
    required this.amount,
  });
}

class SpendingInsight {
  final String title;
  final String description;
  final String icon;
  final String color;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class AnalyticsData {
  static final List<MonthlyData> monthlyData = [
    MonthlyData(month: "Jan", expenses: 2400, revenue: 4800),
    MonthlyData(month: "Feb", expenses: 1800, revenue: 4500),
    MonthlyData(month: "Mar", expenses: 2200, revenue: 5200),
    MonthlyData(month: "Apr", expenses: 2800, revenue: 4900),
    MonthlyData(month: "May", expenses: 2100, revenue: 5500),
    MonthlyData(month: "Jun", expenses: 2600, revenue: 5800),
  ];

  static final List<CategoryData> categoryData = [
    CategoryData(name: "Food & Drink", value: 450, color: "#65C4A3"),
    CategoryData(name: "Shopping", value: 380, color: "#4A90E2"),
    CategoryData(name: "Transportation", value: 280, color: "#7ED321"),
    CategoryData(name: "Utilities", value: 320, color: "#50E3C2"),
    CategoryData(name: "Entertainment", value: 180, color: "#9013FE"),
  ];

  static final List<WeeklySpending> weeklySpending = [
    WeeklySpending(day: "Mon", amount: 85),
    WeeklySpending(day: "Tue", amount: 120),
    WeeklySpending(day: "Wed", amount: 95),
    WeeklySpending(day: "Thu", amount: 145),
    WeeklySpending(day: "Fri", amount: 180),
    WeeklySpending(day: "Sat", amount: 220),
    WeeklySpending(day: "Sun", amount: 160),
  ];

  static final List<SpendingInsight> insights = [
    SpendingInsight(
      title: "Great savings this month!",
      description: "You saved 15% more compared to last month",
      icon: "trending_down",
      color: "#65C4A3",
    ),
    SpendingInsight(
      title: "Weekend spending alert",
      description: "Your weekend expenses are 40% higher than weekdays",
      icon: "calendar",
      color: "#65C4A3",
    ),
  ];

  static double get totalExpenses => monthlyData.fold(0, (sum, data) => sum + data.expenses);
  static double get totalRevenue => monthlyData.fold(0, (sum, data) => sum + data.revenue);
  static double get netIncome => totalRevenue - totalExpenses;
  static double get savingsRate => (netIncome / totalRevenue) * 100;
}
