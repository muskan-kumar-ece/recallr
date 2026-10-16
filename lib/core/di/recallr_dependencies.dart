import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import '../../data/firestore/firestore_activity_repository.dart';
import '../../data/firestore/firestore_capture_processing_repository.dart';
import '../../data/firestore/firestore_capture_repository.dart';
import '../../data/firestore/firestore_follow_up_repository.dart';
import '../../data/firestore/firestore_people_repository.dart';
import '../../data/firestore/firestore_person_detail_repository.dart';
import '../../data/mock/mock_activity_repository.dart';
import '../../data/mock/mock_capture_processing_repository.dart';
import '../../data/mock/mock_capture_repository.dart';
import '../../data/mock/mock_follow_up_repository.dart';
import '../../data/mock/mock_media_storage_repository.dart';
import '../../data/mock/mock_people_repository.dart';
import '../../data/mock/mock_person_detail_repository.dart';
import '../../data/storage/firebase_media_storage_repository.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/capture_processing_repository.dart';
import '../../repositories/capture_repository.dart';
import '../../repositories/follow_up_repository.dart';
import '../../repositories/media_storage_repository.dart';
import '../../repositories/people_repository.dart';
import '../../repositories/person_detail_repository.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/capture_processing_service.dart';
import '../../services/entity_resolution_service.dart';
import '../../services/media_picker_service.dart';
import '../../data/firestore/firestore_memory_retrieval_repository.dart';
import '../../data/mock/mock_gemini_ai_provider.dart';
import '../../data/mock/mock_memory_retrieval_repository.dart';
import '../../repositories/memory_retrieval_repository.dart';
import '../../services/ai/ai_answer_generator.dart';
import '../../services/ai/ai_answer_service.dart';
import '../../services/ai/answer_grounding_service.dart';
import '../../services/ai/deterministic_ai_answer_generator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/ai/gemini/callable_functions_gemini_ai_provider.dart';
import '../../services/ai/gemini/gemini_ai_configuration.dart';
import '../../services/ai/gemini/gemini_ai_provider.dart';
import '../../services/ai/gemini/gemini_grounded_answer_generator.dart';
import '../../services/ai/gemini/gemini_prompt_builder.dart';
import '../../services/ai/gemini/gemini_response_parser.dart';
import '../../services/ai/gemini/google_sdk_gemini_ai_provider.dart';
import '../../services/ai/gemini/grounded_answer_validator.dart';
import '../../services/mock_capture_processing_service.dart';
import '../../services/mock_entity_resolution_service.dart';
import '../../services/mock_relationship_memory_service.dart';
import '../../services/ocr/mlkit_ocr_service.dart';
import '../../services/ocr/mock_ocr_service.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/relationship/relationship_intelligence_service.dart';
import '../../services/relationship/relationship_action_engine.dart';
import '../../services/relationship/relationship_action_priority_calculator.dart';
import '../../services/relationship/relationship_attention_calculator.dart';
import '../../services/relationship/relationship_attention_engine.dart';
import '../../services/relationship/relationship_attention_priority_calculator.dart';
import '../../services/relationship/network_health_calculator.dart';
import '../../services/relationship/network_trend_calculator.dart';
import '../../services/relationship/network_insight_generator.dart';
import '../../services/relationship/network_intelligence_service.dart';
import '../../services/relationship/relationship_cadence_calculator.dart';
import '../../services/relationship/relationship_velocity_calculator.dart';
import '../../services/relationship/relationship_evolution_classifier.dart';
import '../../services/relationship/relationship_momentum_engine.dart';
import '../../services/relationship/relationship_momentum_service.dart';
import '../../services/relationship/network_connection_calculator.dart';
import '../../services/relationship/network_cluster_detector.dart';
import '../../services/relationship/network_pattern_engine.dart';
import '../../services/relationship/network_connection_intelligence_service.dart';
import '../../services/relationship/relationship_intelligence_consistency_validator.dart';
import '../../services/relationship/unified_relationship_intelligence_service.dart';
import '../../services/relationship/unified_relationship_ranking.dart';

import '../../services/relationship/relationship_state_classifier.dart';
import '../../services/relationship/relationship_strength_calculator.dart';
import '../../services/relationship_memory_service.dart';
import '../../services/retrieval/memory_retrieval_service.dart';
import '../../services/retrieval/mock_memory_retrieval_service.dart';
import '../../services/retrieval/relationship_context_assembler.dart';

import '../observability/observability.dart';

/// Central dependency container for Recallr repositories and hardware services.
/// Decouples UI screens from concrete Firestore/ML/Mock implementations.
class RecallrDependencies {
  final PeopleRepository peopleRepository;
  final PersonDetailRepository personDetailRepository;
  final ActivityRepository activityRepository;
  final FollowUpRepository followUpRepository;
  final CaptureRepository captureRepository;
  final MediaStorageRepository mediaStorageRepository;
  final MediaPickerService mediaPickerService;
  final AudioRecorderService audioRecorderService;
  final CaptureProcessingRepository captureProcessingRepository;
  final CaptureProcessingService captureProcessingService;
  final OcrService ocrService;
  final EntityResolutionService entityResolutionService;
  final RelationshipMemoryService relationshipMemoryService;
  final MemoryRetrievalRepository memoryRetrievalRepository;
  final RelationshipContextAssembler relationshipContextAssembler;
  final MemoryRetrievalService memoryRetrievalService;
  final AiAnswerGenerator aiAnswerGenerator;
  final AnswerGroundingService answerGroundingService;
  final AiAnswerService aiAnswerService;
  final GeminiAiConfiguration geminiAiConfiguration;
  final GeminiAiProvider geminiAiProvider;
  final GeminiPromptBuilder geminiPromptBuilder;
  final GeminiResponseParser geminiResponseParser;
  final GroundedAnswerValidator groundedAnswerValidator;
  final RelationshipStrengthCalculator relationshipStrengthCalculator;
  final RelationshipStateClassifier relationshipStateClassifier;
  final RelationshipIntelligenceService relationshipIntelligenceService;
  final RelationshipActionPriorityCalculator relationshipActionPriorityCalculator;
  final RelationshipActionEngine relationshipActionEngine;
  final RelationshipAttentionCalculator relationshipAttentionCalculator;
  final RelationshipAttentionPriorityCalculator relationshipAttentionPriorityCalculator;
  final RelationshipAttentionEngine relationshipAttentionEngine;
  final NetworkHealthCalculator networkHealthCalculator;
  final NetworkTrendCalculator networkTrendCalculator;
  final NetworkInsightGenerator networkInsightGenerator;
  final NetworkIntelligenceService networkIntelligenceService;
  final RelationshipCadenceCalculator relationshipCadenceCalculator;
  final RelationshipVelocityCalculator relationshipVelocityCalculator;
  final RelationshipEvolutionClassifier relationshipEvolutionClassifier;
  final RelationshipMomentumEngine relationshipMomentumEngine;
  final RelationshipMomentumService relationshipMomentumService;
  final NetworkConnectionCalculator networkConnectionCalculator;
  final NetworkClusterDetector networkClusterDetector;
  final NetworkPatternEngine networkPatternEngine;
  final NetworkConnectionIntelligenceService networkConnectionIntelligenceService;
  final UnifiedRelationshipIntelligenceService unifiedRelationshipIntelligenceService;
  final RelationshipIntelligenceConsistencyValidator relationshipIntelligenceConsistencyValidator;
  final UnifiedRelationshipRanking unifiedRelationshipRanking;
  final CrashReportingService crashReportingService;
  final TelemetryService telemetryService;
  final PerformanceTracker performanceTracker;

  RecallrDependencies({
    required this.peopleRepository,
    required this.personDetailRepository,
    required this.activityRepository,
    required this.followUpRepository,
    required this.captureRepository,
    MediaStorageRepository? mediaStorageRepository,
    MediaPickerService? mediaPickerService,
    AudioRecorderService? audioRecorderService,
    CaptureProcessingRepository? captureProcessingRepository,
    CaptureProcessingService? captureProcessingService,
    OcrService? ocrService,
    EntityResolutionService? entityResolutionService,
    RelationshipMemoryService? relationshipMemoryService,
    MemoryRetrievalRepository? memoryRetrievalRepository,
    RelationshipContextAssembler? relationshipContextAssembler,
    MemoryRetrievalService? memoryRetrievalService,
    AiAnswerGenerator? aiAnswerGenerator,
    AnswerGroundingService? answerGroundingService,
    AiAnswerService? aiAnswerService,
    GeminiAiConfiguration? geminiAiConfiguration,
    GeminiAiProvider? geminiAiProvider,
    GeminiPromptBuilder? geminiPromptBuilder,
    GeminiResponseParser? geminiResponseParser,
    GroundedAnswerValidator? groundedAnswerValidator,
    RelationshipStrengthCalculator? relationshipStrengthCalculator,
    RelationshipStateClassifier? relationshipStateClassifier,
    RelationshipIntelligenceService? relationshipIntelligenceService,
    RelationshipActionPriorityCalculator? relationshipActionPriorityCalculator,
    RelationshipActionEngine? relationshipActionEngine,
    RelationshipAttentionCalculator? relationshipAttentionCalculator,
    RelationshipAttentionPriorityCalculator? relationshipAttentionPriorityCalculator,
    RelationshipAttentionEngine? relationshipAttentionEngine,
    NetworkHealthCalculator? networkHealthCalculator,
    NetworkTrendCalculator? networkTrendCalculator,
    NetworkInsightGenerator? networkInsightGenerator,
    NetworkIntelligenceService? networkIntelligenceService,
    RelationshipCadenceCalculator? relationshipCadenceCalculator,
    RelationshipVelocityCalculator? relationshipVelocityCalculator,
    RelationshipEvolutionClassifier? relationshipEvolutionClassifier,
    RelationshipMomentumEngine? relationshipMomentumEngine,
    RelationshipMomentumService? relationshipMomentumService,
    NetworkConnectionCalculator? networkConnectionCalculator,
    NetworkClusterDetector? networkClusterDetector,
    NetworkPatternEngine? networkPatternEngine,
    NetworkConnectionIntelligenceService? networkConnectionIntelligenceService,
    UnifiedRelationshipIntelligenceService? unifiedRelationshipIntelligenceService,
    RelationshipIntelligenceConsistencyValidator? relationshipIntelligenceConsistencyValidator,
    UnifiedRelationshipRanking? unifiedRelationshipRanking,
    CrashReportingService? crashReportingService,
    TelemetryService? telemetryService,
    PerformanceTracker? performanceTracker,
  })  : crashReportingService = crashReportingService ?? ProductionCrashReportingService(),
        telemetryService = telemetryService ?? ProductionTelemetryService(),
        performanceTracker = performanceTracker ??
            PerformanceTracker(telemetryService ?? ProductionTelemetryService()),
        mediaStorageRepository = mediaStorageRepository ?? MockMediaStorageRepository(),
        mediaPickerService = mediaPickerService ?? MockMediaPickerService(),
        audioRecorderService = audioRecorderService ?? MockAudioRecorderService(),
        captureProcessingRepository =
            captureProcessingRepository ?? MockCaptureProcessingRepository(),
        captureProcessingService =
            captureProcessingService ?? MockCaptureProcessingService(),
        ocrService = ocrService ?? MockOcrService(),
        entityResolutionService =
            entityResolutionService ?? MockEntityResolutionService(),
        relationshipMemoryService =
            relationshipMemoryService ?? MockRelationshipMemoryService(),
        memoryRetrievalRepository =
            memoryRetrievalRepository ?? MockMemoryRetrievalRepository(),
        relationshipContextAssembler = relationshipContextAssembler ??
            RelationshipContextAssembler(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              followUpRepository: followUpRepository,
              captureRepository: captureRepository,
            ),
        memoryRetrievalService = memoryRetrievalService ??
            MockMemoryRetrievalService(),
        answerGroundingService = answerGroundingService ?? const AnswerGroundingService(),
        geminiAiConfiguration = geminiAiConfiguration ?? const GeminiAiConfiguration(),
        geminiAiProvider = geminiAiProvider ?? MockGeminiAiProvider(),
        geminiPromptBuilder = geminiPromptBuilder ?? const GeminiPromptBuilder(),
        geminiResponseParser = geminiResponseParser ?? const GeminiResponseParser(),
        groundedAnswerValidator = groundedAnswerValidator ??
            GroundedAnswerValidator(
              groundingService: answerGroundingService ?? const AnswerGroundingService(),
            ),
        aiAnswerGenerator = aiAnswerGenerator ??
            GeminiGroundedAnswerGenerator(
              configuration: geminiAiConfiguration ?? const GeminiAiConfiguration(),
              provider: geminiAiProvider ?? MockGeminiAiProvider(),
              promptBuilder: geminiPromptBuilder ?? const GeminiPromptBuilder(),
              responseParser: geminiResponseParser ?? const GeminiResponseParser(),
              validator: groundedAnswerValidator ??
                  GroundedAnswerValidator(
                    groundingService: answerGroundingService ?? const AnswerGroundingService(),
                  ),
              fallbackGenerator: DeterministicAiAnswerGenerator(
                groundingService: answerGroundingService ?? const AnswerGroundingService(),
              ),
            ),
        aiAnswerService = aiAnswerService ??
            DeterministicAiAnswerService(
              retrievalService: memoryRetrievalService ?? MockMemoryRetrievalService(),
              generator: aiAnswerGenerator ??
                  GeminiGroundedAnswerGenerator(
                    configuration: geminiAiConfiguration ?? const GeminiAiConfiguration(),
                    provider: geminiAiProvider ?? MockGeminiAiProvider(),
                    promptBuilder: geminiPromptBuilder ?? const GeminiPromptBuilder(),
                    responseParser: geminiResponseParser ?? const GeminiResponseParser(),
                    validator: groundedAnswerValidator ??
                        GroundedAnswerValidator(
                          groundingService: answerGroundingService ?? const AnswerGroundingService(),
                        ),
                    fallbackGenerator: DeterministicAiAnswerGenerator(
                      groundingService: answerGroundingService ?? const AnswerGroundingService(),
                    ),
                  ),
              groundingService: answerGroundingService ?? const AnswerGroundingService(),
            ),
        relationshipStrengthCalculator =
            relationshipStrengthCalculator ?? const DeterministicRelationshipStrengthCalculator(),
        relationshipStateClassifier =
            relationshipStateClassifier ?? const DeterministicRelationshipStateClassifier(),
        relationshipIntelligenceService = relationshipIntelligenceService ??
            DeterministicRelationshipIntelligenceService(
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              followUpRepository: followUpRepository,
              captureRepository: captureRepository,
              strengthCalculator: relationshipStrengthCalculator ??
                  const DeterministicRelationshipStrengthCalculator(),
              stateClassifier: relationshipStateClassifier ??
                  const DeterministicRelationshipStateClassifier(),
            ),
        relationshipActionPriorityCalculator = relationshipActionPriorityCalculator ??
            const DeterministicRelationshipActionPriorityCalculator(),
        relationshipActionEngine = relationshipActionEngine ??
            DeterministicRelationshipActionEngine(
              priorityCalculator: relationshipActionPriorityCalculator ??
                  const DeterministicRelationshipActionPriorityCalculator(),
            ),
        relationshipAttentionCalculator = relationshipAttentionCalculator ??
            const DeterministicRelationshipAttentionCalculator(),
        relationshipAttentionPriorityCalculator = relationshipAttentionPriorityCalculator ??
            const DeterministicRelationshipAttentionPriorityCalculator(),
        relationshipAttentionEngine = relationshipAttentionEngine ??
            DeterministicRelationshipAttentionEngine(
              calculator: relationshipAttentionCalculator ??
                  const DeterministicRelationshipAttentionCalculator(),
              priorityCalculator: relationshipAttentionPriorityCalculator ??
                  const DeterministicRelationshipAttentionPriorityCalculator(),
              actionEngine: relationshipActionEngine ??
                  const DeterministicRelationshipActionEngine(),
            ),
        networkHealthCalculator = networkHealthCalculator ??
            const DeterministicNetworkHealthCalculator(),
        networkTrendCalculator = networkTrendCalculator ??
            const DeterministicNetworkTrendCalculator(),
        networkInsightGenerator = networkInsightGenerator ??
            const DeterministicNetworkInsightGenerator(),
        networkIntelligenceService = networkIntelligenceService ??
            DeterministicNetworkIntelligenceService(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              followUpRepository: followUpRepository,
              captureRepository: captureRepository,
              relationshipIntelligenceService: relationshipIntelligenceService ??
                  DeterministicRelationshipIntelligenceService(
                    personDetailRepository: personDetailRepository,
                    activityRepository: activityRepository,
                    followUpRepository: followUpRepository,
                    captureRepository: captureRepository,
                  ),
              relationshipAttentionEngine: relationshipAttentionEngine ??
                  const DeterministicRelationshipAttentionEngine(),
              healthCalculator: networkHealthCalculator ??
                  const DeterministicNetworkHealthCalculator(),
              trendCalculator: networkTrendCalculator ??
                  const DeterministicNetworkTrendCalculator(),
              insightGenerator: networkInsightGenerator ??
                  const DeterministicNetworkInsightGenerator(),
            ),
        relationshipCadenceCalculator = relationshipCadenceCalculator ??
            const DeterministicRelationshipCadenceCalculator(),
        relationshipVelocityCalculator = relationshipVelocityCalculator ??
            const DeterministicRelationshipVelocityCalculator(),
        relationshipEvolutionClassifier = relationshipEvolutionClassifier ??
            const DeterministicRelationshipEvolutionClassifier(),
        relationshipMomentumEngine = relationshipMomentumEngine ??
            DeterministicRelationshipMomentumEngine(
              cadenceCalculator: relationshipCadenceCalculator ??
                  const DeterministicRelationshipCadenceCalculator(),
              velocityCalculator: relationshipVelocityCalculator ??
                  const DeterministicRelationshipVelocityCalculator(),
              evolutionClassifier: relationshipEvolutionClassifier ??
                  const DeterministicRelationshipEvolutionClassifier(),
            ),
        relationshipMomentumService = relationshipMomentumService ??
            DeterministicRelationshipMomentumService(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              followUpRepository: followUpRepository,
              relationshipIntelligenceService: relationshipIntelligenceService ??
                  DeterministicRelationshipIntelligenceService(
                    personDetailRepository: personDetailRepository,
                    activityRepository: activityRepository,
                    followUpRepository: followUpRepository,
                    captureRepository: captureRepository,
                  ),
              momentumEngine: relationshipMomentumEngine ??
                  const DeterministicRelationshipMomentumEngine(),
            ),
        networkConnectionCalculator = networkConnectionCalculator ??
            const DeterministicNetworkConnectionCalculator(),
        networkClusterDetector = networkClusterDetector ??
            const DeterministicNetworkClusterDetector(),
        networkPatternEngine = networkPatternEngine ??
            const DeterministicNetworkPatternEngine(),
        networkConnectionIntelligenceService = networkConnectionIntelligenceService ??
            DeterministicNetworkConnectionIntelligenceService(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              captureRepository: captureRepository,
              relationshipIntelligenceService: relationshipIntelligenceService,
              momentumEngine: relationshipMomentumEngine,
              connectionCalculator: networkConnectionCalculator ??
                  const DeterministicNetworkConnectionCalculator(),
              clusterDetector: networkClusterDetector ??
                  const DeterministicNetworkClusterDetector(),
              patternEngine: networkPatternEngine ??
                  const DeterministicNetworkPatternEngine(),
            ),
        relationshipIntelligenceConsistencyValidator = relationshipIntelligenceConsistencyValidator ??
            const RelationshipIntelligenceConsistencyValidator(),
        unifiedRelationshipRanking = unifiedRelationshipRanking ??
            const UnifiedRelationshipRanking(),
        unifiedRelationshipIntelligenceService = unifiedRelationshipIntelligenceService ??
            DeterministicUnifiedRelationshipIntelligenceService(
              peopleRepository: peopleRepository,
              personDetailRepository: personDetailRepository,
              activityRepository: activityRepository,
              followUpRepository: followUpRepository,
              captureRepository: captureRepository,
              strengthCalculator: relationshipStrengthCalculator ??
                  const DeterministicRelationshipStrengthCalculator(),
              stateClassifier: relationshipStateClassifier ??
                  const DeterministicRelationshipStateClassifier(),
              actionEngine: relationshipActionEngine ??
                  const DeterministicRelationshipActionEngine(),
              attentionEngine: relationshipAttentionEngine ??
                  const DeterministicRelationshipAttentionEngine(),
              momentumEngine: relationshipMomentumEngine ??
                  const DeterministicRelationshipMomentumEngine(),
              networkConnectionService: networkConnectionIntelligenceService,
              networkIntelligenceService: networkIntelligenceService,
              ranking: unifiedRelationshipRanking ?? const UnifiedRelationshipRanking(),
              validator: relationshipIntelligenceConsistencyValidator ??
                  const RelationshipIntelligenceConsistencyValidator(),
            );

  /// Production configuration resolving to Firestore-backed repositories, ML Kit OCR, and identity resolution.
  factory RecallrDependencies.production({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    PeopleRepository? peopleRepository,
    PersonDetailRepository? personDetailRepository,
    ActivityRepository? activityRepository,
    FollowUpRepository? followUpRepository,
    CaptureRepository? captureRepository,
    MediaStorageRepository? mediaStorageRepository,
    MediaPickerService? mediaPickerService,
    AudioRecorderService? audioRecorderService,
    CaptureProcessingRepository? captureProcessingRepository,
    CaptureProcessingService? captureProcessingService,
    OcrService? ocrService,
    EntityResolutionService? entityResolutionService,
    RelationshipMemoryService? relationshipMemoryService,
    MemoryRetrievalRepository? memoryRetrievalRepository,
    MemoryRetrievalService? memoryRetrievalService,
    AiAnswerGenerator? aiAnswerGenerator,
    AnswerGroundingService? answerGroundingService,
    AiAnswerService? aiAnswerService,
    GeminiAiConfiguration? geminiAiConfiguration,
    GeminiAiProvider? geminiAiProvider,
    GeminiPromptBuilder? geminiPromptBuilder,
    GeminiResponseParser? geminiResponseParser,
    GroundedAnswerValidator? groundedAnswerValidator,
    RelationshipStrengthCalculator? relationshipStrengthCalculator,
    RelationshipStateClassifier? relationshipStateClassifier,
    RelationshipIntelligenceService? relationshipIntelligenceService,
    RelationshipActionPriorityCalculator? relationshipActionPriorityCalculator,
    RelationshipActionEngine? relationshipActionEngine,
    RelationshipAttentionCalculator? relationshipAttentionCalculator,
    RelationshipAttentionPriorityCalculator? relationshipAttentionPriorityCalculator,
    RelationshipAttentionEngine? relationshipAttentionEngine,
    NetworkHealthCalculator? networkHealthCalculator,
    NetworkTrendCalculator? networkTrendCalculator,
    NetworkInsightGenerator? networkInsightGenerator,
    NetworkIntelligenceService? networkIntelligenceService,
    RelationshipCadenceCalculator? relationshipCadenceCalculator,
    RelationshipVelocityCalculator? relationshipVelocityCalculator,
    RelationshipEvolutionClassifier? relationshipEvolutionClassifier,
    RelationshipMomentumEngine? relationshipMomentumEngine,
    RelationshipMomentumService? relationshipMomentumService,
    NetworkConnectionCalculator? networkConnectionCalculator,
    NetworkClusterDetector? networkClusterDetector,
    NetworkPatternEngine? networkPatternEngine,
    NetworkConnectionIntelligenceService? networkConnectionIntelligenceService,
    UnifiedRelationshipIntelligenceService? unifiedRelationshipIntelligenceService,
    RelationshipIntelligenceConsistencyValidator? relationshipIntelligenceConsistencyValidator,
    UnifiedRelationshipRanking? unifiedRelationshipRanking,
    CrashReportingService? crashReportingService,
    TelemetryService? telemetryService,
    PerformanceTracker? performanceTracker,
  }) {
    final peopleRepo = peopleRepository ?? FirestorePeopleRepository(firestore: firestore, auth: auth);
    final personDetailRepo = personDetailRepository ?? FirestorePersonDetailRepository(firestore: firestore, auth: auth);
    final activityRepo = activityRepository ?? FirestoreActivityRepository(firestore: firestore, auth: auth);
    final followUpRepo = followUpRepository ?? FirestoreFollowUpRepository(firestore: firestore, auth: auth);
    final captureRepo = captureRepository ?? FirestoreCaptureRepository(firestore: firestore, auth: auth);
    final ocr = ocrService ?? MlKitOcrService();

    final relMemoryService = relationshipMemoryService ??
        DeterministicRelationshipMemoryService(
          personDetailRepository: personDetailRepo,
          followUpRepository: followUpRepo,
          peopleRepository: peopleRepo,
        );

    final resolutionService = entityResolutionService ??
        DeterministicEntityResolutionService(
          peopleRepository: peopleRepo,
          activityRepository: activityRepo,
          relationshipMemoryService: relMemoryService,
        );

    final processingService = DeterministicCaptureProcessingService(
      ocrService: ocr,
      entityResolutionService: resolutionService,
      simulatedLatency: Duration.zero,
    );

    final retrievalRepo = memoryRetrievalRepository ??
        FirestoreMemoryRetrievalRepository(
          firestore: firestore,
          auth: auth,
        );

    final contextAssembler = RelationshipContextAssembler(
      peopleRepository: peopleRepo,
      personDetailRepository: personDetailRepo,
      activityRepository: activityRepo,
      followUpRepository: followUpRepo,
      captureRepository: captureRepo,
    );

    final retrievalService = memoryRetrievalService ??
        DeterministicMemoryRetrievalService(
          repository: retrievalRepo,
          assembler: contextAssembler,
        );

    final grounding = answerGroundingService ?? const AnswerGroundingService();
    final geminiConfig = geminiAiConfiguration ?? GeminiAiConfiguration.fromEnvironment();
    final geminiProv = geminiAiProvider ??
        (geminiConfig.isConfigured
            ? GoogleSdkGeminiAiProvider(configuration: geminiConfig)
            : CallableFunctionsGeminiAiProvider(
                functions: functions,
                configuration: geminiConfig,
              ));
    final promptBuilder = geminiPromptBuilder ?? const GeminiPromptBuilder();
    final responseParser = geminiResponseParser ?? const GeminiResponseParser();
    final validator = groundedAnswerValidator ?? GroundedAnswerValidator(groundingService: grounding);

    final generator = aiAnswerGenerator ??
        GeminiGroundedAnswerGenerator(
          configuration: geminiConfig,
          provider: geminiProv,
          promptBuilder: promptBuilder,
          responseParser: responseParser,
          validator: validator,
          fallbackGenerator: DeterministicAiAnswerGenerator(groundingService: grounding),
        );

    final answerSvc = aiAnswerService ??
        DeterministicAiAnswerService(
          retrievalService: retrievalService,
          generator: generator,
          groundingService: grounding,
        );

    final strengthCalc = relationshipStrengthCalculator ??
        const DeterministicRelationshipStrengthCalculator();
    final stateClass = relationshipStateClassifier ??
        const DeterministicRelationshipStateClassifier();

    final intelligenceSvc = relationshipIntelligenceService ??
        DeterministicRelationshipIntelligenceService(
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          captureRepository: captureRepo,
          strengthCalculator: strengthCalc,
          stateClassifier: stateClass,
        );

    final actionPriorityCalc = relationshipActionPriorityCalculator ??
        const DeterministicRelationshipActionPriorityCalculator();
    final actionEngine = relationshipActionEngine ??
        DeterministicRelationshipActionEngine(priorityCalculator: actionPriorityCalc);

    final attentionCalc = relationshipAttentionCalculator ??
        const DeterministicRelationshipAttentionCalculator();
    final attentionPriorityCalc = relationshipAttentionPriorityCalculator ??
        const DeterministicRelationshipAttentionPriorityCalculator();
    final attentionEngine = relationshipAttentionEngine ??
        DeterministicRelationshipAttentionEngine(
          calculator: attentionCalc,
          priorityCalculator: attentionPriorityCalc,
          actionEngine: actionEngine,
        );

    final netHealthCalc = networkHealthCalculator ??
        const DeterministicNetworkHealthCalculator();
    final netTrendCalc = networkTrendCalculator ??
        const DeterministicNetworkTrendCalculator();
    final netInsightGen = networkInsightGenerator ??
        const DeterministicNetworkInsightGenerator();
    final netIntelSvc = networkIntelligenceService ??
        DeterministicNetworkIntelligenceService(
          peopleRepository: peopleRepo,
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          captureRepository: captureRepo,
          relationshipIntelligenceService: intelligenceSvc,
          relationshipAttentionEngine: attentionEngine,
          healthCalculator: netHealthCalc,
          trendCalculator: netTrendCalc,
          insightGenerator: netInsightGen,
        );

    final cadenceCalc = relationshipCadenceCalculator ??
        const DeterministicRelationshipCadenceCalculator();
    final velocityCalc = relationshipVelocityCalculator ??
        const DeterministicRelationshipVelocityCalculator();
    final evolutionClass = relationshipEvolutionClassifier ??
        const DeterministicRelationshipEvolutionClassifier();
    final momentumEng = relationshipMomentumEngine ??
        DeterministicRelationshipMomentumEngine(
          cadenceCalculator: cadenceCalc,
          velocityCalculator: velocityCalc,
          evolutionClassifier: evolutionClass,
        );
    final momentumSvc = relationshipMomentumService ??
        DeterministicRelationshipMomentumService(
          peopleRepository: peopleRepo,
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          relationshipIntelligenceService: intelligenceSvc,
          momentumEngine: momentumEng,
        );

    final crashSvc = crashReportingService ?? ProductionCrashReportingService();
    final telemetrySvc = telemetryService ?? ProductionTelemetryService();
    final perfTracker = performanceTracker ?? PerformanceTracker(telemetrySvc);

    return RecallrDependencies(
      peopleRepository: peopleRepo,
      personDetailRepository: personDetailRepo,
      activityRepository: activityRepo,
      followUpRepository: followUpRepo,
      captureRepository: captureRepo,
      mediaStorageRepository: FirebaseMediaStorageRepository(storage: storage, auth: auth),
      mediaPickerService: DeviceMediaPickerService(),
      audioRecorderService: DeviceAudioRecorderService(),
      captureProcessingRepository: FirestoreCaptureProcessingRepository(
        firestore: firestore,
        auth: auth,
        processingService: processingService,
      ),
      captureProcessingService: processingService,
      ocrService: ocr,
      entityResolutionService: resolutionService,
      relationshipMemoryService: relMemoryService,
      memoryRetrievalRepository: retrievalRepo,
      relationshipContextAssembler: contextAssembler,
      memoryRetrievalService: retrievalService,
      answerGroundingService: grounding,
      aiAnswerGenerator: generator,
      aiAnswerService: answerSvc,
      geminiAiConfiguration: geminiConfig,
      geminiAiProvider: geminiProv,
      geminiPromptBuilder: promptBuilder,
      geminiResponseParser: responseParser,
      groundedAnswerValidator: validator,
      relationshipStrengthCalculator: strengthCalc,
      relationshipStateClassifier: stateClass,
      relationshipIntelligenceService: intelligenceSvc,
      relationshipActionPriorityCalculator: actionPriorityCalc,
      relationshipActionEngine: actionEngine,
      relationshipAttentionCalculator: attentionCalc,
      relationshipAttentionPriorityCalculator: attentionPriorityCalc,
      relationshipAttentionEngine: attentionEngine,
      networkHealthCalculator: netHealthCalc,
      networkTrendCalculator: netTrendCalc,
      networkInsightGenerator: netInsightGen,
      networkIntelligenceService: netIntelSvc,
      relationshipCadenceCalculator: cadenceCalc,
      relationshipVelocityCalculator: velocityCalc,
      relationshipEvolutionClassifier: evolutionClass,
      relationshipMomentumEngine: momentumEng,
      relationshipMomentumService: momentumSvc,
      crashReportingService: crashSvc,
      telemetryService: telemetrySvc,
      performanceTracker: perfTracker,
    );
  }

  /// Mock / Test configuration resolving to deterministic in-memory repositories.
  factory RecallrDependencies.mock({
    PeopleRepository? peopleRepository,
    PersonDetailRepository? personDetailRepository,
    ActivityRepository? activityRepository,
    FollowUpRepository? followUpRepository,
    CaptureRepository? captureRepository,
    MediaStorageRepository? mediaStorageRepository,
    MediaPickerService? mediaPickerService,
    AudioRecorderService? audioRecorderService,
    CaptureProcessingRepository? captureProcessingRepository,
    CaptureProcessingService? captureProcessingService,
    OcrService? ocrService,
    EntityResolutionService? entityResolutionService,
    RelationshipMemoryService? relationshipMemoryService,
    MemoryRetrievalRepository? memoryRetrievalRepository,
    MemoryRetrievalService? memoryRetrievalService,
    AiAnswerGenerator? aiAnswerGenerator,
    AnswerGroundingService? answerGroundingService,
    AiAnswerService? aiAnswerService,
    GeminiAiConfiguration? geminiAiConfiguration,
    GeminiAiProvider? geminiAiProvider,
    GeminiPromptBuilder? geminiPromptBuilder,
    GeminiResponseParser? geminiResponseParser,
    GroundedAnswerValidator? groundedAnswerValidator,
    RelationshipStrengthCalculator? relationshipStrengthCalculator,
    RelationshipStateClassifier? relationshipStateClassifier,
    RelationshipIntelligenceService? relationshipIntelligenceService,
    RelationshipActionPriorityCalculator? relationshipActionPriorityCalculator,
    RelationshipActionEngine? relationshipActionEngine,
    RelationshipAttentionCalculator? relationshipAttentionCalculator,
    RelationshipAttentionPriorityCalculator? relationshipAttentionPriorityCalculator,
    RelationshipAttentionEngine? relationshipAttentionEngine,
    NetworkHealthCalculator? networkHealthCalculator,
    NetworkTrendCalculator? networkTrendCalculator,
    NetworkInsightGenerator? networkInsightGenerator,
    NetworkIntelligenceService? networkIntelligenceService,
    RelationshipCadenceCalculator? relationshipCadenceCalculator,
    RelationshipVelocityCalculator? relationshipVelocityCalculator,
    RelationshipEvolutionClassifier? relationshipEvolutionClassifier,
    RelationshipMomentumEngine? relationshipMomentumEngine,
    RelationshipMomentumService? relationshipMomentumService,
    NetworkConnectionCalculator? networkConnectionCalculator,
    NetworkClusterDetector? networkClusterDetector,
    NetworkPatternEngine? networkPatternEngine,
    NetworkConnectionIntelligenceService? networkConnectionIntelligenceService,
    UnifiedRelationshipIntelligenceService? unifiedRelationshipIntelligenceService,
    RelationshipIntelligenceConsistencyValidator? relationshipIntelligenceConsistencyValidator,
    UnifiedRelationshipRanking? unifiedRelationshipRanking,
    CrashReportingService? crashReportingService,
    TelemetryService? telemetryService,
    PerformanceTracker? performanceTracker,
  }) {
    final peopleRepo = peopleRepository ?? MockPeopleRepository();
    final personDetailRepo = personDetailRepository ?? MockPersonDetailRepository();
    final activityRepo = activityRepository ?? MockActivityRepository();
    final followUpRepo = followUpRepository ?? MockFollowUpRepository();
    final captureRepo = captureRepository ?? MockCaptureRepository();
    final ocr = ocrService ?? MockOcrService();

    final relMemoryService = relationshipMemoryService ??
        DeterministicRelationshipMemoryService(
          personDetailRepository: personDetailRepo,
          followUpRepository: followUpRepo,
          peopleRepository: peopleRepo,
        );

    final resolutionService = entityResolutionService ??
        DeterministicEntityResolutionService(
          peopleRepository: peopleRepo,
          activityRepository: activityRepo,
          relationshipMemoryService: relMemoryService,
        );

    final service = captureProcessingService ??
        DeterministicCaptureProcessingService(
          ocrService: ocr,
          entityResolutionService: resolutionService,
          simulatedLatency: Duration.zero,
        );

    final retrievalRepo = memoryRetrievalRepository ??
        MockMemoryRetrievalRepository(
          peopleRepository: peopleRepo,
          activityRepository: activityRepo,
          captureRepository: captureRepo,
          followUpRepository: followUpRepo,
          personDetailRepository: personDetailRepo,
        );

    final contextAssembler = RelationshipContextAssembler(
      peopleRepository: peopleRepo,
      personDetailRepository: personDetailRepo,
      activityRepository: activityRepo,
      followUpRepository: followUpRepo,
      captureRepository: captureRepo,
    );

    final retrievalService = memoryRetrievalService ??
        DeterministicMemoryRetrievalService(
          repository: retrievalRepo,
          assembler: contextAssembler,
        );

    final grounding = answerGroundingService ?? const AnswerGroundingService();
    final geminiConfig = geminiAiConfiguration ?? const GeminiAiConfiguration();
    final geminiProv = geminiAiProvider ?? MockGeminiAiProvider();
    final promptBuilder = geminiPromptBuilder ?? const GeminiPromptBuilder();
    final responseParser = geminiResponseParser ?? const GeminiResponseParser();
    final validator = groundedAnswerValidator ?? GroundedAnswerValidator(groundingService: grounding);

    final generator = aiAnswerGenerator ??
        GeminiGroundedAnswerGenerator(
          configuration: geminiConfig,
          provider: geminiProv,
          promptBuilder: promptBuilder,
          responseParser: responseParser,
          validator: validator,
          fallbackGenerator: DeterministicAiAnswerGenerator(groundingService: grounding),
        );

    final answerSvc = aiAnswerService ??
        DeterministicAiAnswerService(
          retrievalService: retrievalService,
          generator: generator,
          groundingService: grounding,
        );

    final strengthCalc = relationshipStrengthCalculator ??
        const DeterministicRelationshipStrengthCalculator();
    final stateClass = relationshipStateClassifier ??
        const DeterministicRelationshipStateClassifier();

    final intelligenceSvc = relationshipIntelligenceService ??
        DeterministicRelationshipIntelligenceService(
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          captureRepository: captureRepo,
          strengthCalculator: strengthCalc,
          stateClassifier: stateClass,
        );

    final actionPriorityCalc = relationshipActionPriorityCalculator ??
        const DeterministicRelationshipActionPriorityCalculator();
    final actionEngine = relationshipActionEngine ??
        DeterministicRelationshipActionEngine(priorityCalculator: actionPriorityCalc);

    final attentionCalc = relationshipAttentionCalculator ??
        const DeterministicRelationshipAttentionCalculator();
    final attentionPriorityCalc = relationshipAttentionPriorityCalculator ??
        const DeterministicRelationshipAttentionPriorityCalculator();
    final attentionEngine = relationshipAttentionEngine ??
        DeterministicRelationshipAttentionEngine(
          calculator: attentionCalc,
          priorityCalculator: attentionPriorityCalc,
          actionEngine: actionEngine,
        );

    final netHealthCalc = networkHealthCalculator ??
        const DeterministicNetworkHealthCalculator();
    final netTrendCalc = networkTrendCalculator ??
        const DeterministicNetworkTrendCalculator();
    final netInsightGen = networkInsightGenerator ??
        const DeterministicNetworkInsightGenerator();
    final netIntelSvc = networkIntelligenceService ??
        DeterministicNetworkIntelligenceService(
          peopleRepository: peopleRepo,
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          captureRepository: captureRepo,
          relationshipIntelligenceService: intelligenceSvc,
          relationshipAttentionEngine: attentionEngine,
          healthCalculator: netHealthCalc,
          trendCalculator: netTrendCalc,
          insightGenerator: netInsightGen,
        );

    final cadenceCalc = relationshipCadenceCalculator ??
        const DeterministicRelationshipCadenceCalculator();
    final velocityCalc = relationshipVelocityCalculator ??
        const DeterministicRelationshipVelocityCalculator();
    final evolutionClass = relationshipEvolutionClassifier ??
        const DeterministicRelationshipEvolutionClassifier();
    final momentumEng = relationshipMomentumEngine ??
        DeterministicRelationshipMomentumEngine(
          cadenceCalculator: cadenceCalc,
          velocityCalculator: velocityCalc,
          evolutionClassifier: evolutionClass,
        );
    final momentumSvc = relationshipMomentumService ??
        DeterministicRelationshipMomentumService(
          peopleRepository: peopleRepo,
          personDetailRepository: personDetailRepo,
          activityRepository: activityRepo,
          followUpRepository: followUpRepo,
          relationshipIntelligenceService: intelligenceSvc,
          momentumEngine: momentumEng,
        );

    final crashSvc = crashReportingService ?? MockCrashReportingService();
    final telemetrySvc = telemetryService ?? MockTelemetryService();
    final perfTracker = performanceTracker ?? PerformanceTracker(telemetrySvc);

    return RecallrDependencies(
      peopleRepository: peopleRepo,
      personDetailRepository: personDetailRepo,
      activityRepository: activityRepo,
      followUpRepository: followUpRepo,
      captureRepository: captureRepo,
      mediaStorageRepository: mediaStorageRepository ?? MockMediaStorageRepository(),
      mediaPickerService: mediaPickerService ?? MockMediaPickerService(),
      audioRecorderService: audioRecorderService ?? MockAudioRecorderService(),
      captureProcessingRepository:
          captureProcessingRepository ?? MockCaptureProcessingRepository(service: service),
      captureProcessingService: service,
      ocrService: ocr,
      entityResolutionService: resolutionService,
      relationshipMemoryService: relMemoryService,
      memoryRetrievalRepository: retrievalRepo,
      relationshipContextAssembler: contextAssembler,
      memoryRetrievalService: retrievalService,
      answerGroundingService: grounding,
      aiAnswerGenerator: generator,
      aiAnswerService: answerSvc,
      geminiAiConfiguration: geminiConfig,
      geminiAiProvider: geminiProv,
      geminiPromptBuilder: promptBuilder,
      geminiResponseParser: responseParser,
      groundedAnswerValidator: validator,
      relationshipStrengthCalculator: strengthCalc,
      relationshipStateClassifier: stateClass,
      relationshipIntelligenceService: intelligenceSvc,
      relationshipActionPriorityCalculator: actionPriorityCalc,
      relationshipActionEngine: actionEngine,
      relationshipAttentionCalculator: attentionCalc,
      relationshipAttentionPriorityCalculator: attentionPriorityCalc,
      relationshipAttentionEngine: attentionEngine,
      networkHealthCalculator: netHealthCalc,
      networkTrendCalculator: netTrendCalc,
      networkInsightGenerator: netInsightGen,
      networkIntelligenceService: netIntelSvc,
      relationshipCadenceCalculator: cadenceCalc,
      relationshipVelocityCalculator: velocityCalc,
      relationshipEvolutionClassifier: evolutionClass,
      relationshipMomentumEngine: momentumEng,
      relationshipMomentumService: momentumSvc,
      crashReportingService: crashSvc,
      telemetryService: telemetrySvc,
      performanceTracker: perfTracker,
    );
  }

  static RecallrDependencies? _instance;

  /// Global instance fallback (defaults to Mock configuration for tests and offline preview).
  static RecallrDependencies get instance => _instance ??= RecallrDependencies.mock();

  /// Set the global dependencies instance (useful for testing or app bootstrap).
  static void setInstance(RecallrDependencies dependencies) {
    _instance = dependencies;
  }

  /// Reset the global instance.
  static void reset() {
    _instance = null;
  }
}

/// InheritedWidget providing RecallrDependencies down the widget tree.
class RecallrScope extends InheritedWidget {
  final RecallrDependencies dependencies;

  const RecallrScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  static RecallrDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecallrScope>();
    return scope?.dependencies ?? RecallrDependencies.instance;
  }

  @override
  bool updateShouldNotify(covariant RecallrScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}

/// Convenience extensions on BuildContext to access repositories cleanly.
extension RecallrDependenciesContext on BuildContext {
  RecallrDependencies get dependencies => RecallrScope.of(this);
  PeopleRepository get peopleRepo => dependencies.peopleRepository;
  PersonDetailRepository get personDetailRepo => dependencies.personDetailRepository;
  ActivityRepository get activityRepo => dependencies.activityRepository;
  FollowUpRepository get followUpRepo => dependencies.followUpRepository;
  CaptureRepository get captureRepo => dependencies.captureRepository;
  MediaStorageRepository get mediaStorageRepo => dependencies.mediaStorageRepository;
  MediaPickerService get mediaPickerService => dependencies.mediaPickerService;
  AudioRecorderService get audioRecorderService => dependencies.audioRecorderService;
  CaptureProcessingRepository get captureProcessingRepo => dependencies.captureProcessingRepository;
  CaptureProcessingService get captureProcessingService => dependencies.captureProcessingService;
  OcrService get ocrService => dependencies.ocrService;
  EntityResolutionService get entityResolutionService => dependencies.entityResolutionService;
  RelationshipMemoryService get relationshipMemoryService => dependencies.relationshipMemoryService;
  MemoryRetrievalRepository get memoryRetrievalRepo => dependencies.memoryRetrievalRepository;
  RelationshipContextAssembler get relationshipContextAssembler => dependencies.relationshipContextAssembler;
  MemoryRetrievalService get memoryRetrievalService => dependencies.memoryRetrievalService;
  AiAnswerGenerator get aiAnswerGenerator => dependencies.aiAnswerGenerator;
  AnswerGroundingService get answerGroundingService => dependencies.answerGroundingService;
  AiAnswerService get aiAnswerService => dependencies.aiAnswerService;
  GeminiAiConfiguration get geminiAiConfiguration => dependencies.geminiAiConfiguration;
  GeminiAiProvider get geminiAiProvider => dependencies.geminiAiProvider;
  GeminiPromptBuilder get geminiPromptBuilder => dependencies.geminiPromptBuilder;
  GeminiResponseParser get geminiResponseParser => dependencies.geminiResponseParser;
  GroundedAnswerValidator get groundedAnswerValidator => dependencies.groundedAnswerValidator;
  RelationshipStrengthCalculator get relationshipStrengthCalculator => dependencies.relationshipStrengthCalculator;
  RelationshipStateClassifier get relationshipStateClassifier => dependencies.relationshipStateClassifier;
  RelationshipIntelligenceService get relationshipIntelligenceService => dependencies.relationshipIntelligenceService;
  RelationshipActionPriorityCalculator get relationshipActionPriorityCalculator => dependencies.relationshipActionPriorityCalculator;
  RelationshipActionEngine get relationshipActionEngine => dependencies.relationshipActionEngine;
  RelationshipAttentionCalculator get relationshipAttentionCalculator => dependencies.relationshipAttentionCalculator;
  RelationshipAttentionPriorityCalculator get relationshipAttentionPriorityCalculator => dependencies.relationshipAttentionPriorityCalculator;
  RelationshipAttentionEngine get relationshipAttentionEngine => dependencies.relationshipAttentionEngine;
  NetworkHealthCalculator get networkHealthCalculator => dependencies.networkHealthCalculator;
  NetworkTrendCalculator get networkTrendCalculator => dependencies.networkTrendCalculator;
  NetworkInsightGenerator get networkInsightGenerator => dependencies.networkInsightGenerator;
  NetworkIntelligenceService get networkIntelligenceService => dependencies.networkIntelligenceService;
  RelationshipCadenceCalculator get relationshipCadenceCalculator => dependencies.relationshipCadenceCalculator;
  RelationshipVelocityCalculator get relationshipVelocityCalculator => dependencies.relationshipVelocityCalculator;
  RelationshipEvolutionClassifier get relationshipEvolutionClassifier => dependencies.relationshipEvolutionClassifier;
  RelationshipMomentumEngine get relationshipMomentumEngine => dependencies.relationshipMomentumEngine;
  RelationshipMomentumService get relationshipMomentumService => dependencies.relationshipMomentumService;
  NetworkConnectionCalculator get networkConnectionCalculator => dependencies.networkConnectionCalculator;
  NetworkClusterDetector get networkClusterDetector => dependencies.networkClusterDetector;
  NetworkPatternEngine get networkPatternEngine => dependencies.networkPatternEngine;
  NetworkConnectionIntelligenceService get networkConnectionIntelligenceService => dependencies.networkConnectionIntelligenceService;
  UnifiedRelationshipIntelligenceService get unifiedRelationshipIntelligence => dependencies.unifiedRelationshipIntelligenceService;
  RelationshipIntelligenceConsistencyValidator get relationshipIntelligenceConsistencyValidator => dependencies.relationshipIntelligenceConsistencyValidator;
  UnifiedRelationshipRanking get unifiedRelationshipRanking => dependencies.unifiedRelationshipRanking;
}