# Changelog

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
