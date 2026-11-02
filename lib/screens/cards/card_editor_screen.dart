import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../features/cards/models/visiting_card.dart';
import '../../features/cards/widgets/visiting_card_preview.dart';
import '../../services/auth_service.dart';
import 'public_card_screen.dart';

class CardEditorScreen extends StatefulWidget {
  final VisitingCard? initialCard;
  const CardEditorScreen({super.key, this.initialCard});
  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = {
    for (final key in VisitingCard.labels.keys) key: TextEditingController()
  };
  Set<String> _visible = VisitingCard.labels.keys.toSet();
  String _layout = 'classic';
  int _accent = 0xFF7C3AED;
  bool _loading = true, _busy = false, _preview = false;
  String? _error, _publicId;
  bool _published = false;
  Timer? _draftTimer;
  String get _id => widget.initialCard?.id ?? 'main';
  String get _cacheKey =>
      'card_draft_${AuthService().currentUser?.uid ?? 'preview'}_$_id';
  VisitingCard get _card => VisitingCard(
      id: _id,
      fields: _controllers.map((k, v) => MapEntry(k, v.text.trim())),
      visibleFields: _visible,
      layout: _layout,
      accent: _accent,
      sourcePersonId: widget.initialCard?.sourcePersonId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _controllers['name']!.text.isEmpty) _load();
  }

  Future<void> _load() async {
    try {
      final repository = context.dependencies.libraryRepository;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      final saved = await repository.getDraft(_id);
      final user = AuthService().currentUser;
      final card = cached != null
          ? VisitingCard.fromMap(
              _id, jsonDecode(cached) as Map<String, dynamic>)
          : saved ??
              widget.initialCard ??
              VisitingCard(id: _id, fields: {
                'name': user?.displayName ?? '',
                'email': user?.email ?? '',
                'photoUrl': user?.photoURL ?? ''
              });
      if (!mounted) return;
      setState(() {
        for (final e in _controllers.entries) {
          e.value.text = card.fields[e.key] ?? '';
        }
        _visible = card.visibleFields.toSet();
        _accent = card.accent;
        _layout = card.layout;
        _publicId = saved?.publicId;
        _published = saved?.published ?? false;
        _loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load your draft: $e';
        });
    }
  }

  void _changed() {
    setState(() {});
    _draftTimer?.cancel();
    final payload = _card.encodeDraft();
    final key = _cacheKey;
    _draftTimer = Timer(const Duration(milliseconds: 350), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, payload);
    });
  }

  Future<void> _save({bool publish = false}) async {
    if (_busy || !(_form.currentState?.validate() ?? true)) return;
    if (_card.name.isEmpty) {
      setState(() => _error = 'Enter a name before saving.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = context.dependencies.libraryRepository;
      final card = _card;
      if (publish) {
        final id = await repository.publish(card);
        if (mounted)
          setState(() {
            _publicId = id;
            _published = true;
          });
      } else {
        await repository.saveDraft(card);
      }
      _draftTimer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(publish
                ? 'Your public card is ready to share.'
                : 'Draft saved.')));
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save your card: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.initialCard == null
                ? 'My Visiting Card'
                : 'Shareable Contact Card'),
            actions: [
              IconButton(
                  tooltip: _preview ? 'Edit fields' : 'Preview card',
                  onPressed: () => setState(() => _preview = !_preview),
                  icon: Icon(_preview
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined)),
            ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error))),
                      LayoutBuilder(builder: (context, constraints) {
                        final preview = VisitingCardPreview(card: _card);
                        if (_preview) return preview;
                        final form = _buildForm();
                        return constraints.maxWidth >= 800
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(child: form),
                                    const SizedBox(width: 32),
                                    Expanded(child: preview),
                                  ])
                            : form;
                      }),
                      const SizedBox(height: 24),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        OutlinedButton(
                            onPressed: _busy ? null : () => _save(),
                            child: const Text('Save Draft')),
                        FilledButton.icon(
                            onPressed:
                                _busy ? null : () => _save(publish: true),
                            icon: const Icon(Icons.public),
                            label: Text(_busy
                                ? 'Saving…'
                                : _published
                                    ? 'Update Public Card'
                                    : 'Publish Card')),
                        if (_publicId != null && _published)
                          OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => PublicCardScreen(
                                              cardId: _publicId!))),
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Share / My QR')),
                        if (_published)
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      setState(() => _busy = true);
                                      try {
                                        await context
                                            .dependencies.libraryRepository
                                            .unpublish(_id);
                                        if (mounted)
                                          setState(() => _published = false);
                                      } catch (e) {
                                        if (mounted)
                                          setState(() => _error =
                                              'Could not unpublish: $e');
                                      } finally {
                                        if (mounted)
                                          setState(() => _busy = false);
                                      }
                                    },
                              child: const Text('Unpublish')),
                      ]),
                    ]))),
      );
  Widget _buildForm() => Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Make an introduction that lasts.',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Choose the details people see when they open your card.'),
        const SizedBox(height: 20),
        for (final entry in VisitingCard.labels.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: TextFormField(
                        controller: _controllers[entry.key],
                        enabled: !_busy,
                        maxLength: entry.key == 'bio' || entry.key == 'services'
                            ? 1000
                            : entry.key.endsWith('Url')
                                ? 2000
                                : 200,
                        maxLines: entry.key == 'bio' ? 3 : 1,
                        decoration: InputDecoration(
                            labelText: entry.value, counterText: ''),
                        onChanged: (_) => _changed(),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (entry.key == 'name' && v.isEmpty)
                            return 'Name is required';
                          if (['website', 'linkedin', 'photoUrl']
                                  .contains(entry.key) &&
                              v.isNotEmpty) {
                            final uri = Uri.tryParse(v);
                            if (uri == null ||
                                uri.scheme != 'https' ||
                                uri.host.isEmpty)
                              return 'Enter a complete https:// URL';
                          }
                          if (entry.key == 'email' &&
                              v.isNotEmpty &&
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v)) return 'Enter a valid email';
                          return null;
                        })),
                if (entry.key != 'name')
                  IconButton(
                      tooltip: _visible.contains(entry.key)
                          ? 'Public: ${entry.value}'
                          : 'Hidden: ${entry.value}',
                      onPressed: _busy
                          ? null
                          : () {
                              _visible.contains(entry.key)
                                  ? _visible.remove(entry.key)
                                  : _visible.add(entry.key);
                              _changed();
                            },
                      icon: Icon(_visible.contains(entry.key)
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined)),
              ])),
        SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'classic', label: Text('Classic')),
              ButtonSegment(value: 'centered', label: Text('Centered'))
            ],
            selected: {
              _layout
            },
            onSelectionChanged: (v) {
              _layout = v.first;
              _changed();
            }),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            children: [0xFF7C3AED, 0xFF0284C7, 0xFF059669, 0xFFDB2777]
                .map((c) => ChoiceChip(
                    label: Icon(Icons.circle, color: Color(c)),
                    selected: _accent == c,
                    onSelected: (_) {
                      _accent = c;
                      _changed();
                    }))
                .toList()),
      ]));
}
