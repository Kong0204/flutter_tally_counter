import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const TallyCounterApp());
}

class TallyWidget {
  String id;
  String name;
  int count;
  int step;
  String colorKey;

  TallyWidget({
    required this.id,
    required this.name,
    this.count = 0,
    required this.step,
    required this.colorKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'count': count,
        'step': step,
        'colorKey': colorKey,
      };

  factory TallyWidget.fromJson(Map<String, dynamic> json) => TallyWidget(
        id: json['id'],
        name: json['name'],
        count: json['count'],
        step: json['step'],
        colorKey: json['colorKey'],
      );
}

class TallyCounterApp extends StatelessWidget {
  const TallyCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tally Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TallyWidget> _widgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWidgets();
  }

  Future<void> _loadWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('tally_widgets');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _widgets = decoded.map((item) => TallyWidget.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWidgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_widgets.map((w) => w.toJson()).toList());
    await prefs.setString('tally_widgets', encoded);
  }

  void _addWidget(
      {required String name, required int step, required String colorKey}) {
    setState(() {
      _widgets.add(TallyWidget(
        id: const Uuid().v4(),
        name: name.isEmpty ? 'New Counter' : name,
        step: step,
        colorKey: colorKey,
      ));
    });
    _saveWidgets();
  }

  void _updateWidget(TallyWidget widget) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widget.id);
      if (index != -1) _widgets[index] = widget;
    });
    _saveWidgets();
  }

  void _deleteWidget(String id) {
    setState(() {
      _widgets.removeWhere((w) => w.id == id);
    });
    _saveWidgets();
  }

  Color _getColor(String key) {
    switch (key) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'orange':
        return const Color(0xFFF97316);
      case 'rose':
        return const Color(0xFFF43F5E);
      case 'violet':
        return const Color(0xFF8B5CF6);
      case 'slate':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  final List<Map<String, String>> _colorPalette = [
    {'name': 'Indigo', 'key': 'indigo'},
    {'name': 'Emerald', 'key': 'emerald'},
    {'name': 'Blue', 'key': 'blue'},
    {'name': 'Amber', 'key': 'orange'},
    {'name': 'Rose', 'key': 'rose'},
    {'name': 'Violet', 'key': 'violet'},
    {'name': 'Slate', 'key': 'slate'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Tally Counter',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              'Active: ${_widgets.length}',
              style: TextStyle(
                  color: Colors.slate.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgets.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _widgets.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _widgets.removeAt(oldIndex);
                      _widgets.insert(newIndex, item);
                    });
                    _saveWidgets();
                  },
                  itemBuilder: (context, index) {
                    final widget = _widgets[index];
                    return CounterCard(
                      key: ValueKey(widget.id),
                      widget: widget,
                      color: _getColor(widget.colorKey),
                      onIncrement: () {
                        setState(() => widget.count += widget.step);
                        _saveWidgets();
                      },
                      onDecrement: () {
                        setState(() => widget.count -= widget.step);
                        _saveWidgets();
                      },
                      onReset: () {
                        setState(() => widget.count = 0);
                        _saveWidgets();
                      },
                      onEdit: () => _showEditModal(context, widget),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditModal(context, null),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: Colors.slate.shade50, shape: BoxShape.circle),
            child: Icon(Icons.add, size: 64, color: Colors.slate.shade300),
          ),
          const SizedBox(height: 24),
          const Text('No counters found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Create your first tally counter to start tracking',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, TallyWidget? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final stepController =
        TextEditingController(text: (existing?.step ?? 1).toString());
    String selectedColor = existing?.colorKey ?? 'indigo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 32,
              right: 32,
              top: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'New Tally' : 'Edit Counter',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Customize your widget preferences',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              const Text('WIDGET LABEL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.black,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name (e.g. Daily Eggs)',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('STEP',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.black,
                                letterSpacing: 2)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: stepController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('THEME',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.black,
                                letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children:
                              ['indigo', 'emerald', 'blue', 'orange', 'rose']
                                  .map((color) => GestureDetector(
                                        onTap: () => setModalState(
                                            () => selectedColor = color),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _getColor(color),
                                            shape: BoxShape.circle,
                                            border: selectedColor == color
                                                ? Border.all(
                                                    color: Colors.black,
                                                    width: 2)
                                                : null,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text;
                    final step = int.tryParse(stepController.text) ?? 1;
                    if (existing == null) {
                      _addWidget(
                          name: name, step: step, colorKey: selectedColor);
                    } else {
                      existing.name = name;
                      existing.step = step;
                      existing.colorKey = selectedColor;
                      _updateWidget(existing);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                      existing == null ? 'Initialize Tally' : 'Confirm Update',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              if (existing != null)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _deleteWidget(existing.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete Widget',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class CounterCard extends StatelessWidget {
  final TallyWidget widget;
  final Color color;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;
  final VoidCallback onEdit;

  const CounterCard({
    super.key,
    required this.widget,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.slate.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.open_with, color: Colors.slate, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COUNTER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.black,
                                letterSpacing: 2,
                                color: color)),
                        Text(widget.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, py: 4),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('Step: ${widget.step}',
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.settings,
                            color: Colors.grey, size: 20)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 32),
            Text('${widget.count}',
                style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: onDecrement,
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.remove, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                    onPressed: onReset,
                    child: const Text('RESET',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 2))),
                const SizedBox(width: 16),
                Expanded(
                  child: IconButton(
                    onPressed: onIncrement,
                    style: IconButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    icon: const Icon(Icons.add, size: 32),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
