import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../features/cards/models/visiting_card.dart';
import '../../features/cards/widgets/visiting_card_preview.dart';
import '../../features/categories/widgets/save_organize_sheet.dart';
import '../../services/auth_service.dart';

class PublicCardScreen extends StatefulWidget {
  final String cardId;
  final bool saveOnOpen;
  const PublicCardScreen(
      {super.key, required this.cardId, this.saveOnOpen = false});
  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  Future<VisitingCard?>? _future;
  bool _saving = false;
  bool _autoSaveStarted = false;
  String? _savedPerson;
  final _imageKey = GlobalKey();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        context.dependencies.libraryRepository.getPublicCard(widget.cardId);
    if (widget.saveOnOpen &&
        !_autoSaveStarted &&
        AuthService().currentUser != null) {
      _autoSaveStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final card = await _future;
        if (mounted && card != null) await _save(card);
      });
    }
  }

  Future<void> _save(VisitingCard card) async {
    if (_saving) return;
    if (AuthService().currentUser == null) {
      Navigator.pushNamed(context, '/save-card/${widget.cardId}');
      return;
    }
    final selection = await SaveOrganizeSheet.show(context,
        title: card.name, showNote: true, requireCategory: true);
    if (selection == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final id = await context.dependencies.libraryRepository
          .importCard(widget.cardId, selection.categoryIds, selection.note);
      if (mounted) setState(() => _savedPerson = id);
    } catch (e) {
      if (mounted) _message('Could not save contact: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _share(VisitingCard card, String format) async {
    try {
      final link =
          context.dependencies.libraryRepository.cardLink(widget.cardId);
      if (format == 'copy') {
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) _message('Card link copied');
        return;
      }
      if (format == 'vcf') {
        await SharePlus.instance.share(ShareParams(files: [
          XFile.fromData(Uint8List.fromList(utf8.encode(card.vCard)),
              mimeType: 'text/vcard')
        ], fileNameOverrides: [
          'contact.vcf'
        ], subject: card.name));
      } else if (format == 'image') {
        final boundary = _imageKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) return;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data != null)
          await SharePlus.instance.share(ShareParams(files: [
            XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png')
          ], fileNameOverrides: [
            'visiting-card.png'
          ], text: link));
      } else {
        await SharePlus.instance.share(ShareParams(
            text: '${card.name}\n$link',
            subject: 'Visiting card: ${card.name}'));
      }
    } catch (_) {
      if (mounted) _message('Could not share. Try copying the card link.');
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri) && mounted)
        _message('No application is available for this action.');
    } catch (_) {
      if (mounted) _message('Could not open this contact action.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Visiting Card')),
      body: FutureBuilder<VisitingCard?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data == null)
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.link_off, size: 48),
                const SizedBox(height: 16),
                const Text('This card is unavailable or has been unpublished.'),
                TextButton(
                    onPressed: () => setState(() => _future = context
                        .dependencies.libraryRepository
                        .getPublicCard(widget.cardId)),
                    child: const Text('Retry')),
              ]));
            final card = snapshot.data!;
            final f = card.publicFields;
            return Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      RepaintBoundary(
                          key: _imageKey,
                          child: ColoredBox(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Column(children: [
                                VisitingCardPreview(card: card),
                                const SizedBox(height: 16),
                                QrImageView(
                                    data: context.dependencies.libraryRepository
                                        .cardLink(card.id),
                                    size: 180,
                                    backgroundColor: Colors.white),
                                const SizedBox(height: 12)
                              ]))),
                      const SizedBox(height: 20),
                      if (_savedPerson != null)
                        FilledButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, '/person/$_savedPerson'),
                            icon: const Icon(Icons.check),
                            label: const Text('Saved — View Contact'))
                      else
                        FilledButton.icon(
                            onPressed: _saving ? null : () => _save(card),
                            icon: const Icon(Icons.person_add_alt),
                            label: Text(
                                _saving ? 'Saving…' : 'Save to My Network')),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                                onPressed: () => _share(card, 'link'),
                                icon: const Icon(Icons.share),
                                label: const Text('Share')),
                            OutlinedButton(
                                onPressed: () => _share(card, 'copy'),
                                child: const Text('Copy Link')),
                            OutlinedButton(
                                onPressed: () => _share(card, 'vcf'),
                                child: const Text('Contact (.vcf)')),
                            OutlinedButton(
                                onPressed: () => _share(card, 'image'),
                                child: const Text('Card Image')),
                            if (f['phone']?.isNotEmpty == true)
                              TextButton(
                                  onPressed: () => _open(
                                      Uri(scheme: 'tel', path: f['phone'])),
                                  child: const Text('Call')),
                            if (f['email']?.isNotEmpty == true)
                              TextButton(
                                  onPressed: () => _open(
                                      Uri(scheme: 'mailto', path: f['email'])),
                                  child: const Text('Email')),
                            if (f['whatsapp']?.isNotEmpty == true)
                              TextButton(
                                  onPressed: () => _open(Uri.https('wa.me',
                                      '/${f['whatsapp']!.replaceAll(RegExp(r'\D'), '')}')),
                                  child: const Text('WhatsApp')),
                            if (f['website']?.startsWith('https://') == true)
                              TextButton(
                                  onPressed: () =>
                                      _open(Uri.parse(f['website']!)),
                                  child: const Text('Website')),
                          ]),
                    ])));
          }));
}
