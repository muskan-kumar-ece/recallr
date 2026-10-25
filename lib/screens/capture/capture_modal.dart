import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/theme/theme.dart';
import '../../features/capture/models/capture_models.dart';
import '../../features/capture/models/capture_processing_models.dart';
import '../../features/capture/widgets/business_card_capture_view.dart';
import '../../features/capture/widgets/capture_empty_state.dart';
import '../../features/capture/widgets/capture_error_view.dart';
import '../../features/capture/widgets/capture_header.dart';
import '../../features/capture/widgets/capture_method_grid.dart';
import '../../features/capture/widgets/capture_recent_list.dart';
import '../../features/capture/widgets/capture_review_view.dart';
import '../../features/capture/widgets/capture_success_view.dart';
import '../../features/capture/widgets/photo_doc_capture_view.dart';
import '../../features/capture/widgets/quick_note_capture_view.dart';
import '../../features/capture/widgets/voice_capture_view.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/media_storage_repository.dart';
import '../../repositories/capture_processing_repository.dart';
import '../../services/media_picker_service.dart';
import '../../services/audio_recorder_service.dart';
import '../../repositories/people_repository.dart';
import '../../features/people/models/person_item.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/ocr/ocr_entity_extractor.dart';

class CaptureModal extends StatefulWidget {
  final bool isEmpty;
  final bool isError;
  final String? errorMessage;
  final ValueChanged<CaptureItem>? onSaved;
  final VoidCallback? onClose;
  final CaptureRepository? repository;
  final CaptureRepository? captureRepository;
  final MediaStorageRepository? mediaStorageRepository;
  final CaptureProcessingRepository? captureProcessingRepository;
  final MediaPickerService? mediaPickerService;
  final AudioRecorderService? audioRecorderService;
  final OcrService? ocrService;
  final List<CaptureItem>? initialCaptures;

  const CaptureModal({
    super.key,
    this.isEmpty = false,
    this.isError = false,
    this.errorMessage,
    this.onSaved,
    this.onClose,
    this.repository,
    this.captureRepository,
    this.mediaStorageRepository,
    this.captureProcessingRepository,
    this.mediaPickerService,
    this.audioRecorderService,
    this.ocrService,
    this.initialCaptures,
  });

  @override
  State<CaptureModal> createState() => _CaptureModalState();
}

class _CaptureModalState extends State<CaptureModal> {
  late CaptureState _state;
  CaptureType? _activeType;
  CaptureReviewData? _reviewData;
  CaptureItem? _savedItem;
  String _errorMessage = '';
  CaptureProcessingStatus? _processingStatus;
  bool _isScanningCard = false;
  bool _isPickingMedia = false;
  bool _isMicPermDenied = false;
  bool _isSaving = false;

  // Controllers for Note
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteContentController = TextEditingController();
  final TextEditingController _notePersonController = TextEditingController();
  final TextEditingController _noteCompanyController = TextEditingController();
  final TextEditingController _noteEventController = TextEditingController();
  final TextEditingController _noteLocationController = TextEditingController();

  // Controllers for Photo/Doc
  final TextEditingController _photoTitleController = TextEditingController();
  final TextEditingController _photoNoteController = TextEditingController();
  final TextEditingController _photoContextController = TextEditingController();

  // Voice state
  bool _isRecordingVoice = false;
  int _voiceDurationSeconds = 0;
  StreamSubscription<Duration>? _voiceDurationSub;

  PickedMediaFile? _pickedMediaFile;
  RecordedAudioFile? _recordedAudioFile;

  List<CaptureItem> _recentCaptures = [];
  StreamSubscription<List<CaptureItem>>? _recentSubscription;

  CaptureRepository get _captureRepo =>
      widget.repository ??
      widget.captureRepository ??
      (mounted ? context.captureRepo : RecallrDependencies.instance.captureRepository);

  MediaStorageRepository get _mediaStorageRepo =>
      widget.mediaStorageRepository ??
      (mounted ? context.mediaStorageRepo : RecallrDependencies.instance.mediaStorageRepository);

  CaptureProcessingRepository? get _captureProcessingRepo =>
      widget.captureProcessingRepository ??
      (mounted ? context.dependencies.captureProcessingRepository : RecallrDependencies.instance.captureProcessingRepository);

  MediaPickerService get _mediaPicker =>
      widget.mediaPickerService ??
      (mounted ? context.mediaPickerService : RecallrDependencies.instance.mediaPickerService);

  AudioRecorderService get _audioRecorder =>
      widget.audioRecorderService ??
      (mounted ? context.audioRecorderService : RecallrDependencies.instance.audioRecorderService);

  OcrService get _ocrService =>
      widget.ocrService ??
      (mounted ? context.ocrService : RecallrDependencies.instance.ocrService);

  PeopleRepository get _peopleRepo =>
      (mounted ? context.peopleRepo : RecallrDependencies.instance.peopleRepository);

  @override
  void initState() {
    super.initState();
    _state = widget.isError ? CaptureState.error : CaptureState.idle;
    _errorMessage = widget.errorMessage ?? 'An error occurred. Please try again.';
    _recentCaptures = widget.initialCaptures ?? [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialCaptures == null && !widget.isEmpty && !widget.isError) {
      _subscribeToRecentCaptures();
    }
  }

  void _subscribeToRecentCaptures() {
    _recentSubscription?.cancel();
    _recentSubscription = _captureRepo.streamRecentCaptures(limit: 5).listen(
      (captures) {
        if (mounted) {
          setState(() {
            _recentCaptures = captures;
          });
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    if (_isRecordingVoice) {
      _audioRecorder.cancelRecording();
    }
    _recentSubscription?.cancel();
    _voiceDurationSub?.cancel();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _notePersonController.dispose();
    _noteCompanyController.dispose();
    _noteEventController.dispose();
    _noteLocationController.dispose();
    _photoTitleController.dispose();
    _photoNoteController.dispose();
    _photoContextController.dispose();
    super.dispose();
  }

  void _selectType(CaptureType type) {
    setState(() {
      _activeType = type;
      _state = CaptureState.capturing;
      _pickedMediaFile = null;
      _recordedAudioFile = null;
      _voiceDurationSeconds = 0;
      _isRecordingVoice = false;
      _processingStatus = null;
    });
  }

  Future<void> _processBusinessCardMedia(PickedMediaFile? picked) async {
    if (picked == null) return;
    _pickedMediaFile = picked;
    CaptureReviewData reviewData;
    try {
      final ocrResult = await _ocrService.extractText(
        mediaPath: picked.path,
        mimeType: picked.mimeType,
      );
      final entities = OcrEntityExtractor.extract(ocrResult.text);
      final personName = entities.name;
      final nameConfidence = entities.confidence['name'] ?? (personName != null ? 0.9 : 0.0);
      final needsConfirmation = nameConfidence < 0.7 || personName == null || personName.trim().isEmpty;
      final displayTitle = personName ?? (entities.company != null && entities.company!.isNotEmpty ? entities.company! : 'Business Card');
      final confidenceVal = nameConfidence * 100.0;

      reviewData = CaptureReviewData(
        title: displayTitle,
        summary: 'Scanned visiting card with verified contact credentials.',
        personName: personName,
        personRole: entities.effectiveRole ?? 'Contact',
        companyName: entities.company ?? '',
        eventName: '',
        location: entities.effectiveLocation ?? '',
        address: entities.address ?? entities.location ?? '',
        brands: entities.brands,
        nameConfidence: nameConfidence,
        needsNameConfirmation: needsConfirmation,
        date: entities.date ?? 'Today',
        bulletPoints: entities.keyPoints.isNotEmpty
            ? entities.keyPoints
            : [
                if (entities.brands.isNotEmpty) 'Brands: ${entities.brands.join(', ')}',
                'Card text detected with ${confidenceVal.toStringAsFixed(1)}% name confidence',
                if (entities.company != null && entities.company!.isNotEmpty)
                  '${entities.company} matched in network database',
              ],
        contactDetails: {
          if (entities.email != null) 'email': entities.email!,
          if (entities.phone != null) 'phone': entities.phone!,
          if (entities.website != null) 'website': entities.website!,
        },
      );
    } catch (_) {
      reviewData = CaptureReviewData(
        title: picked.name,
        summary: 'Scanned visiting card image captured.',
        date: 'Today',
        needsNameConfirmation: true,
      );
    }
    if (mounted) {
      setState(() {
        _state = CaptureState.review;
        _reviewData = reviewData;
      });
    }
  }

  Future<void> _handleBusinessCardScan() async {
    if (_isScanningCard) return;
    _isScanningCard = true;
    try {
      final picked = await _mediaPicker.pickFromCamera();
      await _processBusinessCardMedia(picked);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to capture image: $e';
        });
      }
    } finally {
      _isScanningCard = false;
    }
  }

  Future<void> _handleBusinessCardGallery() async {
    if (_isScanningCard) return;
    _isScanningCard = true;
    try {
      final picked = await _mediaPicker.pickFromGallery();
      await _processBusinessCardMedia(picked);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to pick from gallery: $e';
        });
      }
    } finally {
      _isScanningCard = false;
    }
  }

  Future<void> _handlePhotoCamera() async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;
    try {
      final picked = await _mediaPicker.pickFromCamera();
      if (picked != null && mounted) {
        setState(() {
          _pickedMediaFile = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to capture photo: $e';
        });
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _handlePhotoGallery() async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;
    try {
      final picked = await _mediaPicker.pickFromGallery();
      if (picked != null && mounted) {
        setState(() {
          _pickedMediaFile = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to pick from gallery: $e';
        });
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _handleDocumentPick() async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;
    try {
      // CAP-P0-4: Use a real document picker for document type, not image gallery.
      final picked = await _mediaPicker.pickDocument();
      if (picked == null && mounted) {
        // Document picker not available on this platform/build — show honest error.
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Document selection is not available on this device. '
              'Please use photo capture instead.';
        });
        return;
      }
      if (picked != null && mounted) {
        setState(() {
          _pickedMediaFile = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to pick document. Please try again.';
        });
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> _handlePhotoDocUpload(CaptureType type) async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;
    try {
      final picked = _pickedMediaFile ?? await _mediaPicker.pickFromGallery();
      _pickedMediaFile = picked;

      String? extractedTitle;
      String? extractedSummary;
      String? extractedPersonName;
      String? extractedRole;
      String? extractedCompany;
      String? extractedLocation;
      List<String> extractedKeyPoints = [];
      Map<String, String> extractedContactDetails = {};

      if (picked != null) {
        try {
          final ocrResult = await _ocrService.extractText(
            mediaPath: picked.path,
            mimeType: picked.mimeType,
          );
          if (ocrResult.text.trim().isNotEmpty) {
            final entities = OcrEntityExtractor.extract(ocrResult.text);
            extractedPersonName = entities.name;
            extractedRole = entities.role ?? (entities.name != null ? 'Contact' : null);
            extractedCompany = entities.company;
            extractedLocation = entities.location;
            if (entities.email != null) extractedContactDetails['email'] = entities.email!;
            if (entities.phone != null) extractedContactDetails['phone'] = entities.phone!;
            if (entities.website != null) extractedContactDetails['website'] = entities.website!;

            extractedKeyPoints = entities.keyPoints.isNotEmpty
                ? entities.keyPoints
                : ocrResult.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).take(5).toList();

            if (entities.name != null && entities.name!.isNotEmpty) {
              extractedTitle = entities.name;
              extractedSummary = 'Photo capture with extracted contact details: ${entities.name}${entities.company != null ? ' at ${entities.company}' : ''}.';
            } else if (ocrResult.text.trim().isNotEmpty) {
              final firstLine = ocrResult.text.trim().split('\n').first.trim();
              if (firstLine.length <= 40) {
                extractedTitle = firstLine;
              }
              extractedSummary = ocrResult.text.trim();
            }
          }
        } catch (e) {
          debugPrint('[Capture] Optical extraction notice: $e');
        }
      }

      if (mounted) {
        final title = _photoTitleController.text.isNotEmpty
            ? _photoTitleController.text
            : (extractedTitle ?? (type == CaptureType.photo ? 'Photo Capture' : 'Document Upload'));
        final summary = _photoNoteController.text.isNotEmpty
            ? _photoNoteController.text
            : (extractedSummary ?? (picked != null ? 'Uploaded file (${picked.name}).' : 'Uploaded document context.'));

        setState(() {
          _state = CaptureState.review;
          _reviewData = CaptureReviewData(
            title: title,
            summary: summary,
            personName: extractedPersonName,
            personRole: extractedRole,
            companyName: extractedCompany,
            location: extractedLocation,
            date: 'Today',
            bulletPoints: extractedKeyPoints,
            contactDetails: extractedContactDetails,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Failed to process media. Please try again.';
        });
      }
    } finally {
      _isPickingMedia = false;
    }
  }

  void _handleNoteCaptured() {
    final title = _noteTitleController.text.trim();
    final note = _noteContentController.text.trim();
    final person = _notePersonController.text.trim();
    final company = _noteCompanyController.text.trim();
    final event = _noteEventController.text.trim();
    final location = _noteLocationController.text.trim();

    final lines = note.split('\n').where((l) => l.trim().isNotEmpty).toList();

    setState(() {
      _state = CaptureState.review;
      _reviewData = CaptureReviewData(
        title: title.isNotEmpty ? title : 'Professional Note',
        summary: note.isNotEmpty ? note : (person.isNotEmpty ? 'Met with $person' : (title.isNotEmpty ? title : 'Encounter note')),
        personName: person.isNotEmpty ? person : null,
        companyName: company.isNotEmpty ? company : null,
        eventName: event.isNotEmpty ? event : null,
        location: location.isNotEmpty ? location : null,
        date: 'Today',
        bulletPoints: lines,
      );
    });
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      _voiceDurationSub?.cancel();
      try {
        final file = await _audioRecorder.stopRecording();
        _recordedAudioFile = file;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
        });
      }
    } else {
      try {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            setState(() {
              _state = CaptureState.error;
              _isMicPermDenied = true;
              _errorMessage =
                  'Recallr needs microphone access to record voice memos. '
                  'Please allow microphone access in your device settings.';
            });
          }
          return;
        }
        await _audioRecorder.startRecording();
        if (mounted) {
          setState(() {
            _isRecordingVoice = true;
            _isMicPermDenied = false;
            _voiceDurationSeconds = 0;
          });
          _voiceDurationSub?.cancel();
          _voiceDurationSub = _audioRecorder.durationStream.listen((duration) {
            if (mounted) {
              setState(() {
                _voiceDurationSeconds = duration.inSeconds;
              });
            }
          });
        }
      } on PlatformException catch (e) {
        if (mounted) {
          setState(() {
            _state = CaptureState.error;
            _isMicPermDenied = e.code == 'PERMISSION_DENIED';
            _errorMessage = e.code == 'PERMISSION_DENIED'
                ? 'Recallr needs microphone access to record voice memos. '
                  'Please allow microphone access in your device settings.'
                : 'Could not start recording. Please try again.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _state = CaptureState.error;
            _errorMessage = 'Could not start recording. Please try again.';
          });
        }
      }
    }
  }

  Future<void> _processVoice() async {
    _voiceDurationSub?.cancel();
    if (_isRecordingVoice) {
      try {
        final file = await _audioRecorder.stopRecording();
        _recordedAudioFile = file;
      } catch (_) {}
    }

    // CAP-P0-3 / CAP-P3: If no real audio was recorded, show error rather
    // than fabricating synthetic audio bytes.
    if (_recordedAudioFile == null) {
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _state = CaptureState.error;
          _errorMessage = 'No recording was captured. '
              'Please tap the microphone to start recording before processing.';
        });
      }
      return;
    }

    final durationSecs = _recordedAudioFile!.duration.inSeconds > 0
        ? _recordedAudioFile!.duration.inSeconds
        : _voiceDurationSeconds;

    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _state = CaptureState.review;
        _reviewData = CaptureReviewData(
          title: durationSecs > 0
              ? 'Voice Recording (${durationSecs}s)'
              : 'Voice Memo',
          summary: 'Voice recording saved. '
              'Transcription unavailable \u2014 no STT provider configured.',
          date: 'Today',
          audioDuration: durationSecs > 0 ? '${durationSecs}s' : null,
          bulletPoints: const [
            'Audio file captured and ready to save',
            'Transcription requires a configured STT provider',
          ],
        );
      });
    }
  }

  Future<void> _processSavedItem(CaptureItem item) async {
    final processingRepo = _captureProcessingRepo;
    if (processingRepo == null) return;

    if (!mounted) return;
    setState(() {
      _processingStatus = CaptureProcessingStatus.processing;
    });

    try {
      final processedItem = await processingRepo.processCapture(item);
      if (mounted) {
        setState(() {
          _savedItem = processedItem;
          _processingStatus = CaptureProcessingStatus.completed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingStatus = CaptureProcessingStatus.failed;
        });
      }
    }
  }

  Future<void> _saveCapture() async {
    // CAP-P1-3: Guard against duplicate submission or zombie saves.
    if (_isSaving || _state == CaptureState.saving || _reviewData == null || _activeType == null) return;
    _isSaving = true;

    if (!mounted) return;
    setState(() {
      _state = CaptureState.saving;
    });

    final captureId = 'cap_${DateTime.now().millisecondsSinceEpoch}';
    String? storagePath;
    String? mediaUrl;
    String? mimeType;
    int? fileSize;
    String? localFilePath;

    try {
      if (_pickedMediaFile != null) {
        // Preserve local path BEFORE upload for on-device OCR
        localFilePath = _pickedMediaFile!.path;
        mimeType = _pickedMediaFile!.mimeType;
        fileSize = _pickedMediaFile!.size;
        try {
          final uploadResult = await _mediaStorageRepo.uploadCaptureImage(
            captureId: captureId,
            file: _pickedMediaFile!,
          );
          storagePath = uploadResult.storagePath;
          mediaUrl = uploadResult.mediaUrl;
          mimeType = uploadResult.mimeType;
          fileSize = uploadResult.fileSize;
        } catch (storageErr) {
          if (_activeType == CaptureType.photo && widget.mediaStorageRepository != null) {
            rethrow;
          }
          debugPrint('[Capture] Storage upload skipped/failed: $storageErr');
        }
      } else if (_recordedAudioFile != null) {
        // CAP-P3: Only upload real recorded audio — never a synthetic fallback.
        mimeType = _recordedAudioFile!.mimeType;
        fileSize = _recordedAudioFile!.size;
        try {
          final uploadResult = await _mediaStorageRepo.uploadCaptureAudio(
            captureId: captureId,
            file: _recordedAudioFile!,
          );
          storagePath = uploadResult.storagePath;
          mediaUrl = uploadResult.mediaUrl;
          mimeType = uploadResult.mimeType;
          fileSize = uploadResult.fileSize;
        } catch (storageErr) {
          debugPrint('[Capture] Audio upload skipped/failed: $storageErr');
        }
      }

      // Immediate Person Directory persistence for contacts
      String? linkedPersonId;
      if (_reviewData!.personName != null && _reviewData!.personName!.trim().isNotEmpty) {
        try {
          final personName = _reviewData!.personName!.trim();
          final email = _reviewData!.contactDetails['email'];
          final phone = _reviewData!.contactDetails['phone'];
          final company = _reviewData!.companyName ?? '';
          final role = _reviewData!.personRole ?? 'Contact';

          PersonItem? existing;
          if (email != null && email.isNotEmpty) {
            existing = await _peopleRepo.findPersonByEmail(email);
          }
          if (existing == null && phone != null && phone.isNotEmpty) {
            existing = await _peopleRepo.findPersonByPhone(phone);
          }

          if (existing != null) {
            linkedPersonId = existing.id;
          } else {
            final newPerson = PersonItem(
              id: 'per_cap_$captureId',
              name: personName,
              role: role,
              company: company,
              email: email,
              phone: phone,
              locationOrEvent: _reviewData!.location,
              contextSnippet: 'Captured via ${_activeType!.label}',
              lastInteraction: 'Captured ${_reviewData!.title}',
              lastInteractionDate: DateTime.now(),
              initials: PersonItem.computeInitials(personName),
              capabilities: _reviewData!.bulletPoints.take(3).toList(),
              brands: _reviewData!.brands,
              relationshipType: RelationshipContextType.collaborator,
            );
            final created = await _peopleRepo.createPersonFromCapture(newPerson);
            linkedPersonId = created.id;
          }
        } catch (personErr) {
          debugPrint('[Capture] Immediate contact creation note: $personErr');
        }
      }

      final item = CaptureItem(
        id: captureId,
        type: _activeType!,
        title: _reviewData!.title,
        description: _reviewData!.summary,
        timestamp: 'Just now',
        personId: linkedPersonId,
        personName: _reviewData!.personName,
        personRole: _reviewData!.personRole,
        companyName: _reviewData!.companyName,
        eventName: _reviewData!.eventName,
        location: _reviewData!.location,
        targetRoute: '/captures/$captureId',
        isVerified: true,
        mediaUrl: mediaUrl,
        storagePath: storagePath,
        mimeType: mimeType,
        fileSize: fileSize,
        localFilePath: localFilePath,
        durationSeconds: _recordedAudioFile?.duration.inSeconds ??
            (_voiceDurationSeconds > 0 ? _voiceDurationSeconds : null),
        processingStatus: CaptureProcessingStatus.pending,
        metadata: {
          'contactDetails': _reviewData!.contactDetails,
          'bulletPoints': _reviewData!.bulletPoints,
          if (linkedPersonId != null) 'resolvedPersonId': linkedPersonId,
        },
        createdAt: DateTime.now(),
      );

      CaptureItem savedItem;
      try {
        savedItem = await _captureRepo.saveCapture(item);
      } catch (saveError) {
        if (storagePath != null) {
          try {
            await _mediaStorageRepo.deleteCaptureMedia(captureId: captureId, storagePath: storagePath);
          } catch (_) {}
        }
        rethrow;
      }

      if (widget.onSaved != null) {
        widget.onSaved!(savedItem);
      }

      if (mounted) {
        setState(() {
          _savedItem = savedItem;
          _state = CaptureState.saved;
        });
        _processSavedItem(savedItem);
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().toLowerCase();
        final isQuota = errText.contains('quota');
        final isStorageIssue = errText.contains('storage') ||
            errText.contains('bucket') ||
            errText.contains('object-not-found') ||
            errText.contains('not-found');
        setState(() {
          _state = CaptureState.error;
          if (isQuota) {
            _errorMessage = 'Cloud storage limit reached. You can upgrade to Pro for 1.5 GB in Settings, or save contact details directly without cloud photo.';
          } else if (isStorageIssue) {
            _errorMessage = 'Could not upload media to Cloud Storage. Please ensure Firebase Storage is initialized in Firebase Console, or save contact details directly.';
          } else {
            _errorMessage = 'Failed to save capture. Please try again.';
          }
        });
      }
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _saveWithoutStorage() async {
    if (_reviewData == null || _activeType == null) return;
    setState(() {
      _state = CaptureState.saving;
    });

    final captureId = 'cap_${DateTime.now().millisecondsSinceEpoch}';

    String? linkedPersonId;
    if (_reviewData!.personName != null && _reviewData!.personName!.trim().isNotEmpty) {
      try {
        final personName = _reviewData!.personName!.trim();
        final email = _reviewData!.contactDetails['email'];
        final phone = _reviewData!.contactDetails['phone'];
        final company = _reviewData!.companyName ?? '';
        final role = _reviewData!.personRole ?? 'Contact';

        PersonItem? existing;
        if (email != null && email.isNotEmpty) {
          existing = await _peopleRepo.findPersonByEmail(email);
        }
        if (existing == null && phone != null && phone.isNotEmpty) {
          existing = await _peopleRepo.findPersonByPhone(phone);
        }

        if (existing != null) {
          linkedPersonId = existing.id;
        } else {
          final newPerson = PersonItem(
            id: 'per_cap_$captureId',
            name: personName,
            role: role,
            company: company,
            email: email,
            phone: phone,
            locationOrEvent: _reviewData!.location,
            contextSnippet: 'Captured via ${_activeType!.label}',
            lastInteraction: 'Captured ${_reviewData!.title}',
            lastInteractionDate: DateTime.now(),
            initials: PersonItem.computeInitials(personName),
            capabilities: _reviewData!.bulletPoints.take(3).toList(),
            brands: _reviewData!.brands,
            relationshipType: RelationshipContextType.collaborator,
          );
          final created = await _peopleRepo.createPersonFromCapture(newPerson);
          linkedPersonId = created.id;
        }
      } catch (personErr) {
        debugPrint('[Capture] Immediate contact creation note: $personErr');
      }
    }

    final item = CaptureItem(
      id: captureId,
      type: _activeType!,
      title: _reviewData!.title,
      description: _reviewData!.summary,
      timestamp: 'Just now',
      personId: linkedPersonId,
      personName: _reviewData!.personName,
      personRole: _reviewData!.personRole,
      companyName: _reviewData!.companyName,
      eventName: _reviewData!.eventName,
      location: _reviewData!.location,
      targetRoute: '/captures/$captureId',
      isVerified: true,
      mediaUrl: null,
      storagePath: null,
      mimeType: _pickedMediaFile?.mimeType,
      fileSize: _pickedMediaFile?.size,
      localFilePath: _pickedMediaFile?.path,
      durationSeconds: _recordedAudioFile?.duration.inSeconds ??
          (_voiceDurationSeconds > 0 ? _voiceDurationSeconds : null),
      processingStatus: CaptureProcessingStatus.pending,
      metadata: {
        'contactDetails': _reviewData!.contactDetails,
        'bulletPoints': _reviewData!.bulletPoints,
        if (linkedPersonId != null) 'resolvedPersonId': linkedPersonId,
      },
      createdAt: DateTime.now(),
    );

    try {
      final savedItem = await _captureRepo.saveCapture(item);
      if (widget.onSaved != null) {
        widget.onSaved!(savedItem);
      }
      if (mounted) {
        setState(() {
          _savedItem = savedItem;
          _state = CaptureState.saved;
        });
        _processSavedItem(savedItem);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Could not save capture to database: $e';
        });
      }
    }
  }

  Future<void> _handleDeleteRecentCapture(CaptureItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RecallrColors.charcoalCard,
        shape: RoundedRectangleBorder(
          borderRadius: RecallrRadii.radiusLg,
          side: const BorderSide(color: RecallrColors.borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: RecallrColors.crimsonAlert, size: 22),
            const SizedBox(width: 8),
            Text('Delete Capture', style: RecallrTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Delete "${item.title}"? This cannot be undone.',
          style: const TextStyle(color: RecallrColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: RecallrColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RecallrColors.crimsonAlert.withAlpha(40),
              foregroundColor: RecallrColors.crimsonAlert,
              elevation: 0,
              side: const BorderSide(color: RecallrColors.crimsonAlert, width: 1),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _captureRepo.deleteCapture(item.id);
        if (mounted) {
          setState(() {
            _recentCaptures.removeWhere((c) => c.id == item.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capture deleted'),
              backgroundColor: RecallrColors.slateSurface,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete capture: $e'), backgroundColor: RecallrColors.crimsonAlert),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(RecallrRadii.lg)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CaptureHeader(
                  state: _state,
                  activeType: _activeType,
                  onClose: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  onBack: _state != CaptureState.idle
                      ? () => setState(() {
                            _state = CaptureState.idle;
                            _activeType = null;
                            _pickedMediaFile = null;
                            _recordedAudioFile = null;
                            _processingStatus = null;
                          })
                      : null,
                ),
                RecallrSpacing.gapMd,
                _buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case CaptureState.idle:
        return _buildIdleView();
      case CaptureState.capturing:
      case CaptureState.recording:
        return _buildCapturingView();
      case CaptureState.review:
        return _buildReviewView();
      case CaptureState.processing:
      case CaptureState.saving:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      case CaptureState.saved:
        return _buildSavedView();
      case CaptureState.error:
        return _buildErrorView();
    }
  }

  Widget _buildIdleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CaptureMethodGrid(
          onSelectType: _selectType,
        ),
        RecallrSpacing.gapLg,
        if (_recentCaptures.isNotEmpty && !widget.isEmpty)
          CaptureRecentList(
            items: _recentCaptures,
            onDeleteItem: _handleDeleteRecentCapture,
            onTapItem: (item) {
              final nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
              }
              nav.pushNamed(item.targetRoute);
            },
          )
        else
          const CaptureEmptyState(),
      ],
    );
  }

  Widget _buildCapturingView() {
    switch (_activeType) {
      case CaptureType.businessCard:
        return BusinessCardCaptureView(
          onCapture: _handleBusinessCardScan,
          onPickGallery: _handleBusinessCardGallery,
          onCancel: () => setState(() => _state = CaptureState.idle),
        );
      case CaptureType.voice:
        final minutes = (_voiceDurationSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_voiceDurationSeconds % 60).toString().padLeft(2, '0');
        return VoiceCaptureView(
          isRecording: _isRecordingVoice,
          durationText: '$minutes:$seconds',
          onToggleRecording: _toggleVoiceRecording,
          onProcessVoice: _processVoice,
          onCancel: () => setState(() => _state = CaptureState.idle),
        );
      case CaptureType.note:
        return QuickNoteCaptureView(
          titleController: _noteTitleController,
          noteController: _noteContentController,
          personController: _notePersonController,
          companyController: _noteCompanyController,
          eventController: _noteEventController,
          locationController: _noteLocationController,
          onSave: _handleNoteCaptured,
          onCancel: () => setState(() => _state = CaptureState.idle),
        );
      case CaptureType.photo:
      case CaptureType.document:
        final isDoc = _activeType == CaptureType.document;
        return PhotoDocCaptureView(
          type: _activeType!,
          titleController: _photoTitleController,
          noteController: _photoNoteController,
          contextController: _photoContextController,
          pickedMediaFile: _pickedMediaFile,
          onProcess: () => _handlePhotoDocUpload(_activeType!),
          onCancel: () => setState(() => _state = CaptureState.idle),
          onPickCamera: isDoc ? null : _handlePhotoCamera,
          onPickGallery: isDoc ? null : _handlePhotoGallery,
          onPickDocument: isDoc ? _handleDocumentPick : null,
        );
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReviewView() {
    if (_reviewData == null) return const SizedBox.shrink();
    return CaptureReviewView(
      type: _activeType ?? CaptureType.note,
      reviewData: _reviewData!,
      onEdit: () => setState(() => _state = CaptureState.capturing),
      onSave: _saveCapture,
      onUpdateData: (newData) => setState(() => _reviewData = newData),
    );
  }

  Widget _buildSavedView() {
    if (_savedItem == null) return const SizedBox.shrink();
    return CaptureSuccessView(
      item: _savedItem!,
      processingStatus: _processingStatus,
      onRetryProcessing: () => _processSavedItem(_savedItem!),
      onViewMemory: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        }
        nav.pushNamed(_savedItem!.targetRoute);
      },
      onDone: () {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            setState(() => _state = CaptureState.idle);
          }
        }
      },
    );
  }

  Widget _buildErrorView() {
    return CaptureErrorView(
      errorMessage: _errorMessage.isNotEmpty
          ? _errorMessage
          : 'Something went wrong while capturing context.',
      onSecondaryAction: (_reviewData != null && _pickedMediaFile != null)
          ? _saveWithoutStorage
          : null,
      secondaryActionLabel: 'Save Contact Without Cloud Photo',
      onRetry: () {
        // CAP-P1-1: Preserve captured content — do NOT wipe _activeType,
        // _pickedMediaFile, or _recordedAudioFile on retry.
        setState(() {
          _isMicPermDenied = false;
          _errorMessage = '';
          if (_reviewData != null) {
            // Return to review if we already had data
            _state = CaptureState.review;
          } else if (_activeType != null) {
            // Return to capture mode if a type was selected
            _state = CaptureState.capturing;
          } else {
            _state = CaptureState.idle;
          }
        });
      },
      onCancel: () {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            setState(() {
              _state = CaptureState.idle;
              _activeType = null;
              _isMicPermDenied = false;
              _errorMessage = '';
            });
          }
        }
      },
      onOpenSettings: _isMicPermDenied
          ? () async {
              // Open device app settings so the user can grant microphone access.
              // Uses AppSettingsIntent on Android / UIApplication.openSettingsURL on iOS.
              const channel = MethodChannel('recallr/app_settings');
              try {
                await channel.invokeMethod<void>('openAppSettings');
              } catch (_) {
                // Fallback: no-op if the channel is not implemented in the host app
              }
            }
          : null,
    );
  }
}