import HTTPTypes

/// An enumeration of runtime errors that can occur in `swift-gpt`.
public enum RuntimeError: Error, Sendable {
    /// An unknown or unexpected error occurred.
    case unknown
    /// The list of models to try was empty.
    case emptyModelList
    /// The provided API URL was invalid.
    case invalidApiURL(String)
    /// The response from the server had an unsupported content type.
    case reveiveUnsupportedContentTypeInResponse
    /// An HTTP error occurred during the request.
    case httpError(HTTPResponse.Status, String?)
    /// The response body was empty when content was expected.
    case emptyResponseBody
    /// The specified model provider is not supported.
    case unsupportedModelProvider(LLMProviderType)
    /// The request was skipped based on the ``RetryAdviser``'s advice.
    case skipByRetryAdvice
    /// All retry attempts failed for all available models.
    case retryFailed([Error])
}

extension RuntimeError: Equatable {
    public static func == (lhs: RuntimeError, rhs: RuntimeError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.emptyModelList, .emptyModelList):
            return true
        case (.invalidApiURL(let lhsURL), .invalidApiURL(let rhsURL))   :
            return lhsURL == rhsURL
        case (.reveiveUnsupportedContentTypeInResponse, .reveiveUnsupportedContentTypeInResponse):
            return true
        case (.httpError(let lhsStatus, let lhsBody), .httpError(let rhsStatus, let rhsBody)):
            return lhsStatus == rhsStatus && lhsBody == rhsBody
        case (.emptyResponseBody, .emptyResponseBody):
            return true
        case (.unsupportedModelProvider(let lhsProvider), .unsupportedModelProvider(let rhsProvider)):
            return lhsProvider == rhsProvider
        case (.skipByRetryAdvice, .skipByRetryAdvice):
            return true
        case (.retryFailed(_), .retryFailed(_)):
            return true
        default:
            return false
        }   
    }
}
