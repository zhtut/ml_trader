//
//  File.swift
//  
//
//  Created by tutuzhou on 2024/1/19.
//

import Foundation

/// k线接口管理器
open class CandleManager {
    
    /// symbol，全大写，BTCUSDT
    open var instId: String = "BTCUSDT"
    
    /// k线类型，如,5m, 1d
    open var intervalStr: String = "5m"
    
    /// 分钟转换成秒，需要跟上面的一致
    open var interval = 300
    
    /// 请求条数
    open var limit: Int = 1500
    
    public init() {
        
    }
    
    /// 请求k线数据
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - limit: 限制条数
    /// - Returns: 返回k线数组
    open func requestCandles(startTime: Int? = nil, limit: Int? = nil) async throws -> (response: HTTPURLResponse, candles: [Candle]) {
        let path = "GET /api/v1/klines"
        var params = ["symbol": instId, "interval": intervalStr] as [String: Any]
        if let startTime = startTime {
            params["startTime"] = startTime
        }
        params["limit"] = limit ?? self.limit
        let response = await RestAPI.send(path: path, params: params)
        if response.succeed {
            if let data = response.data as? [[Any]] {
                var candles = [Candle]()
                for arr in data {
                    let candle = Candle(array: arr)
                    candles.append(candle)
                }
                return (response.res.urlResponse!, candles)
            } else {
                throw CommonError(message: "data类型不对")
            }
        } else {
            logInfo("请求k线失败：\(response.errMsg ?? "")")
            throw CommonError(message: response.errMsg ?? "")
        }
    }
}
