# swift-gpt

A Swift package for interacting with Large Language Models (LLMs) from various providers.

## Overview

`swift-gpt` provides a unified interface for sending prompts to different LLM providers like OpenAI and OpenAI-compatible services. It supports both streaming and non-streaming responses, features a robust retry mechanism, and is designed for extensibility.

### Key Features

- **Multiple Providers**: Interact with different LLM providers through a single API.
- **Streaming and Non-Streaming**: Choose between receiving a complete response or streaming partial results as they become available.
- **Automatic Retries**: Built-in retry logic with configurable strategies to handle transient network issues or model failures.
- **Type-Safe**: Leverages Swift's type system to ensure correctness and provide a great developer experience.

## Installation

Add `swift-gpt` as a dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/AFutureD/swift-gpt.git", branch: "main")
```

## Usage

Here's a basic example of how to use `swift-gpt` to generate a response:

```swift
import GPT
import OpenAPIRuntime
import OpenAPIAsyncHTTPClient

// 1. Configure your provider
let openAIProvider = LLMProviderConfiguration(
    type: .OpenAI,
    name: "OpenAI",
    apiKey: "YOUR_OPENAI_API_KEY",
    apiURL: "https://api.openai.com/v1"
)

// 2. Specify the model
let gpt4o = LLMModelReference(
    model: LLMModel(name: "gpt-4o"),
    provider: openAIProvider
)

// 3. Create a GPTSession
let client = AsyncHTTPClientTransport()
let session = GPTSession(client: client)

// 4. Create a prompt
let prompt = Prompt(
    instructions: "You are a helpful assistant.",
    inputs: [
        .text(.init(role: .user, content: "Hello, who are you?"))
    ],
    stream: false // For non-streaming responses
)

// 5. Generate a response
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