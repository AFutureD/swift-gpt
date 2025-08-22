# Getting Started with swift-gpt

This guide provides a basic example of how to use `swift-gpt` to send a prompt to an LLM and receive a response.

## 1. Import GPT

First, import the `GPT` module in your Swift file.

```swift
import GPT
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient
```

## 2. Configure the Provider and Model

You need to configure the LLM provider and the model you want to use. This includes the API key and URL for the provider.

```swift
// Configure your provider
let openAIProvider = LLMProviderConfiguration(
    type: .OpenAI,
    name: "OpenAI",
    apiKey: "YOUR_OPENAI_API_KEY",
    apiURL: "https://api.openai.com"
)

// Specify the model
let gpt4o = LLMModelReference(
    model: LLMModel(name: "gpt-4o"),
    provider: openAIProvider
)
```

## 3. Create a GPTSession

The ``GPTSession`` is the main entry point for interacting with the LLM. You need to provide a `ClientTransport` for the session to use for network requests.

```swift
// Create a client transport
let client = Client(
    transport: AsyncHTTPClientTransport(
        configuration: .init(
            redirectConfiguration: .follow(max: 5)
        )
    )
)

// Create a GPTSession
let session = GPTSession(client: client)
```

## 4. Create a Prompt

A ``Prompt`` contains the input for the LLM. You can include system instructions and a series of inputs.

```swift
// Create a prompt
let prompt = Prompt(
    instructions: "You are a helpful assistant.",
    inputs: [
        .text(.init(role: .user, content: "Hello, who are you?"))
    ],
    stream: false // For non-streaming responses
)
```

## 5. Generate a Response

Use the `generate(prompt:model:)` method of the ``GPTSession`` to get a complete response from the LLM.

```swift
do {
    let response = try await session.generate(prompt, model: gpt4o)
    if let message = response.items.first?.message,
       let content = message.content?.first?.text?.content {
        print("Response: \(content)")
    }
} catch {
    print("Error: \(error)")
}
```

## Streaming Responses

To stream a response, set `stream: true` in the ``Prompt`` and use the `stream(prompt:model:)` method.

```swift
let streamingPrompt = Prompt(
    instructions: "You are a helpful assistant.",
    inputs: [
        .text(.init(role: .user, content: "Tell me a story."))
    ],
    stream: true
)

do {
    let stream = try await session.stream(streamingPrompt, model: gpt4o)
    for try await event in stream {
        if case .contentDelta(let deltaEvent) = event,
           let delta = deltaEvent.data.text?.delta {
            print(delta, terminator: "")
        }
    }
    print()
} catch {
    print("Error: \(error)")
}
