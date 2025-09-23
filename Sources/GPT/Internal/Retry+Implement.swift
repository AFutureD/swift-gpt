//
//  Retry+Implement.swift
//  swift-gpt
//
//  Created by AFuture on 2025-08-15.
//

import CoreFoundation

/// Internal implementation of the retry logic.
extension RetryAdviser.BackOffPolicy {
    /// Calculates the delay for a given retry count.
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
    /// Clears the cached advice for a given model.
    func cleanCache(model: LLMModelReference) {
        self.cached.withLock { $0[model] = nil }
    }
    
    /// Determines whether to skip a model based on cached advice.
    func skip(_ context: Context) -> Bool {
        guard let model = context.current else {
            return true
        }
        
        let advice = cached.withLock { $0[model] }
        
        let now = uptimeInNanoseconds()
        
        switch advice {
        case .skip:
            return true
        case let .wait(base: base, count: _, delay: delay):
            return base + delay > now
        case nil:
            return false
        }
    }
    
    /// Determines the retry delay for a given context and error.
    /// - Returns: The delay in nanoseconds, or `nil` to skip to the next model.
    func retry(_ context: Context, error: any Error) -> UInt64? {
        guard let model = context.current else { return nil }
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
    
    /// Generates advice based on the error and retry count.
    func getAdvice(count: UInt, error: any Error, delay: UInt64) -> Advice {
        let now = uptimeInNanoseconds()
        
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
