//
//  MarketMakerTests.swift
//  
//
//  Created by zhtg on 2022/2/27.
//

import XCTest

@testable import MLTrader
@testable import BinanceSupport

class MLTraderTests: XCTestCase {
    
    func testOrder() async throws {
        // 准备工作
        guard let configURL = Bundle.module.url(forResource: "config", withExtension: "json") else {
            logInfo("初始化失败, MLTrader/Resources目录下没有发现config.json")
            exit(1)
        }
        try await Setup.shared.setup(configURL)
        // 开始测试
        let path = "POST /api/v3/order/test (HMAC SHA256)"
        var params = [String: Any]()
        params["symbol"] = "BTCFDUSD"
        params["side"] = "SELL"
        params["type"] = "MARKET"
        params["quantity"] = "0.001"
        let res = try await RestAPI.post(path: path, params: params)
        if res.succeed {
            logInfo("卖出成功")
        } else {
            logInfo("卖出失败：\(res.errMsg ?? "")")
        }
    }
}
