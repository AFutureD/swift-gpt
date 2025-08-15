//
//  Dispatch+Time.swift
//  swift-gpt
//
//  Created by AFuture on 2025-08-15.
//

import Dispatch

/// A convenience method to get system UPTIME.
///
/// A better method may refer to `NIODeadline.timeNow()`, but in our saturation we do not need such accuracy.
internal func uptimeInNanoseconds() -> UInt64 {
    return DispatchTime.now().uptimeNanoseconds
}
