import HTTPTypes

public enum RuntimeError: Error, Sendable {
    case unknown
    case emptyModelList
    case invalidApiURL(String)
    case reveiveUnsupportedContentTypeInResponse
    case httpError(HTTPResponse.Status, String?)
    case emptyResponseBody
    case unsupportedModelProvider(LLMProviderType)
    case skipByRetryAdvice
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
