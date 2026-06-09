import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/note_provider.dart';
import '../providers/expense_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final expenses = ref.watch(expensesProvider);
    
    // Calculate today's expense
    final today = DateTime.now();
    final todayExpenses = expenses.where((e) => 
      e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
    ).fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes & Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/analytics'),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Today\'s Expenses', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('\$${todayExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Recent Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push('/note_editor', extra: note),
                );
              },
              childCount: notes.length,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_expense',
            onPressed: () => context.push('/expense_editor'),
            child: const Icon(Icons.attach_money),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_note',
            onPressed: () => context.push('/note_editor'),
            child: const Icon(Icons.note_add),
          ),
        ],
      ),
    );
  }
}
