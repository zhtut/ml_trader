//
//  Candle.swift
//
//
//  Created by zhtg on 2022/3/7.
//

import Foundation
import UtilCore

open class Candle {
    
    ///1499040000000,      // 开盘时间
    open var t: Int = 0
    ///"0.01634790",       // 开盘价
    open var o: String = ""
    ///"0.80000000",       // 最高价
    open var h: String = ""
    ///"0.01575800",       // 最低价
    open var l: String = ""
    ///"0.01577100",       // 收盘价(当前K线未结束的即为最新价)
    open var c: String = ""
    ///"148976.11427815",  // 成交量
    open var v: String = ""
    ///1499644799999,      // 收盘时间
    open var T: Int = 0
    ///"2434.19055334",    // 成交额
    open var q: String = ""
    ///308,   // 成交笔数, size
    open var s: String = ""
    ///"1756.87402397",    // 主动买入成交量
    open var vc: String = ""
    ///"28.46694368",      // 主动买入成交额
    open var vq: String = ""
    
    public convenience init(array: [Any]) {
        self.init()
        if array.count > 10 {
            t = array[0] as? Int ?? 0
            o = array[1] as? String ?? ""
            h = array[2] as? String ?? ""
            l = array[3] as? String ?? ""
            c = array[4] as? String ?? ""
            v = array[5] as? String ?? ""
            T = array[6] as? Int ?? 0
            q = array[7] as? String ?? ""
            s = array[8] as? String ?? ""
            vc = array[9] as? String ?? ""
            vq = array[10] as? String ?? ""
        }
    }
    
    /// 涨跌幅
    open var rate: String {
        if let open = Decimal(string: o),
           let close = Decimal(string: c) {
            let offset = close - open
            let rate = (offset / close) * 100.0
            let rateStr = String(format: "%.2f", rate.double ?? 0.0)
            return rateStr
        }
        return ""
    }
    
    /// 是否当前的k线
    /// - Parameter interval: k线的秒数
    /// - Returns: 返回是否当前的k线柱子
    open func isCurrent(interval: Int) -> Bool {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let offset = now - Int(t)
        if offset < interval * 1000 {
            return true
        }
        return false
    }
    
    /// 对这个k线的描述
    open var desc: String {
        "\(o)-\(c)-\(h)-\(l)-\(rate)"
    }
}
