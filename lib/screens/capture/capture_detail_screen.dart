import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../features/capture/models/capture_models.dart';

class CaptureDetailScreen extends StatefulWidget {
  final String captureId;

  const CaptureDetailScreen({super.key, required this.captureId});

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  CaptureItem? _capture;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapture();
  }

  Future<void> _loadCapture() async {
    try {
      final repo = RecallrDependencies.instance.captureRepository;
      final capture = await repo.getCapture(widget.captureId);
      if (mounted) {
        setState(() {
          _capture = capture;
          _isLoading = false;
          if (capture == null) {
            _error = 'Capture not found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load capture.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _capture == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0),
        body: Center(
          child: Text(
            _error ?? 'Capture not found',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final item = _capture!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              item.type.toString().split('.').last.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            if (item.description.isNotEmpty) ...[
              const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
            ],
            if (item.personName != null) ...[
              const Text('Person', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.personName!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
            ],
            if (item.companyName != null) ...[
              const Text('Company', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item.companyName!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
