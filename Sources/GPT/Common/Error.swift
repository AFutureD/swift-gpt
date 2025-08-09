import HTTPTypes

public enum RuntimeError: Error, Sendable {
    case unknown
    case invalidApiURL(String)
    case reveiveUnsupportedContentTypeInResponse
    case httpError(HTTPResponse.Status, String?)
    case emptyResponseBody
    case unsupportedModelProvider(LLMProviderType)
    case skipByRetryAdvice
    case retryFailed([Error])
}
