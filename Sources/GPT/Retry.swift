//
//  Retry.swift
//  swift-gpt
//
//  Created by AFuture on 2025/8/4.
//

import SynchronizationKit
import LazyKit

extension RetryAdviser {
    // in nano seconds
    public enum BackOffPolicy: Sendable {
        case simple(delay: UInt64)
        case exponential(base: UInt64, max: UInt64, multiplier: Int)
    }
    
    public struct Strategy: Sendable {
        let preferNextProvider: Bool
        let maxAttemptsPerProvider: Int
        
        let backOff: BackOffPolicy
        
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
    enum Advice: Hashable {
        case wait(base: UInt64, count: UInt, delay: UInt64)
        case skip
    }
}

extension RetryAdviser.BackOffPolicy {
    func delay(_ count: UInt) -> UInt64 {
        0
    }
}


extension RetryAdviser {
    struct Context {
        var model: LLMModelReference?
        var errors: [Error] = []
    }
}


public final class RetryAdviser: Sendable {
    public static let shared = RetryAdviser()
    
    let strategy: Strategy
    
    let cached: LazyLockedValue<[LLMModelReference: Advice]>
    
    public init(
        strategy: Strategy = .init()
    ) {
        self.strategy = strategy
        self.cached = .init([:])
    }
        
    func cleanCache(model: LLMModelReference) {
        self.cached.withLock { $0[model] = nil }
    }

    func skip(_ context: Context) -> Bool {
        guard let model = context.model else {
            return true
        }
        
        let advice = cached.withLock { $0[model] }
        
        let now = timeNow()
        
        switch advice {
        case .skip:
            return true
        case let .wait(base: base, count: count, delay: delay):
            return base + delay > now
        case nil:
            return false
        }
    }

    func retry(_ context: Context, error: any Error) -> Bool {
        if self.strategy.preferNextProvider { return false }
        
        guard let model = context.model else { return false }
        let previous = self.cached.withLock { $0[model] }
        
        if case .skip = previous { return false }
        guard case .wait(_, let count, _) = previous else { unreachable() }
        
        let backoff = self.strategy.backOff
        let delay = backoff.delay(count)
        
        let now = timeNow()
        
        let advice: Advice
        if let err = error as? RuntimeError {
            switch err {
            case .invalidApiURL(_), .unsupportedModelProvider(_):
                advice = .skip
            case .httpError(let status, _):
                advice = .wait(base: now, count: count + 1, delay: delay)
            default:
                advice = .wait(base: now, count: count + 1, delay: delay)
            }
        } else {
            advice = .wait(base: now, count: count + 1, delay: delay)
        }
        
        self.cached.withLock { $0[model]  = advice }
        
        return true
    }
}



import Dispatch

/// A convenience method to get system UPTIME.
///
/// A better method may refer to `NIODeadline.timeNow()`, but in out satiation we do not need such accuracy.
fileprivate func timeNow() -> UInt64 {
    return DispatchTime.now().uptimeNanoseconds
}
