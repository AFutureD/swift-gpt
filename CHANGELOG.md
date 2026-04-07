# Changelog

## 0.8.0 (2026-04-08)

Feature enhancements:

- Add `timeout` support to `GPTSession.generate`.

## 0.7.1 (2026-03-05)

Fix:

- fix first candidate will return in both contentDelta and contentAdd event when using gemini provider stream

## 0.7.0 (2026-03-04)

Feature enhancements:

- Include `provider` metadata in `GenerationConext` for generated and streamed responses.
- Add `Gemini` target. Using OpenAPI to generate types for [Gemini API](https://ai.google.dev/api/generate-content). 
- Add Gemini support.
- Add `ThinkingControl` and `ThinkingLevel` for reasoning controls.

## 0.6.0 (2025-11-04)

Feature enhancements:

- Add ExtraBody Support.
- `OpenAIChatCompletionStreamResponseAsyncAggregater` now support qwen-mt with `modelStreamResponseNotSupportDeltaContent` option in `GenerationConext`.
- Add Image Input Support.

## 0.5.1 (2025-10-21)

Feature enhancements:

- Introduce [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- Add attributes in tracing when collection response body failed.

## 0.5.0 (2025-10-18)

Feature enhancements:

- Added tracing support via `swift-distributed-tracing`.

## 0.4.0 (2025-10-12)

Feature enhancements:

- Added `ContextControl` and `GenerationControl` to simplify `Prompt`.
- Introduced `ConversationID` support via `GenerationContext`.

## 0.3.0 (2025-09-28)

Feature enhancements:

- Rewrote `OpenAIChatCompletionStreamResponseAsyncAggregater`.

## 0.2.0 (2025-09-23)

Feature enhancements:

- Rewrote types.
- Added convenience methods.
- Added conversation support.
- Rewrote provider conversion implementation.

## 0.1.1 (2025-09-22)

- Logged error details on retry failures.
