import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../features/categories/models/network_category.dart';
import '../../features/categories/widgets/save_organize_sheet.dart';
import '../../repositories/library_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Stream<List<NetworkCategory>>? _categories;
  final _streams = <String, Stream<List<LibraryEntry>>>{};
  String? _category;
  String _type = 'people';
  String _query = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.dependencies.libraryRepository;
    _categories ??= repo.categories();
    for (final type in ['people', 'captures', 'follow_ups']) {
      _streams.putIfAbsent(type, () => repo.entries(type));
    }
  }

  Future<void> _delete(NetworkCategory category) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Delete ${category.name}?'),
                content: const Text(
                    'Saved contacts and memories will be kept. Only this category assignment is removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete Category'))
                ]));
    if (yes != true || !mounted) return;
    try {
      await context.dependencies.libraryRepository.deleteCategory(category.id);
      if (mounted) setState(() => _category = null);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete category: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Categories'), actions: [
        IconButton(
            tooltip: 'Create Category',
            onPressed: () => editCategory(context),
            icon: const Icon(Icons.create_new_folder_outlined)),
      ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Text('A place for every connection.',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                StreamBuilder<List<NetworkCategory>>(
                    stream: _categories,
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Text(
                            'Could not load categories. Reopen this screen to retry.');
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();
                      return Wrap(spacing: 8, runSpacing: 8, children: [
                        ChoiceChip(
                            label: const Text('All'),
                            selected: _category == null,
                            onSelected: (_) =>
                                setState(() => _category = null)),
                        ChoiceChip(
                            label: const Text('Uncategorized'),
                            selected: _category == '',
                            onSelected: (_) => setState(() => _category = '')),
                        ...snapshot.data!.map((c) => InputChip(
                            label: Text(c.name),
                            avatar: Icon(categoryIcons[c.icon],
                                color: Color(c.color), size: 18),
                            selected: _category == c.id,
                            onPressed: () => setState(() => _category = c.id),
                            onDeleted: () => _delete(c),
                            deleteButtonTooltipMessage: 'Delete ${c.name}')),
                        ActionChip(
                            label: const Text('Create Category'),
                            avatar: const Icon(Icons.add),
                            onPressed: () => editCategory(context)),
                        if (_category?.isNotEmpty == true &&
                            snapshot.data!.any((c) => c.id == _category))
                          ActionChip(
                              label: const Text('Edit Category'),
                              onPressed: () => editCategory(context,
                                  category: snapshot.data!
                                      .firstWhere((c) => c.id == _category))),
                      ]);
                    }),
                const SizedBox(height: 20),
                SegmentedButton<String>(segments: const [
                  ButtonSegment(value: 'people', label: Text('People')),
                  ButtonSegment(value: 'captures', label: Text('Memories')),
                  ButtonSegment(value: 'follow_ups', label: Text('Follow-ups'))
                ], selected: {
                  _type
                }, onSelectionChanged: (v) => setState(() => _type = v.first)),
                const SizedBox(height: 16),
                TextField(
                    decoration: const InputDecoration(
                        labelText: 'Search saved items',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase())),
                const SizedBox(height: 16),
                StreamBuilder<List<LibraryEntry>>(
                    key: ValueKey(_type),
                    stream: _streams[_type],
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Text('Could not load saved items.');
                      if (!snapshot.hasData)
                        return const LinearProgressIndicator();
                      final entries = snapshot.data!
                          .where((e) =>
                              e.title.toLowerCase().contains(_query) &&
                              (_category == null ||
                                  (_category == ''
                                      ? e.categoryIds.isEmpty
                                      : e.categoryIds.contains(_category))))
                          .toList();
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('${entries.length} saved items'),
                            if (entries.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                      'Your saved items will appear here.')),
                            ...entries.map((entry) => Card(
                                child: ListTile(
                                    title: Text(entry.title),
                                    onTap: () => Navigator.pushNamed(
                                        context, entry.route),
                                    trailing: IconButton(
                                        tooltip: 'Change categories',
                                        icon: const Icon(Icons.folder_outlined),
                                        onPressed: () async {
                                          final selection =
                                              await SaveOrganizeSheet.show(
                                                  context,
                                                  title: entry.title,
                                                  initialCategories:
                                                      entry.categoryIds);
                                          if (selection == null ||
                                              !context.mounted) return;
                                          try {
                                            await context
                                                .dependencies.libraryRepository
                                                .categorize(
                                                    entry.collection,
                                                    entry.id,
                                                    selection.categoryIds);
                                          } catch (e) {
                                            if (context.mounted)
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Could not update categories: $e')));
                                          }
                                        })))),
                          ]);
                    }),
              ]))));
}
