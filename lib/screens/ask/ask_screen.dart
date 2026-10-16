import 'package:flutter/material.dart';
import '../../core/di/recallr_dependencies.dart';
import '../../core/security/security.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/firestore/firestore_memory_retrieval_repository.dart';
import '../../features/ask/models/ai_answer_models.dart';
import '../../features/ask/models/ask_mock_data.dart';
import '../../features/ask/models/ask_models.dart';
import '../../features/ask/models/memory_retrieval_models.dart';
import '../../features/ask/widgets/ask_empty_state.dart';
import '../../features/ask/widgets/ask_header.dart';
import '../../features/ask/widgets/ask_loading_state.dart';
import '../../features/ask/widgets/ask_no_answer_state.dart';
import '../../features/ask/widgets/grounded_answer_card.dart';
import '../../features/ask/widgets/memory_sources_section.dart';
import '../../features/ask/widgets/people_mentions.dart';
import '../../features/ask/widgets/question_input.dart';
import '../../features/ask/widgets/recent_questions.dart';
import '../../features/ask/widgets/suggested_questions.dart';
import '../capture/capture_modal.dart';

/// Phase 07, 13E & 13G: Ask / Grounded Memory Engine Screen.
/// Answers: "What do I already know about my professional network?"
/// Grounded strictly in personal memory without synthetic mock fallbacks.
class AskScreen extends StatefulWidget {
  final String? initialQuery;
  final bool isEmpty;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;
  final VoidCallback? onCaptureFirstEncounter;
  final List<String>? initialSuggestions;
  final List<String>? initialRecentQuestions;

  const AskScreen({
    super.key,
    this.initialQuery,
    this.isEmpty = false,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
    this.onCaptureFirstEncounter,
    this.initialSuggestions,
    this.initialRecentQuestions,
  });

  static const List<String> defaultSuggestions = MockMemoryEngine.suggestedQuestions;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  late TextEditingController _questionController;
  late bool _isLoading;
  late bool _isError;
  String? _activeErrorMessage;
  AiErrorType _activeErrorType = AiErrorType.none;
  bool _hasQueried = false;
  GroundedAnswer? _currentAnswer;
  late final List<String> _recentQuestions;
  final List<ConversationTurn> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
    _isError = widget.isError;
    _recentQuestions = widget.initialRecentQuestions != null
        ? List.from(widget.initialRecentQuestions!)
        : (RecallrDependencies.instance.memoryRetrievalRepository is FirestoreMemoryRetrievalRepository
            ? <String>[]
            : List.from(MockMemoryEngine.recentQuestions));
    _questionController = TextEditingController(text: widget.initialQuery ?? '');

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performAsk(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty && !_hasQueried && _questionController.text.isEmpty) {
      _questionController.text = args;
      _performAsk(args);
    }
  }

  @override
  void didUpdateWidget(covariant AskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading ||
        oldWidget.isError != widget.isError ||
        oldWidget.initialQuery != widget.initialQuery) {
      setState(() {
        _isLoading = widget.isLoading;
        _isError = widget.isError;
      });
      if (widget.initialQuery != null && widget.initialQuery != oldWidget.initialQuery) {
        _performAsk(widget.initialQuery!);
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _performAsk(String question) async {
    if (_isLoading) return;
    final cleanQuestion = InputSanitizer.sanitizeQuery(question);
    if (cleanQuestion.isEmpty) return;

    setState(() {
      _questionController.text = cleanQuestion;
      _isLoading = true;
      _isError = false;
      _activeErrorMessage = null;
      _activeErrorType = AiErrorType.none;
      _hasQueried = true;
    });

    if (!_recentQuestions.contains(cleanQuestion)) {
      _recentQuestions.insert(0, cleanQuestion);
      if (_recentQuestions.length > 5) {
        _recentQuestions.removeLast();
      }
    }

    GroundedAnswer? result;
    AiErrorType errorType = AiErrorType.none;
    String? errorMessage;

    try {
      final answerService = context.dependencies.aiAnswerService;
      
      // Pass bounded recent conversation turns (last 5 turns)
      final historyTurns = _conversationHistory
          .where((turn) => turn.answer != null)
          .toList();
      final boundedHistory = historyTurns.length > 5
          ? historyTurns.sublist(historyTurns.length - 5)
          : historyTurns;

      final turnsPayload = boundedHistory.map((t) {
        return AiAnswerTurn(
          id: t.id,
          query: t.question,
          answer: t.answer!.answerText,
          timestamp: t.timestamp,
        );
      }).toList();

      final aiAnswer = await answerService.answer(
        AiAnswerRequest(
          query: cleanQuestion,
          conversationHistory: turnsPayload.isNotEmpty ? turnsPayload : null,
        ),
      );

      if (aiAnswer.status == AiAnswerStatus.failed) {
        errorType = aiAnswer.errorType != AiErrorType.none
            ? aiAnswer.errorType
            : AiErrorType.aiUnavailable;
        errorMessage = aiAnswer.errorMessage ?? errorType.defaultMessage;
      } else if (aiAnswer.status == AiAnswerStatus.empty) {
        result = null;
        errorType = AiErrorType.insufficientEvidence;
      } else {
        final sources = aiAnswer.evidence.map((ev) {
          IconData icon = Icons.psychology_outlined;
          if (ev.sourceType == MemorySourceType.person) icon = Icons.person_outline;
          if (ev.sourceType == MemorySourceType.activity) icon = Icons.event_note_outlined;
          if (ev.sourceType == MemorySourceType.followUp) icon = Icons.task_alt_outlined;
          if (ev.sourceType == MemorySourceType.capture) icon = Icons.document_scanner_outlined;

          return MemorySource(
            id: ev.sourceId,
            sourceType: ev.sourceType.label,
            icon: icon,
            personName: ev.personName ?? 'Contact',
            personRole: ev.title,
            company: '',
            date: ev.timestamp ?? 'Recent',
            excerpt: ev.content,
            isVerified: ev.relevanceScore >= 0.7,
            targetRoute: ev.targetRoute,
          );
        }).toList();

        result = GroundedAnswer(
          queryId: 'ans_${DateTime.now().millisecondsSinceEpoch}',
          queryText: cleanQuestion,
          answerText: aiAnswer.answer,
          metadata: GroundingMetadata(
            memoryCount: aiAnswer.evidence.length,
            personCount: aiAnswer.mentionedPeople.length,
            groundingSummary: 'Grounded in ${aiAnswer.evidence.length} memories',
          ),
          relatedPeople: aiAnswer.mentionedPeople,
          sources: sources,
          followUpSuggestions: aiAnswer.suggestedActions,
        );
      }
    } catch (e) {
      result = null;
      errorType = AiErrorType.networkUnavailable;
      errorMessage = e.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentAnswer = result;
        _activeErrorType = errorType;
        _activeErrorMessage = errorMessage;

        if (errorType != AiErrorType.none && errorType != AiErrorType.insufficientEvidence) {
          _isError = true;
        }

        if (!_recentQuestions.contains(cleanQuestion)) {
          _recentQuestions.insert(0, cleanQuestion);
          if (_recentQuestions.length > 5) {
            _recentQuestions.removeLast();
          }
        }
        _conversationHistory.add(
          ConversationTurn(
            id: 'turn_${DateTime.now().millisecondsSinceEpoch}',
            question: cleanQuestion,
            answer: result,
            timestamp: DateTime.now(),
          ),
        );
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeAt(0);
        }
        // Memory optimization: Prune heavy source/evidence trees in older turns
        if (_conversationHistory.length > 10) {
          for (int i = 0; i < _conversationHistory.length - 10; i++) {
            final turn = _conversationHistory[i];
            if (turn.answer != null && turn.answer!.sources.isNotEmpty) {
              _conversationHistory[i] = ConversationTurn(
                id: turn.id,
                question: turn.question,
                answer: GroundedAnswer(
                  queryId: turn.answer!.queryId,
                  queryText: turn.answer!.queryText,
                  answerText: turn.answer!.answerText,
                  metadata: turn.answer!.metadata,
                  relatedPeople: turn.answer!.relatedPeople,
                  sources: const [], // Pruned to free heap memory
                  followUpSuggestions: turn.answer!.followUpSuggestions,
                ),
                timestamp: turn.timestamp,
              );
            }
          }
        }
      });
    }
  }

  void clearConversation() {
    setState(() {
      _questionController.clear();
      _hasQueried = false;
      _currentAnswer = null;
      _isLoading = false;
      _isError = false;
      _activeErrorMessage = null;
      _activeErrorType = AiErrorType.none;
      _conversationHistory.clear();
    });
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      if (_questionController.text.isNotEmpty) {
        _performAsk(_questionController.text);
      } else {
        setState(() {
          _isError = false;
          _activeErrorMessage = null;
          _activeErrorType = AiErrorType.none;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      final defaultMsg = _activeErrorType != AiErrorType.none
          ? _activeErrorType.defaultMessage
          : "We couldn't query your memory network. Please check your connection and try again.";
      final displayMsg = _activeErrorMessage != null && _activeErrorMessage!.isNotEmpty
          ? _activeErrorMessage!
          : defaultMsg;

      return Center(
        child: Padding(
          padding: RecallrSpacing.pagePadding,
          child: RecallrErrorState(
            message: displayMsg,
            onRetry: _handleRetry,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth > 1100 ? 1040 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: RecallrSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AskHeader(),
                        RecallrSpacing.gapLg,
                        if (_isLoading) ...[
                          const AskLoadingState(),
                          RecallrSpacing.gapLg,
                        ] else if (_hasQueried) ...[
                          if (_currentAnswer != null) ...[
                            GroundedAnswerCard(
                              answer: _currentAnswer!,
                              onFollowUpSelected: _performAsk,
                              onNewQuestion: clearConversation,
                            ),
                            RecallrSpacing.gapLg,
                            if (_currentAnswer!.relatedPeople.isNotEmpty) ...[
                              PeopleMentions(
                                people: _currentAnswer!.relatedPeople,
                              ),
                              RecallrSpacing.gapLg,
                            ],
                            if (_currentAnswer!.sources.isNotEmpty) ...[
                              MemorySourcesSection(sources: _currentAnswer!.sources),
                              RecallrSpacing.gapLg,
                            ],
                          ] else ...[
                            AskNoAnswerState(
                              question: _questionController.text,
                              onSuggestionSelected: _performAsk,
                            ),
                            RecallrSpacing.gapLg,
                          ],
                        ] else ...[
                          if (widget.isEmpty) ...[
                            AskEmptyState(
                              onCapture: widget.onCaptureFirstEncounter ?? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CaptureModal(),
                                );
                              },
                            ),
                          ] else ...[
                            SuggestedQuestions(
                              suggestions: widget.initialSuggestions ??
                                  (RecallrDependencies.instance.memoryRetrievalRepository is FirestoreMemoryRetrievalRepository
                                      ? const [
                                          'Who did I meet recently?',
                                          'What commitments did I make this week?',
                                          'Summarize my recent conversations',
                                          'Which founders or leads should I follow up with?',
                                        ]
                                      : AskScreen.defaultSuggestions),
                              onSelected: _performAsk,
                            ),
                            RecallrSpacing.gapLg,
                            if (_recentQuestions.isNotEmpty) ...[
                              RecentQuestions(
                                questions: _recentQuestions,
                                onSelected: _performAsk,
                              ),
                              RecallrSpacing.gapLg,
                            ],
                          ],
                        ],
                        const SizedBox(height: 80.0),
                      ],
                    ),
                  ),
                ),
                QuestionInput(
                  controller: _questionController,
                  isLoading: _isLoading,
                  onSubmitted: _performAsk,
                  onClear: () {
                    _questionController.clear();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}