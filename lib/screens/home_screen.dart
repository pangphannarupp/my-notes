import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/note_provider.dart';
import '../providers/expense_provider.dart';
import '../services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final expenses = ref.watch(expensesProvider);

    final today = DateTime.now();
    final todayExpenses = expenses.where((e) => 
      e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
    ).fold(0.0, (sum, e) => sum + e.amount);

    Widget _buildDashboard() {
      return CustomScrollView(
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      NotificationService().showTestNotification();
                    },
                    child: const Text('Test Notification'),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= 5) return null; // Only show up to 5 recent notes
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push('/note_editor', extra: note),
                );
              },
              childCount: notes.length > 5 ? 5 : notes.length,
            ),
          ),
        ],
      );
    }

    Widget _buildAllNotes() {
      if (notes.isEmpty) {
        return const Center(child: Text('No notes yet.'));
      }
      return ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            title: Text(note.title),
            subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: note.reminderDate != null ? const Icon(Icons.alarm, color: Colors.deepPurple) : null,
            onTap: () => context.push('/note_editor', extra: note),
          );
        },
      );
    }

    Widget _buildCalendar() {
      // Filter notes and expenses for selected day
      final selectedNotes = notes.where((n) => isSameDay(n.createdAt, _selectedDay)).toList();
      final selectedExpenses = expenses.where((e) => isSameDay(e.date, _selectedDay)).toList();
      final selectedExpenseTotal = selectedExpenses.fold(0.0, (sum, e) => sum + e.amount);

      return Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return notes.where((n) => isSameDay(n.createdAt, day)).toList();
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                if (selectedExpenses.isNotEmpty)
                  ListTile(
                    title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('\$${selectedExpenseTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                if (selectedNotes.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ...selectedNotes.map((note) => ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push('/note_editor', extra: note),
                )),
              ],
            ),
          ),
        ],
      );
    }

    final List<Widget> pages = [
      _buildDashboard(),
      _buildAllNotes(),
      _buildCalendar(),
    ];

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
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
        ],
      ),
      floatingActionButton: _currentIndex == 2 ? null : Column(
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
