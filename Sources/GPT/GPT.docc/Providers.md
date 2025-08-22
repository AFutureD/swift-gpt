# Configuring LLM Providers

`swift-gpt` is designed to work with multiple LLM providers. You can configure each provider with its own API key and URL.

## Supported Providers

Currently, `swift-gpt` supports the following provider types:

- ``LLMProviderType/OpenAI``: For OpenAI's official API.
- ``LLMProviderType/OpenAICompatible``: For services that are compatible with the OpenAI API, such as local LLMs or other cloud providers.
- ``LLMProviderType/Gemini``: For Google's Gemini models (note: this is a placeholder and may not be fully implemented).

## Configuring a Provider

To configure a provider, you create an instance of ``LLMProviderConfiguration``.

### OpenAI

For OpenAI, you would configure it like this:

```swift
import GPT

let openAIProvider = LLMProviderConfiguration(
    type: .OpenAI,
    name: "OpenAI",
    apiKey: "YOUR_OPENAI_API_KEY",
    apiURL: "https://api.openai.com"
)
```

### OpenAI-Compatible

For an OpenAI-compatible provider, you would use the `.OpenAICompatible` type and provide the appropriate URL.

```swift
import GPT

let localLLMProvider = LLMProviderConfiguration(
    type: .OpenAICompatible,
    name: "Local LLM",
    apiKey: "your-api-key-if-needed",
    apiURL: "http://localhost:8080"
)
```

## Using Multiple Models and Providers

You can use ``LLMQualifiedModel`` to provide a list of models to try in sequence. This is useful for fallback scenarios.

```swift
import GPT

// Define multiple models from different providers
let gpt4o = LLMModelReference(
    model: LLMModel(name: "gpt-4o"),
    provider: openAIProvider
)

let localModel = LLMModelReference(
    model: LLMModel(name: "local-model"),
    provider: localLLMProvider
)

// Create a qualified model with a fallback
let qualifiedModel = LLMQualifiedModel(
    name: "My Fallback Model",
    models: [gpt4o, localModel]
)

// Use the qualified model in a GPTSession
// If the request with gpt4o fails, it will automatically
// try localModel based on the retry strategy.
do {
    let response = try await session.generate(prompt, model: qualifiedModel)
    // ...
} catch {
    // ...
}
