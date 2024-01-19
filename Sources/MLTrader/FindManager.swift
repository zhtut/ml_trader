//
//  FindChanceManager.swift
//  
//
//  Created by zhtg on 2022/3/12.
//

import Foundation
import BinanceSupport
import CoreML

class FindManager {
    
    /// 数据库检索时的k线相似度
    var contrastOffset: Decimal = 0.7
    
    /// 查找当前的k线
    func findCurrent() async {
        logInfo("正在请求当前K线")
        do {
            let candles = try await requestCurrent()
            logInfo("k线请求成功，开始判断")
            let completionCandles = candles.dropLast()
            logInfo("拿到\(completionCandles.count)个candles进行判断")
            logInfo("最后一个的时间是：\(completionCandles.last?.t.dateDesc ?? "")")
            guard completionCandles.count >= CandleModel.previousCount else {
                sendClosePositionSignal()
                return
            }
            
            // 转换成模型
            let candleModel = try CandleModel(previousCandles: Array(completionCandles))
            
            logInfo("当前orm组装完成，开始使用CoreML模型进行识别")
            do {
                try await self.evaluation(candleModel)
            } catch {
                logInfo("搜索数据库错误:\(error)")
                sendClosePositionSignal()
            }
        } catch {
            logInfo("k线请求失败：\(error)")
            sendClosePositionSignal()
        }
    }
    
    /// k线管理器
    var candleManager = CandleManager()
    
    /// 请求当前的k线
    /// - Returns: 返回当前的所有k线，请求前几个
    func requestCurrent() async throws -> [Candle] {
        let count = CandleModel.previousCount
        let (_, candles) = try await candleManager.requestCandles(limit: count + 1)
        return candles
    }
    
    // 生成识别器
    var regressor: CandleModelRegressor = {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "CandleModelRegressor", withExtension:"mlmodelc")!
        return try! CandleModelRegressor(contentsOf: url)
    }()
    
    /// 对当前已完成的模型进行评估
    /// - Parameter candleModel: 已完成的k线组合
    func evaluation(_ candleModel: CandleModel) async throws {
        
        guard candleModel.previousCandles.count >= CandleModel.previousCount else {
            throw CommonError(message: "用于识别的数量不足")
        }
        
        guard let c0 = candleModel.previousCandles[0].rate.double,
              let c1 = candleModel.previousCandles[1].rate.double,
              let c2 = candleModel.previousCandles[2].rate.double,
              let c3 = candleModel.previousCandles[3].rate.double,
              let c4 = candleModel.previousCandles[4].rate.double else {
            throw CommonError(message: "涨跌幅转成double失败")
        }
        logInfo("开始识别：\(c0),\(c1),\(c2),\(c3),\(c4)")
        let output = try regressor.prediction(_0: c0, _1: c1, _2: c2, _3: c3, _4: c4)
        logInfo("识别结果：\(output.rate)")
        if output.rate > 0 {
            logInfo("发送买入信号")
            OrderManager.shared.orderUp()
        } else {
            logInfo("发送卖出信号")
            OrderManager.shared.orderDown()
        }
    }
    
    func sendClosePositionSignal() {
        // 如果没有找到合适的，则发出清仓信号
        OrderManager.shared.orderClose()
    }
}
