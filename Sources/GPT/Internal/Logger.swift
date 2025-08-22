//
//  Logger.swift
//  swift-gpt
//
//  Created by AFuture on 2025/8/4.
//

import Logging

/// Internal extension for creating a disabled logger.
extension Logger {
    /// A logger that performs no operations.
    static let disabled = Logger(label: "com.swift-gpt.disabled", factory: { _ in SwiftLogNoOpLogHandler() })
}
