//
//  Retry.swift
//  swift-gpt
//
//  Created by AFuture on 2025/8/4.
//

import SynchronizationKit
import LazyKit
import Foundation

extension RetryAdviser {
    /// An enumeration of backoff policies for retrying requests.
    ///
    /// Delays are specified in nanoseconds.
    public enum BackOffPolicy: Sendable {
        /// A simple, fixed delay between retries.
        case simple(delay: UInt64)
        /// An exponential backoff with a maximum delay and a multiplier.
        case exponential(delay: UInt64, maxDelay: UInt64, multiplier: Double)
    }
    
    /// A strategy for retrying failed requests.
    public struct Strategy: Sendable {
        /// If `true`, the adviser will immediately try the next model in the list upon failure.
        /// If `false`, it will exhaust `maxAttemptsPerProvider` for the current model before moving on.
        public let preferNextProvider: Bool
        /// The maximum number of times to retry a request with the same model before moving to the next.
        public let maxAttemptsPerProvider: Int
        
        /// The backoff policy to use between retries.
        public let backOff: BackOffPolicy
        
        /// Creates a new retry strategy.
        ///
        /// - Parameters:
        ///   - maxAttemptsPerProvider: The maximum number of attempts per provider. Defaults to 3.
        ///   - preferNextProvider: Whether to prefer the next provider on failure. Defaults to `true`.
        ///   - backOff: The backoff policy. Defaults to a simple 100ms delay.
        public init(
            maxAttemptsPerProvider: Int = 3,
            preferNextProvider: Bool = true,
            backOff: BackOffPolicy = .simple(delay: 100 * 1_000_000)
        ) {
            self.maxAttemptsPerProvider = maxAttemptsPerProvider
            self.preferNextProvider = preferNextProvider
            self.backOff = backOff
        }
    }
}

extension RetryAdviser {
    /// An enumeration of advice from the ``RetryAdviser``.
    public enum Advice: Hashable, Sendable {
        /// Wait for a specified delay before retrying.
        case wait(base: UInt64, count: UInt, delay: UInt64)
        /// Skip the current model and move to the next.
        case skip
    }
}

extension RetryAdviser {
    /// The context for a retry decision, including the model being used and any errors that have occurred.
    public struct Context {
        var current: LLMModelReference?
        var errors: [String: Error] = [:]
        
        public mutating func append(_ err: Error) {
            guard let current else { return }

            errors[current.name] = err
        }
    }
}


/// A class that provides advice on whether and how to retry failed LLM requests.
public final class RetryAdviser: Sendable {
    /// A shared instance of `RetryAdviser` with a default strategy.
    public static let shared = RetryAdviser()
    
    /// The retry strategy used by this adviser.
    public let strategy: Strategy
    
    let cached: LazyLockedValue<[LLMModelReference: Advice]>
    
    /// Creates a new `RetryAdviser`.
    ///
    /// - Parameter strategy: The retry strategy to use. Defaults to the default strategy.
    public init(
        strategy: Strategy = .init()
    ) {
        self.strategy = strategy
        self.cached = .init([:])
    }
}
