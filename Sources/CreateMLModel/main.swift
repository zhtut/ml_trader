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
        logInfo("开始生成模型")
        // 初始化binacne
        let creater = ModelCreator()
        try await creater.create()
        exit(0)
    } catch {
        logInfo("生成失败: \(error)")
        exit(1)
    }
}

/// 当主线程增加一个runloop防止退出
RunLoop.current.add(SocketPort(), forMode: .default)
RunLoop.current.run()
