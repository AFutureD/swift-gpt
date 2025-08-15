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
    // in nano seconds
    public enum BackOffPolicy: Sendable {
        case simple(delay: UInt64)
        case exponential(delay: UInt64, maxDelay: UInt64, multiplier: Double)
    }
    
    public struct Strategy: Sendable {
        public let preferNextProvider: Bool
        public let maxAttemptsPerProvider: Int
        
        public let backOff: BackOffPolicy
        
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
    public enum Advice: Hashable, Sendable {
        case wait(base: UInt64, count: UInt, delay: UInt64)
        case skip
    }
}

extension RetryAdviser {
    public struct Context {
        var model: LLMModelReference?
        var errors: [Error] = []
    }
}


public final class RetryAdviser: Sendable {
    public static let shared = RetryAdviser()
    
    public let strategy: Strategy
    
    let cached: LazyLockedValue<[LLMModelReference: Advice]>
    
    public init(
        strategy: Strategy = .init()
    ) {
        self.strategy = strategy
        self.cached = .init([:])
    }
}
