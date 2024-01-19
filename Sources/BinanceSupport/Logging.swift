//
//  File.swift
//  
//
//  Created by zhtut on 2023/10/20.
//

import Foundation
@_exported import Logging
@_exported import Binance
@_exported import UtilCore
@_exported import Networking

public let logger: Logger = {
    var logger = Logger(label: "Logger")
    logger.logLevel = .info
    return logger
}()

public func logInfo(_ info: String) {
    logger.info("\(info)")
}

public func logError(_ error: String) {
    logger.error("\(error)")
}
