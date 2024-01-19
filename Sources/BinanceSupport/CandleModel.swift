//
//  File.swift
//  
//
//  Created by tutuzhou on 2024/1/19.
//

import Foundation

/// k线模型
open class CandleModel {
    
    /// 数量错误
    public struct PreviousCountError: Error {
        public var previousCount: Int
        public var actualCount: Int
    }
    
    // 当前的candle
    open var current: Candle?
    
    /// 需要多少个candle判断一个
    public static var previousCount = 5
    
    /// 之前的candle
    open var previousCandles: [Candle]
    
    public init(current: Candle? = nil, previousCandles: [Candle]) throws {
        self.current = current
        if previousCandles.count != Self.previousCount {
            throw PreviousCountError(previousCount: Self.previousCount,
                                     actualCount: previousCandles.count)
        }
        self.previousCandles = previousCandles
    }
}
