# Understanding the Retry Policy

`swift-gpt` includes a robust retry mechanism to handle transient errors and improve the reliability of your LLM interactions. This is managed by the ``RetryAdviser``.

## Default Behavior

By default, the ``GPTSession`` uses a shared ``RetryAdviser`` with a sensible default strategy. If a request to an LLM fails, the adviser will attempt to retry the request up to 3 times with the same model. If all attempts for a model fail, it will move on to the next model in the `LLMQualifiedModel` list, if available.

## Customizing the Retry Strategy

You can create your own ``RetryAdviser`` with a custom ``RetryAdviser/Strategy`` to change the retry behavior.

### Strategy Options

- `maxAttemptsPerProvider`: The maximum number of times to retry a request with the same model before moving to the next.
- `preferNextProvider`: If `true`, the adviser will immediately try the next model in the list upon failure. If `false`, it will exhaust the `maxAttemptsPerProvider` for the current model before moving on.
- `backOff`: The backoff policy to use between retries. This can be a simple delay or an exponential backoff.

### Example: Custom Strategy

Here's how you can create a `GPTSession` with a custom retry strategy that uses exponential backoff and retries up to 5 times per model.

```swift
import GPT
import Foundation

// Define a custom backoff policy
let exponentialBackoff = RetryAdviser.BackOffPolicy.exponential(
    delay: 100 * 1_000_000, // 100ms in nanoseconds
    maxDelay: 5 * 1_000_000_000, // 5s in nanoseconds
    multiplier: 2.0
)

// Create a custom strategy
let customStrategy = RetryAdviser.Strategy(
    maxAttemptsPerProvider: 5,
    preferNextProvider: false,
    backOff: exponentialBackoff
)

// Create a RetryAdviser with the custom strategy
let customAdviser = RetryAdviser(strategy: customStrategy)

// Create a GPTSession with the custom adviser
let session = GPTSession(client: yourClientTransport, retryAdviser: customAdviser)
```

Now, any requests made with this `session` will use your custom retry policy.
