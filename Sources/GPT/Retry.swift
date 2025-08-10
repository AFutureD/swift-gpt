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
        case exponential(delay: UInt64, maxDelay: UInt64, multiplier: Double)
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
        switch self {
        case let .simple(delay):
            return delay
        case let .exponential(delay, maxDelay, multiplier):
            guard count > 0 else { return 0 }
            return min(delay * UInt64(pow(multiplier, Double(count - 1))), maxDelay)
        }
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
        case let .wait(base: base, count: _, delay: delay):
            return base + delay > now
        case nil:
            return false
        }
    }

    // return retry time or current model, return nil to skip.
    func retry(_ context: Context, error: any Error) -> UInt64? {
        guard let model = context.model else { return nil }
        let previous = self.cached.withLock { $0[model] }
        
        if case .skip = previous { return nil }
        
        let count: UInt = if case .wait(_, let count, _) = previous {
            count + 1
        } else {
            1
        }
        
        let delay = strategy.backOff.delay(count)
        
        let advice = getAdvice(count: count, error: error, delay: delay)
        self.cached.withLock { $0[model]  = advice }
        
        if self.strategy.preferNextProvider {
            return nil
        } else {
            return count <= strategy.maxAttemptsPerProvider ? delay : nil
        }
    }
    
    func getAdvice(count: UInt, error: any Error, delay: UInt64) -> Advice {
        let now = timeNow()
        
        if let err = error as? RuntimeError {
            switch err {
            case .invalidApiURL(_), .unsupportedModelProvider(_):
                return .skip
            case .httpError(_, _):
                return .wait(base: now, count: count, delay: delay)
            default:
                return .wait(base: now, count: count, delay: delay)
            }
        } else {
            return .wait(base: now, count: count, delay: delay)
        }
    }
}



import Dispatch

/// A convenience method to get system UPTIME.
///
/// A better method may refer to `NIODeadline.timeNow()`, but in out satiation we do not need such accuracy.
fileprivate func timeNow() -> UInt64 {
    return DispatchTime.now().uptimeNanoseconds
}
