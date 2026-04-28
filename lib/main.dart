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
        //fontFamily: 'Inter',
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString('tally_widgets');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        setState(() {
          _widgets = decoded.map((item) => TallyWidget.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading widgets: $e');
    } finally {
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

  void _updateWidget(
      TallyWidget widget, String newName, int newStep, String newColor) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widget.id);
      if (index != -1) {
        _widgets[index] = TallyWidget(
          id: widget.id,
          name: newName.isEmpty ? 'New Counter' : newName,
          count: widget.count,
          step: newStep,
          colorKey: newColor,
        );
      }
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Tally Counter',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                'ACTIVE: ${_widgets.length}',
                style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgets.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  itemCount: _widgets.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _widgets.removeAt(oldIndex);
                      _widgets.insert(newIndex, item);
                    });
                    _saveWidgets();
                  },
                  proxyDecorator: (widget, index, animation) => Material(
                    color: Colors.transparent,
                    child: widget,
                  ),
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
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showEditModal(context, null),
        backgroundColor: const Color(0xFF6366F1), // Indigo 600
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.add, size: 36),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueGrey.shade50, width: 2)),
            child: Icon(Icons.add, size: 64, color: Colors.blueGrey.shade200),
          ),
          const SizedBox(height: 24),
          const Text('No counters found',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Create your first tally counter to start tracking',
              style: TextStyle(
                  color: Colors.blueGrey, fontWeight: FontWeight.w500)),
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
      elevation: 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 32,
              right: 32,
              top: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(existing == null ? 'New Tally' : 'Edit Counter',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      const Text('Customize your widget preferences',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.blueGrey),
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC)),
                  )
                ],
              ),
              const SizedBox(height: 40),
              const Text('WIDGET LABEL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Colors.blueGrey)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Enter name (e.g. Daily Eggs)',
                  hintStyle: TextStyle(color: Colors.blueGrey.shade300),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Color(0xFF6366F1), width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INC STEP',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: Colors.blueGrey)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: stepController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: Color(0xFF6366F1), width: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VISUAL THEME',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: Colors.blueGrey)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _colorPalette
                              .take(5)
                              .map((colorData) => GestureDetector(
                                    onTap: () => setModalState(() =>
                                        selectedColor = colorData['key']!),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _getColor(colorData['key']!),
                                        borderRadius: BorderRadius.circular(10),
                                        border: selectedColor ==
                                                colorData['key']
                                            ? Border.all(
                                                color: const Color(0xFF6366F1),
                                                width: 3)
                                            : null,
                                        boxShadow: selectedColor ==
                                                colorData['key']
                                            ? [
                                                BoxShadow(
                                                    color: _getColor(
                                                            colorData['key']!)
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2))
                                              ]
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
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text;
                    final step = int.tryParse(stepController.text) ?? 1;

                    if (existing == null) {
                      _addWidget(
                          name: name, step: step, colorKey: selectedColor);
                    } else {
                      // Pass the new values to the update method rather than mutating the object directly
                      _updateWidget(existing, name, step, selectedColor);
                    }
                    Navigator.pop(context);
                    nameController.dispose(); // Clean up
                    stepController.dispose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                      existing == null ? 'Initialize Tally' : 'Confirm Update',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              if (existing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        _deleteWidget(existing.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: Color(0xFFF43F5E), size: 20),
                      label: const Text('Delete Widget',
                          style: TextStyle(
                              color: Color(0xFFF43F5E),
                              fontWeight: FontWeight.w900,
                              fontSize: 14)),
                    ),
                  ),
                ),
              const SizedBox(height: 48),
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
        border: Border.all(color: Colors.blueGrey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade200.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.move_up,
                              color: Colors.blueGrey, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5),
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('Step: ${widget.step}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.blueGrey, size: 22),
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF8FAFC)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  '${widget.count}',
                  style: const TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -6,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onDecrement,
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24)),
                          child: const Icon(Icons.remove,
                              size: 36, color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: onReset,
                      child: const Text('RESET',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 2)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: onIncrement,
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: const Icon(Icons.add,
                              size: 36, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
