//
//  Logger.swift
//  swift-gpt
//
//  Created by AFuture on 2025/8/4.
//

import Logging

extension Logger {
    static let disabled = Self(label: "me.afuture.gpt", factory: { _ in SwiftLogNoOpLogHandler() })
}
