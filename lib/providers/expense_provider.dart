import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/expense_model.dart';
import '../database/db_helper.dart';

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier();
});

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier() : super([]) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final expenses = await DBHelper.instance.getExpenses();
    state = expenses;
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await DBHelper.instance.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await DBHelper.instance.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await DBHelper.instance.deleteExpense(id);
    await loadExpenses();
  }
}
