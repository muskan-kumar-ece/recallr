import 'package:flutter/material.dart';
import '../../../core/di/recallr_dependencies.dart';
import '../models/network_category.dart';

class SaveOrganization {
  final List<String> categoryIds;
  final String note;
  const SaveOrganization(this.categoryIds, this.note);
}

const categoryIcons = <String, IconData>{
  'folder': Icons.folder_outlined,
  'work': Icons.work_outline,
  'people': Icons.people_outline,
  'school': Icons.school_outlined,
  'favorite': Icons.favorite_outline,
  'event': Icons.event_outlined
};

Future<NetworkCategory?> editCategory(BuildContext context,
        {NetworkCategory? category}) =>
    showDialog<NetworkCategory>(
        context: context, builder: (_) => _CategoryEditor(category: category));

class _CategoryEditor extends StatefulWidget {
  final NetworkCategory? category;
  const _CategoryEditor({this.category});
  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.category?.name);
  late int _color = widget.category?.color ?? 0xFF7C3AED;
  late String _icon = widget.category?.icon ?? 'folder';
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _name.text.trim().isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = await context.dependencies.libraryRepository.saveCategory(
          NetworkCategory(
              id: widget.category?.id ?? '',
              name: _name.text.trim(),
              color: _color,
              icon: _icon,
              order: widget.category?.order ?? 0));
      if (mounted) Navigator.pop(context, value);
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = 'Could not save category: $e';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.category == null ? 'Create Category' : 'Edit Category'),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _name,
              maxLength: 60,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Category name'),
              onSubmitted: (_) => _save()),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              children: categoryIcons.entries
                  .map((e) => ChoiceChip(
                      label: Icon(e.value, size: 20),
                      tooltip: e.key,
                      selected: _icon == e.key,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _icon = e.key)))
                  .toList()),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              children: [
                0xFF7C3AED,
                0xFF0284C7,
                0xFF059669,
                0xFFDB2777,
                0xFFD97706
              ]
                  .map((c) => ChoiceChip(
                      label: Icon(Icons.circle, color: Color(c)),
                      selected: _color == c,
                      onSelected:
                          _saving ? null : (_) => setState(() => _color = c)))
                  .toList()),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ])),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save Category'))
        ],
      );
}

class SaveOrganizeSheet extends StatefulWidget {
  final String title;
  final List<String> initialCategories;
  final bool showNote;
  final bool requireCategory;
  const SaveOrganizeSheet(
      {super.key,
      required this.title,
      this.initialCategories = const [],
      this.showNote = false,
      this.requireCategory = false});
  static Future<SaveOrganization?> show(BuildContext context,
          {required String title,
          List<String> initialCategories = const [],
          bool showNote = false,
          bool requireCategory = false}) =>
      showModalBottomSheet<SaveOrganization>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => SaveOrganizeSheet(
              title: title,
              initialCategories: initialCategories,
              showNote: showNote,
              requireCategory: requireCategory));
  @override
  State<SaveOrganizeSheet> createState() => _SaveOrganizeSheetState();
}

class _SaveOrganizeSheetState extends State<SaveOrganizeSheet> {
  late final _selected = widget.initialCategories.toSet();
  final _note = TextEditingController();
  String _query = '';
  Stream<List<NetworkCategory>>? _stream;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stream ??= context.dependencies.libraryRepository.categories();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Save & Organize',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(widget.title),
              const SizedBox(height: 20),
              TextField(
                  decoration: const InputDecoration(
                      labelText: 'Search categories',
                      prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _query = v.toLowerCase())),
              const SizedBox(height: 12),
              StreamBuilder<List<NetworkCategory>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Text(
                          'Could not load categories. Close and retry.');
                    if (!snapshot.hasData)
                      return const LinearProgressIndicator();
                    final categories = snapshot.data!;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories
                                  .where((c) =>
                                      c.name.toLowerCase().contains(_query))
                                  .map((c) => FilterChip(
                                      label: Text(c.name),
                                      avatar: Icon(categoryIcons[c.icon],
                                          color: Color(c.color), size: 18),
                                      selected: _selected.contains(c.id),
                                      onSelected: (v) => setState(() {
                                            v
                                                ? _selected.add(c.id)
                                                : _selected.remove(c.id);
                                          })))
                                  .toList()),
                          if (categories.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                    'Create your first category to organize your network.')),
                          TextButton.icon(
                              onPressed: () async {
                                final created = await editCategory(context);
                                if (created != null && mounted)
                                  setState(() => _selected.add(created.id));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Category')),
                          if (widget.showNote)
                            TextField(
                                controller: _note,
                                maxLines: 3,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                    labelText: 'Private note (optional)')),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                              onPressed: widget.requireCategory &&
                                      !_selected.any((id) =>
                                          categories.any((c) => c.id == id))
                                  ? null
                                  : () => Navigator.pop(
                                      context,
                                      SaveOrganization(
                                          _selected
                                              .where((id) => categories
                                                  .any((c) => c.id == id))
                                              .toList(),
                                          _note.text.trim())),
                              icon: const Icon(Icons.check),
                              label: Text(widget.requireCategory &&
                                      !_selected.any((id) =>
                                          categories.any((c) => c.id == id))
                                  ? 'Select or create a category'
                                  : _selected.isEmpty
                                      ? 'Save without category'
                                      : 'Save')),
                        ]);
                  }),
            ]),
      );
}
