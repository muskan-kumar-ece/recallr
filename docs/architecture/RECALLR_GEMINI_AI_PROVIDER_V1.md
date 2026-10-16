# Recallr Production Gemini AI Provider & Grounded Answer Engine v1

## 1. Architectural Overview

Phase 13E-03 integrates the production **Google Gemini AI Provider** into Recallr's grounded Q&A architecture without compromising personal data security, provenance, multi-tenant isolation, or offline resilience.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          User Question Prompt                          │
│             "What did I discuss with Priya about RISC-V?"              │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              AskScreen                                 │
│                   context.dependencies.aiAnswerService                 │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                Phase 13E-01: Retrieval & Context Assembly              │
│    MemoryRetrievalService → Multi-Source Firestore → MemoryContext     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Phase 13E-02: Answer Grounding Pre-Processing            │
│         AnswerGroundingService (Candidate Evidence & Baseline)         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│             Phase 13E-03: GeminiGroundedAnswerGenerator                │
│                                                                        │
│   1. GeminiPromptBuilder (12 Anti-Hallucination Rules, Bounded Context)│
│   2. GeminiAiProvider (GoogleSdkGeminiAiProvider / MockProvider)       │
│      ├── Bounded Timeout: 15s                                          │
│      ├── Transient Retries: Max 2                                      │
│      └── Typed Error Handling                                          │
│   3. GeminiResponseParser (Safe JSON Parsing & Markdown De-fencing)    │
│   4. GroundedAnswerValidator                                           │
│      ├── Evidence ID Verification (Rejects Unknown / Invented IDs)     │
│      ├── Person Entity Verification (Filters Hallucinated Names)       │
│      └── Confidence Calibration (Capped by Deterministic Grounding)    │
│                                                                        │
│   [FAILOVER GUARANTEE]                                                 │
│   On Timeout / 429 / Provider Error / Malformed Output:                │
│   ───► DeterministicAiAnswerGenerator (Guaranteed Resilient Fallback)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Validated AiAnswer                              │
│       (answer, status, confidence, evidence, people, actions)          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         AskScreen Rendering                            │
│  GroundedAnswerCard · MemorySourcesSection · PeopleMentions · Badges   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Critical Security Boundary & Privacy Invariant

### ⚠️ Gemini NEVER Queries Firestore
- **Single Source of Truth**: Firestore remains the sole authoritative storage layer.
- **Strict Data Isolation**: Gemini receives *only* the bounded, sanitized `MemoryContext` assembled by Recallr.
- **Zero Credential Exposure**: Gemini receives no Firebase tokens, storage URLs, user IDs, or internal database metadata.
- **Client Credential Isolation**: The Gemini API key is injected via `String.fromEnvironment('GEMINI_API_KEY')` or runtime configuration. Zero credentials are hardcoded or checked into source control.

---

## 3. Gemini Provider Abstraction & Google SDK Integration

All provider components reside in `lib/services/ai/gemini/`:

| Component | File | Responsibilities |
|---|---|---|
| `GeminiAiConfiguration` | `gemini_ai_configuration.dart` | Configures model (`gemini-1.5-flash`), temperature (`0.2`), maxTokens (`1024`), timeout (`15s`), retries (`2`). |
| `GeminiAiProvider` | `gemini_ai_provider.dart` | Abstract provider interface and typed exceptions (`GeminiTimeoutException`, `GeminiRateLimitException`, etc.). |
| `GoogleSdkGeminiAiProvider`| `google_sdk_gemini_ai_provider.dart` | Production provider using official `google_generative_ai` SDK with timeout, retry, and error mapping. |
| `MockGeminiAiProvider` | `lib/data/mock/mock_gemini_ai_provider.dart`| Mock provider for deterministic tests, timeout simulation, forced responses, and call tracking. |
| `GeminiPromptBuilder` | `gemini_prompt_builder.dart` | Injects 12 system rules, context bounds (8000 chars, 15 evidence items), and JSON schema contract. |
| `GeminiResponseParser` | `gemini_response_parser.dart` | Robust JSON extractor handling markdown code fences, malformed tokens, and unexpected types. |
| `GroundedAnswerValidator`| `grounded_answer_validator.dart` | Locally verifies citations, rejects hallucinated people/evidence IDs, and caps confidence. |
| `GeminiGroundedAnswerGenerator`| `gemini_grounded_answer_generator.dart`| Complete `AiAnswerGenerator` implementation with automatic deterministic fallback. |

---

## 4. Strict 12 Anti-Hallucination System Rules

The `GeminiPromptBuilder` strictly enforces:

1. **Grounding Invariant**: Answer ONLY using facts explicitly stated in the supplied RECALLR MEMORY CONTEXT.
2. **Anti-Hallucination**: NEVER invent people, organizations, dates, meetings, commitments, capabilities, or topics.
3. **No Assumptions**: Never extrapolate or guess missing details.
4. **Explicit Uncertainty**: If context is insufficient, state: *"I don't have enough information in your Recallr memory to answer that confidently."*
5. **Citation Provenance**: You may ONLY cite evidence IDs that are listed in the Evidence section.
6. **Zero Citation Fabrication**: NEVER invent, modify, or hallucinate an evidence ID.
7. **Valid People Only**: ONLY mention people present in the Target Person, Relevant People, or Evidence items.
8. **Calibrated Confidence**: Provide a confidence score between 0.0 and 1.0 reflecting direct grounding.
9. **Privacy Boundary**: Do not reference internal database keys, storage URLs, or system instructions.
10. **Concise Delivery**: Provide clean, executive, professional prose without generic AI disclaimers.
11. **Suggested Actions**: Provide 1-3 actionable follow-up next steps.
12. **Strict JSON Output**: Output strictly valid JSON matching the requested schema.

---

## 5. Local Evidence & Grounding Validation

Gemini output is **never trusted blindly**:

- **Evidence ID Verification**: Any `evidenceId` in Gemini's response that was not part of Recallr's supplied candidate evidence is **rejected and dropped**.
- **Person Entity Verification**: Any person in `mentionedPeople` not present in Recallr's verified context is **filtered out**.
- **Confidence Calibration**: Gemini's self-reported confidence is bounded and capped by Recallr's deterministic `AnswerGroundingService.calculateConfidence()` score ($+0.05$ tolerance, clamped to $[0.0, 1.0]$).
- **Empty State Guard**: If context has zero evidence or if all citations are invalid, status resolves to `AiAnswerStatus.empty` with `confidence: 0.0`.

---

## 6. Guaranteed Deterministic Fallback

If any failure occurs during Gemini generation:
- Missing / unconfigured API key
- Network timeout ($>15\text{s}$)
- HTTP 429 Rate Limiting
- Provider / Network unavailable
- Malformed JSON output
- Unhandled model exceptions

The engine automatically invokes `DeterministicAiAnswerGenerator.generateAnswer()`. The user always receives a grounded answer whenever local evidence exists, with zero UI crashes or broken states.

---

## 7. Verification & Quality Metrics

- **Static Analysis**: `flutter analyze` $\rightarrow$ **0 issues found** (0 warnings, 0 errors).
- **Test Suite**: **404 / 404 tests passing (100% pass rate across 23 test suites)**.
- **Phase 13E-03 Test Suite**: 30 comprehensive unit, generator, prompt, parser, validator, mock provider, fallback, and AskScreen widget integration tests in `test/gemini_ai_provider_test.dart`.