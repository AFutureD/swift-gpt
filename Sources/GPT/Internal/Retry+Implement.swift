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
        case .simple(let delay):
            return delay
        case .exponential(let delay, let maxDelay, let multiplier):
            guard count > 0, delay > 0, maxDelay > 0 else { return 0 }
            let factor = pow(multiplier, Double(count - 1))
            // Double(UInt64.max) rounds up to 2^64, which is not convertible.
            // Check before conversion, then saturate before a product can trap.
            guard factor.isFinite, factor >= 0, factor < Double(UInt64.max) else {
                return maxDelay
            }
            let (scaled, overflow) = delay.multipliedReportingOverflow(by: UInt64(factor))
            return overflow ? maxDelay : min(scaled, maxDelay)
        }
    }
}

extension RetryAdviser {
    /// Clears the cached advice for a given model.
    func cleanCache(model: LLMModelReference) {
        cached.withLock { $0[model] = nil }
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
        case .wait(base: let base, count: _, delay: let delay):
            return now < base || now - base < delay
        case nil:
            return false
        }
    }

    /// Determines the retry delay for a given context and error.
    /// - Returns: The delay in nanoseconds, or `nil` to skip to the next model.
    func retry(_ context: Context, error: any Error) -> UInt64? {
        guard let model = context.current else { return nil }
        let previous = cached.withLock { $0[model] }

        if case .skip = previous { return nil }

        let count: UInt = if case .wait(_, let count, _) = previous {
            count == .max ? .max : count + 1
        } else {
            1
        }

        let delay = strategy.backOff.delay(count)

        let advice = getAdvice(count: count, error: error, delay: delay)
        cached.withLock { $0[model] = advice }

        if strategy.preferNextProvider {
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
            case .invalidApiURL(_), .unsupportedModelProvider:
                return .skip
            case .httpError:
                return .wait(base: now, count: count, delay: delay)
            default:
                return .wait(base: now, count: count, delay: delay)
            }
        } else {
            return .wait(base: now, count: count, delay: delay)
        }
    }
}
