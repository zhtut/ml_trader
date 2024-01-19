//
//  File.swift
//  
//
//  Created by zhtut on 2023/10/20.
//

import Foundation
import BinanceSupport

/// 订单管理器
class OrderManager {
    
    static let shared = OrderManager()
    
    var instId: String
    
    /// 下单BTCFDUSD，观察的是BTCUSDT，因为BTCFDUSD免交易手续费，但是BTCUSDT交易量大
    init(instId: String = "BTCFDUSD") {
        self.instId = instId
    }
    
    /// btc余额
    var btcBalance: CGFloat {
        let btc = BalanceManager.shared.balances
            .first(where: { $0.asset.uppercased() == "BTC" })
        return btc?.free.double ?? 0.0
    }
    
    /// fdusd余额
    var fdusdBalance: CGFloat {
        let fdusd = BalanceManager.shared.balances
            .first(where: { $0.asset.uppercased() == "FDUSD" })
        return fdusd?.free.double ?? 0.0
    }
    
    /// 收到上涨的信号
    func orderUp() {
        logInfo("收到上涨的信号")
        if fdusdBalance < 1 {
            logInfo("当前fdusd数量小于1,无法购买")
            return
        }
        let fusd = fdusdBalance
        logInfo("当前有\(fusd)个fusd，买进这些")
        Task {
            let path = "POST /api/v3/order (HMAC SHA256)"
            var params = [String: Any]()
            params["symbol"] = instId
            params["side"] = "BUY"
            params["type"] = "MARKET"
            params["quoteOrderQty"] = Int(fusd)
            let res = try await RestAPI.post(path: path, params: params)
            if res.succeed {
                logInfo("买进成功")
            } else {
                logInfo("买进失败：\(res.errMsg ?? "")")
            }
        }
    }
    
    /// 收到下跌的信号
    func orderDown() {
        logInfo("收到下跌的信号")
        orderClose()
    }
    
    /// 收到清仓的信号
    func orderClose() {
        if btcBalance < 0.00001 {
            logInfo("当前btc数量小于0.00001, 无需卖出")
            return
        }
        let btc = btcBalance
        logInfo("当前有\(btc)个btc，全部卖掉")
        Task {
            let path = "POST /api/v3/order (HMAC SHA256)"
            var params = [String: Any]()
            params["symbol"] = instId
            params["side"] = "SELL"
            params["type"] = "MARKET"
            params["quantity"] = btc
            let res = try await RestAPI.post(path: path, params: params)
            if res.succeed {
                logInfo("卖出成功")
            } else {
                logInfo("卖出失败：\(res.errMsg ?? "")")
            }
        }
    }
}
