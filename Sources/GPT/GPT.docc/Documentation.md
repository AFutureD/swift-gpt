# ``GPT``

A Swift package for interacting with Large Language Models (LLMs) from various providers.

## Overview

`swift-gpt` provides a unified interface for sending prompts to different LLM providers like OpenAI and OpenAI-compatible services. It supports both streaming and non-streaming responses, features a robust retry mechanism, and is designed for extensibility.

### Key Features

- **Multiple Providers**: Interact with different LLM providers through a single API.
- **Streaming and Non-Streaming**: Choose between receiving a complete response or streaming partial results as they become available.
- **Automatic Retries**: Built-in retry logic with configurable strategies to handle transient network issues or model failures.
- **Type-Safe**: Leverages Swift's type system to ensure correctness and provide a great developer experience.

## Topics

### Getting Started

- ``QuickStart``
- ``GPTSession``
- ``Prompt``

### Models and Providers

- ``LLMProviderConfiguration``
- ``LLMModel``
- ``LLMModelReference``
- ``LLMQualifiedModel``

### Responses

- ``ModelResponse``
- ``ModelStreamResponse``
- ``MessageItem``
- ``TextContent``
- ``TextRefusalContent``

### Prompt Building

- ``Prompt/Input``
- ``Prompt/Input/TextContent``
- ``Prompt/Input/FileContent``
- ``ModelInputContentRole``

### Reliability

- ``RetryAdviser``
- ``RetryAdviser/Strategy``
- ``RetryAdviser/BackOffPolicy``

### Errors

- ``RuntimeError``
