import Testing
@testable import GPT
import Dispatch

@Suite("RetryAdviser Tests")
struct RetryAdviserTests {
    
    @Test("BackOffPolicy simple delay")
    func testSimpleBackOffPolicy() {
        let policy = RetryAdviser.BackOffPolicy.simple(delay: 1000)
        #expect(policy.delay(1) == 1000)
        #expect(policy.delay(5) == 1000)
    }
    
    @Test("BackOffPolicy exponential delay")
    func testExponentialBackOffPolicy() {
        let policy = RetryAdviser.BackOffPolicy.exponential(delay: 100, maxDelay: 10000, multiplier: 2)
        #expect(policy.delay(0) == 0)
        #expect(policy.delay(1) == 100)
        #expect(policy.delay(2) == 200)
        #expect(policy.delay(3) == 400)
        #expect(policy.delay(10) == 10000)
    }
    
    @Test("BackOffPolicy exponential delay with multiplier 2")
    func testExponentialBackOffPolicyWithMultiplier1() {
        let policy = RetryAdviser.BackOffPolicy.exponential(delay: 100, maxDelay: 10000, multiplier: 2)
        #expect(policy.delay(0) == 0)
        #expect(policy.delay(1) == 100)
        #expect(policy.delay(2) == 200)
        #expect(policy.delay(3) == 400)
    }

    @Test("Strategy initialization with defaults")
    func testStrategyDefaultInit() {
        let strategy = RetryAdviser.Strategy()
        #expect(strategy.maxAttemptsPerProvider == 3)
        #expect(strategy.preferNextProvider == true)
    }
    
    @Test("Strategy initialization with custom values")
    func testStrategyCustomInit() {
        let strategy = RetryAdviser.Strategy(
            maxAttemptsPerProvider: 5,
            preferNextProvider: false,
            backOff: .exponential(delay: 200, maxDelay: 5000, multiplier: 3)
        )
        #expect(strategy.maxAttemptsPerProvider == 5)
        #expect(strategy.preferNextProvider == false)
    }
    
    @Test("RetryAdviser skip without model")
    func testSkipWithoutModel() {
        let adviser = RetryAdviser()
        let context = RetryAdviser.Context(model: nil, errors: [])
        #expect(adviser.skip(context) == true)
    }
    
    @Test("RetryAdviser skip with no cached advice")
    func testSkipWithNoCachedAdvice() {
        let adviser = RetryAdviser()
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        let context = RetryAdviser.Context(model: model, errors: [])
        #expect(adviser.skip(context) == false)
    }
    
    @Test("RetryAdviser skip with skip advice")
    func testSkipWithSkipAdvice() {
        let adviser = RetryAdviser()
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        adviser.cached.withLock { $0[model] = .skip }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        #expect(adviser.skip(context) == true)
    }
    
    @Test("RetryAdviser skip with wait advice (not expired)")
    func testSkipWithWaitAdviceNotExpired() {
        let adviser = RetryAdviser()
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        let now = DispatchTime.now().uptimeNanoseconds
        adviser.cached.withLock { 
            $0[model] = .wait(base: now, count: 1, delay: 1_000_000_000)
        }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        #expect(adviser.skip(context) == true)
    }
    
    @Test("RetryAdviser skip with wait advice (expired)")
    func testSkipWithWaitAdviceExpired() {
        let adviser = RetryAdviser()
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        let past = DispatchTime.now().uptimeNanoseconds - 2_000_000_000
        adviser.cached.withLock { 
            $0[model] = .wait(base: past, count: 1, delay: 1_000_000_000)
        }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        #expect(adviser.skip(context) == false)
    }
    
    @Test("RetryAdviser retry with preferNextProvider")
    func testRetryWithPreferNextProvider() {
        let strategy = RetryAdviser.Strategy(preferNextProvider: true)
        let adviser = RetryAdviser(strategy: strategy)
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        let context = RetryAdviser.Context(model: model, errors: [])
        let error = RuntimeError.unknown
        
        #expect(adviser.retry(context, error: error) == nil)
    }
    
    @Test("RetryAdviser retry without model")
    func testRetryWithoutModel() {
        let strategy = RetryAdviser.Strategy(preferNextProvider: false)
        let adviser = RetryAdviser(strategy: strategy)
        let context = RetryAdviser.Context(model: nil, errors: [])
        let error = RuntimeError.unknown
        
        #expect(adviser.retry(context, error: error) == nil)
    }
    
    @Test("RetryAdviser retry with skip advice")
    func testRetryWithSkipAdvice() {
        let strategy = RetryAdviser.Strategy(preferNextProvider: false)
        let adviser = RetryAdviser(strategy: strategy)
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        adviser.cached.withLock { $0[model] = .skip }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        let error = RuntimeError.unknown
        
        #expect(adviser.retry(context, error: error) == nil)
    }
    
    @Test("RetryAdviser retry with invalidApiURL error")
    func testRetryWithInvalidApiURLError() {
        let strategy = RetryAdviser.Strategy(preferNextProvider: false)
        let adviser = RetryAdviser(strategy: strategy)
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        adviser.cached.withLock { 
            $0[model] = .wait(base: 0, count: 0, delay: 0)
        }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        let error = RuntimeError.invalidApiURL("test")
        
        let result = adviser.retry(context, error: error)
        #expect(result != nil)
        
        let cachedAdvice = adviser.cached.withLock { $0[model] }
        #expect(cachedAdvice == .skip)
    }
    
    @Test("RetryAdviser retry with HTTP error")
    func testRetryWithHTTPError() {
        let strategy = RetryAdviser.Strategy(preferNextProvider: false)
        let adviser = RetryAdviser(strategy: strategy)
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        adviser.cached.withLock { 
            $0[model] = .wait(base: 0, count: 0, delay: 0)
        }
        
        let context = RetryAdviser.Context(model: model, errors: [])
        let error = RuntimeError.httpError(.internalServerError, "Server error")
        
        let result = adviser.retry(context, error: error)
        #expect(result != nil)
        
        let cachedAdvice = adviser.cached.withLock { $0[model] }
        if case .wait(_, let count, _) = cachedAdvice {
            #expect(count == 1)
        } else {
            Issue.record("Expected wait advice")
        }
    }
    
    @Test("RetryAdviser cleanCache")
    func testCleanCache() {
        let adviser = RetryAdviser()
        let provider = LLMProviderConfiguration(
            type: .OpenAI,
            name: "Test",
            apiKey: "test-key",
            apiURL: "https://api.test.com"
        )
        let model = LLMModelReference(
            model: LLMModel(name: "test-model"),
            provider: provider
        )
        
        adviser.cached.withLock { $0[model] = .skip }
        
        adviser.cleanCache(model: model)
        
        let cachedAdvice = adviser.cached.withLock { $0[model] }
        #expect(cachedAdvice == nil)
    }
}
