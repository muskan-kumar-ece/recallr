import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/di/recallr_dependencies.dart';

class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});
  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  final _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _link = TextEditingController();
  bool _opening = false;
  String? _error;
  Future<void> _open(String? raw) async {
    if (_opening || raw == null) return;
    final uri = Uri.tryParse(raw.trim());
    final expected =
        Uri.parse(context.dependencies.libraryRepository.cardLink('check'));
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != expected.host ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'card' ||
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(uri.pathSegments.last)) {
      setState(() => _error = 'Scan or paste a published Recallr card link.');
      return;
    }
    _opening = true;
    await _controller.stop();
    if (!mounted) return;
    await Navigator.pushNamed(context, '/card/${uri.pathSegments.last}');
    if (mounted) {
      _opening = false;
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Scan a Visiting Card')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SizedBox(
            height: 320,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    for (final code in capture.barcodes) {
                      if (code.rawValue != null) {
                        _open(code.rawValue);
                        break;
                      }
                    }
                  },
                  errorBuilder: (context, error) => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.no_photography_outlined, size: 40),
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Allow camera access, or paste a card link below.')),
                    TextButton(
                        onPressed: () => _controller.start(),
                        child: const Text('Retry camera')),
                  ])),
                ))),
        const SizedBox(height: 16),
        const Text('Point the camera at a Recallr QR code.'),
        Wrap(spacing: 12, children: [
          IconButton(
              tooltip: 'Toggle flash',
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flash_on)),
          IconButton(
              tooltip: 'Switch camera',
              onPressed: () => _controller.switchCamera(),
              icon: const Icon(Icons.cameraswitch)),
          TextButton.icon(
              onPressed: () async {
                try {
                  final image = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (image == null) return;
                  final capture = await _controller.analyzeImage(image.path);
                  if (capture?.barcodes.isNotEmpty == true) {
                    await _open(capture!.barcodes.first.rawValue);
                  } else if (mounted) {
                    setState(() => _error =
                        'No QR code found. Try a clearer image or paste the link.');
                  }
                } catch (_) {
                  if (mounted)
                    setState(() => _error =
                        'Image scanning is unavailable here. Paste the card link instead.');
                }
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('Scan image')),
        ]),
        TextField(
            controller: _link,
            decoration: const InputDecoration(labelText: 'Paste card link'),
            onSubmitted: _open),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: () => _open(_link.text), child: const Text('Open Card')),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
      ]));
}
