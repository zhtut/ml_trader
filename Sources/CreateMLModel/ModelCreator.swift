//
//  File.swift
//
//
//  Created by tutuzhou on 2024/1/19.
//

import Foundation
import BinanceSupport
import CreateML
import TabularData

/// 创建模型
class ModelCreator {
    
    /// 从哪个时间点开始请求对象 2020/01/01 00:00:00
    var initStartTime: Int = 1577808000000
//    var initStartTime: Int = 1704903659000 // 2024-01-11 0:20:59
    var lastTime: Int?
    
    var candles = [Candle]()
    
    lazy var candleManager: CandleManager = {
        CandleManager()
    }()
    
    /// 开始创建模型
    func create() async throws {
        candles.removeAll()
        try await request()
    }
    
    /// 执行一次请求
    func request() async throws {
        let lastTime = lastTime ?? initStartTime
        let next = lastTime + 1
        do {
            logInfo("开始请求\(next.dateDesc)的数据")
            // 请求当前时间的k线
            let (response, candles) = try await candleManager.requestCandles(startTime: next)
            let requestCompletion = await self.saveCandles(candles)
            if !requestCompletion {
                // 请求没完成，继续请求下一页
                try await self.continueWith(response: response)
                return
            }
            logInfo("请求完成，开始生成Candle模型")
            try await createCandleModels()
        } catch {
            logInfo("请求失败:\(error)")
        }
    }
    
    /// 保存candle到数组中
    /// - Parameter candles: 要保存的k线
    /// - Returns: 返回是否请求完成
    func saveCandles(_ candles: [Candle]) async -> Bool {
        if candles.count == 0 {
            return true
        }
        
        var syncCompletion = false
        if let lastCandle = candles.last {
            syncCompletion = lastCandle.isCurrent(interval: candleManager.interval)
        }
        
        self.candles += candles
        
        // 保存最后一次的值
        lastTime = self.candles.last?.t
        
        return syncCompletion
    }
    
    /// 预订下一次请求
    /// - Parameter response: 上一次的请求response
    func continueWith(response: HTTPURLResponse?) async throws {
        guard let response = response else {
            try await self.request()
            return
        }
        
        let responseHeaders = response.allHeaderFields
        var retryAfter = ""
        // 判断一下header中有没有retry-after，如果有，则不能请求那么快了，要不然容易被封ip
        for key in responseHeaders.keys {
            if let key = key as? String,
               key.lowercased() == "retry-after",
               let value = response.value(forHTTPHeaderField: key) {
                retryAfter = value
                break
            }
        }
        
        var delay = 0.1
        if retryAfter != "",
           let time = retryAfter.double {
            delay = time + 5
        }
        logInfo("\(delay)后开始调用请求")
        sleep(UInt32(delay))
        try await self.request()
    }
    
    var candleModels = [CandleModel]()
    
    /// 使用所有k柱数组生成模型
    func createCandleModels() async throws {
        candleModels.removeAll()
        for (index, _) in candles.enumerated() {
            let lastIndex = index + CandleModel.previousCount
            if candles.count > lastIndex {
                let current = candles[lastIndex]
                let previous = candles[index..<lastIndex]
                let candleModel = try CandleModel(current: current, previousCandles: Array(previous))
                candleModels.append(candleModel)
            }
        }
        logInfo("生成Candle模型完成，生成了\(candleModels.count)个，准备生成csv文件")
        try await createCSVFile()
    }
    
    /// 文件路径
    var csvFileURL: URL =  {
        let path = NSHomeDirectory() + "/candles.csv"
        let url = URL(filePath: path)
        return url
    }()
    
    var modelFileURL: URL =  {
        let path = NSHomeDirectory() + "/CandleModelRegressor.mlmodel"
        let url = URL(filePath: path)
        return url
    }()
    
    var columns: [String] = {
        var headers = [String]()
        for i in 0..<CandleModel.previousCount {
            headers.append("\(i)")
        }
        headers.append("rate")
        return headers
    }()
    
    /// 生成csv文件
    func createCSVFile() async throws {
        // 每行的内容
        var contents = [String]()
        
        // 文件表头
        let header = columns.joined(separator: ",")
        contents.append(header)
        logInfo("组装Header：\(header)")
        
        // 每天的
        for candleModel in candleModels {
            var lines = [String]()
            // 前面的涨跌幅
            lines += candleModel.previousCandles
                .map({ $0.rate })
            
            // 当天的涨跌幅
            if let current = candleModel.current {
                lines.append(current.rate)
            }
            
            // 当前的字符串
            let line = lines.joined(separator: ",")
            logInfo("组装字符串：\(line)")
            contents.append(line)
        }
        
        // 组装成最后字符
        let content = contents.joined(separator: "\n")
        if let data = content.data(using: .utf8) {
            try data.write(to: csvFileURL)
        }
        
        logInfo("生csv成功，准备生成CoreML模型")
        try await createML()
    }
    
    /// 生成模型
    func createML() async throws {
        guard FileManager.default.fileExists(atPath: csvFileURL.path()) else {
            print("csv路径不存在")
            throw CreateError.csvNotFound
        }
        
        // 生成MLTable
        let dataFrame = try DataFrame(contentsOfCSVFile: csvFileURL, columns: columns)
        
        // 划分数据，0.8用于训练，0.2用于验证
        let (trainingData, testingData) = dataFrame.randomSplit(by: 0.2, seed: 5)
        
        // 开始训练
        logInfo("开始训练")
        let regressor = try MLLinearRegressor(trainingData: DataFrame(trainingData), targetColumn: "rate")
        
        /// 获取训练结果
        let trainintError = regressor.trainingMetrics.error
        let trainintValid = regressor.trainingMetrics.isValid
        let worstTrainingError = regressor.trainingMetrics.maximumError
        logInfo("训练结果->: error: \(String(describing: trainintError))，是否有效：\(trainintValid)，识别率：\(worstTrainingError)")
        
        let validationError = regressor.validationMetrics.error
        let validationValid = regressor.validationMetrics.isValid
        let worstValidationError = regressor.validationMetrics.maximumError
        logInfo("验证结果->: error: \(String(describing: validationError))，是否有效：\(validationValid)，识别率：\(worstValidationError)")
        
        /// 评估
        logInfo("开始评估")
        let regressorEvalutation = regressor.evaluation(on: DataFrame(testingData))
        
        
        /// 评估e的结果
        let evalutationError = regressorEvalutation.error
        let evalutationValid = regressorEvalutation.isValid
        let worstEvaluationError = regressorEvalutation.maximumError
        logInfo("评估结果->: error: \(String(describing: evalutationError))，是否有效：\(evalutationValid)，识别率：\(worstEvaluationError)")
        
        // 保存
        let regressorMetaData = MLModelMetadata(author: "zhtg@me.com", shortDescription: "BTC5mk线涨跌预测模型", version: "1.0")
        try regressor.write(to: modelFileURL, metadata: regressorMetaData)
        
        // 测试
//        let testcsvFile = documentsPath + "/test.csv"
//        let testDataFrame = try DataFrame(contentsOfCSVFile: URL(filePath: testcsvFile), columns: ["first", "second"])
//        let pResult = try regressor.predictions(from: testDataFrame)
//        print("result: \(pResult)")
        
        logInfo("完成生成")
        
        
//        xcrun coremlcompiler compile CandleModelRegressor.mlmodel .
//        xcrun coremlcompiler generate --language Swift CandleModelRegressor.mlmodel .
    }
}

enum CreateError: Error {
    case csvNotFound
}
