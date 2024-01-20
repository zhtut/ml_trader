//
//  File.swift
//  
//
//  Created by shutut on 2021/9/5.
//

import Foundation
import BinanceSupport

Task {
    do {
        guard let configURL = Bundle.module.url(forResource: "config", withExtension: "json") else {
            logInfo("初始化失败, MLTrader/Resources目录下没有发现config.json")
            exit(1)
        }
        logInfo("config路径：\(configURL)")
        // 初始化binacne
        try await Setup.shared.setup(configURL)
        
        // 启动交易引擎
        _ = MLTrader.shared
    } catch {
        logInfo("初始化失败: \(error)")
        exit(1)
    }
}

/// 当主线程增加一个runloop防止退出
RunLoop.current.add(SocketPort(), forMode: .default)
RunLoop.current.run()
