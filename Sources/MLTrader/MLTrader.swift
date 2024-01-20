
import Foundation
import BinanceSupport

/// 数据库策略，保存所有k线到数据库中，检查五个模型是否与以往类似，如果有，则可判断后一个
open class MLTrader {
    
    static let shared = MLTrader()
    
    let instId = "BTCUSDT"
    
    let findManager = FindManager()
    
    init() {
        Task {
            await startTrader()
        }
    }
    
    func startTrader() async {
        logInfo("DatabaseTrader 初始化开始")
        scheduledAction()
//#if DEBUG
//        Task {
//            await self.startAction()
//        }
//#endif
    }
    
    var candleManager = CandleManager()
    
    /// 预订下一次的查找，等下一个周期到了时间，再过一秒，即开始查找
    func scheduledAction() {
        let now = Int(Date().timeIntervalSince1970)
        let remain = now % candleManager.interval
        let timeOffset = candleManager.interval - remain + 1
        let startInt = now + timeOffset
        logInfo("开始预订，\(timeOffset) 秒后 \(startInt.dateDesc) 开始判断策略")
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeOffset)) {
            Task {
                await self.startAction()
            }
        }
    }
    
    /// 开始查找
    func startAction() async {
        let now = Int(Date().timeIntervalSince1970)
        let next = now + Int(candleManager.interval)
        logInfo("----->\n开始\(now.dateDesc)的查找，下一次的查找在\(next.dateDesc)")
        
        await findManager.findCurrent()
        
        scheduledAction()
    }
}
