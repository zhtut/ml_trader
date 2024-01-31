> 前几天看到一个CoreML的教程视频，感觉挺有意思的样子，于是去了解了一下，决定尝试将他用于预测涨跌，看下机器学习的能不能预测的准，就算不行，也无所谓，就相当于学习好了

[demo传递门](https://github.com/zhtut/ml_trader)

# 模型类型
CoreML需要选定一个模型来进行训练
![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/85182243a8b64f49ab095b84ebca59ab~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=1214&h=336&s=111198&e=png&b=252426)
打开developer tool，然后点击New document就可以看到有多少类型
![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6024a2bdcef246f2a13bf099a6941778~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=2108&h=1542&s=569990&e=png&b=252525)
前面几个都是图片分类，图片识别，手势识别，文字识别啥的，我也没细看，今天我们就用表格的Tabular Regression来给他一些基础数据，让他来预测
# 模型选型
曾经也想过给复杂的数据给他去训练，有点复杂，还是先给一些简单的了，我的想法就是以最后一根k线的涨跌幅作为目标，往前数五根k线作为基础数据
![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/cb39188ab5a84f03a8cd153ff23b4fe5~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=1288&h=1068&s=203349&e=png&b=1f252f)
生成模型需要准备一个csv文件，我准备像下面这样的格式，前面的k是基础数据，target是目标数据，这样的数据交给模型训练器进行训练
| k0 | k1 | k2 | k3 | k4 | *target*|
| --- | --- | --- | --- | --- | --- |
| 0.09|-0.16|0.23|-0.06|0.07|-0.05|
| -0.16|0.23|-0.06|0.07|-0.05|-0.10||
| 0.23|-0.06|0.07|-0.05|-0.10|0.05|
| -0.06|0.07|-0.05|-0.10|0.05|-0.06|

单位是百分点
# 获取数据
要得到这样的数据，需要从交易平台请求过往的k线数据
我从币安的api接口查到接口和参数，然后查询从某个时刻开始的数据，一次请求1500条，1500条乘以5分钟

```swift
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
```
通过接口测试，我发现最早只能查到2020/01/01 00:00:00的数据，时间戳就是1577808000000，
于是我就起了一个定时器不断调用接口把数据拉下来
```swift
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
```
Candle是一个基础的k线数据结构，CandleModel就是上面的模型了，所有Candle会组装到一个数组中，然后再来生成所有的CandleModel，生成完之后，就开始组装csv需要的格式了
# 生成csv文件

```swift
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
```

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/30081f09951d4a4e8f53f8a3cb77b87a~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=718&h=634&s=111882&e=png&b=21201c)
生成了一个14M的文件，模型还是比较多的

# 生成CoreML模型
接下来就是生成CoreML模型了

```swift
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
```
有了csv也可以用developer tool来生成，我这里为了方便，就干脆用代码一起生成好了，其中有效和结果字段没用上，这个应该要判断一下，如果不满足，则直接中断的

生成的模型是一个CandleModelRegressor.mlmodel名称的，mlmodel结尾，这个文件还不可以用于spm，用于xcode project倒是可以，

不可以用于spm可能是bug，他编译的时候说缺少一个语言，但是spm没有设置语言的地方，走不下去了，只能另外想办法，google到可以手动编译，编译完再放进去就可以

```shell
xcrun coremlcompiler compile CandleModelRegressor.mlmodel .
xcrun coremlcompiler generate --language Swift CandleModelRegressor.mlmodel .
```
手动命令如上，他会生成以下两个文件，
![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/496a135911694b14a37c4ce421c5aee3~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=630&h=100&s=26591&e=png&b=2c2c29)
# 集成
拖入spm项目根目录即可，
然后target还要添加一个resource的配置，需要使用`.copy`，其他都不行
```swift
resources: [
    .copy("CandleModelRegressor.mlmodelc"),
      ]
```
# 使用
用的时候需要先生成一个`regressor`

```swift
    // 生成识别器
    var regressor: CandleModelRegressor = {
        let bundle = Bundle.module
        let url = bundle.url(forResource: "CandleModelRegressor", withExtension:"mlmodelc")!
        return try! CandleModelRegressor(contentsOf: url)
    }()
```
然后识别的时候，传入当前k线往前的5个节点的涨跌幅，即可用模型预测出来一个结果了

```swift
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
```
接下来就是交易的代码了，交易的代码就不帖了，有兴趣大家可以去github自己看，回头我会部署到linux服务上，跑一段时间，再来看结果，结果也会更新到这里

# 部署
本来写好了DockerFile准备部署的，之前写一个后台服务都可以成功部署到linux，结果发现这个不行，因为CoreML模块在swift的linux服务端没有，只能跑在macOS了
![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/416aec0d68ef47e9a9bd2e25b06c31c6~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=1552&h=230&s=33205&e=png&b=2b2b2b)
正好我有个Mac Mini的Nas服务器，因为没有Mac的docker镜像，于是我就在终端直接运行好了，不关掉这个终端就能一直运行，懒得搞进程守护了
```swift
swift run -c release MLTrader
```
![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/80d3c4e08fb74eb38dcf23576841bd17~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=1434&h=346&s=293388&e=png&b=1d1d1d)

# 一天的结果
跑了一天了
![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7bd4695f07814da99ede99e2e950bddc~tplv-k3u1fbpfcp-jj-mark:0:0:0:0:q75.image#?w=2388&h=412&s=189094&e=png&b=1f1f24)
请求到80多次订单，相关于买卖40多次，胜率54%，看起来不错，但收益一算，还没跑赢btc，那这胜率估计也是btc涨起来带动的，要是btc下跌，那不知道有多惨，

`看来这个机器还是太笨了啊，这个策略终止`

*其实我可以不用跑实盘，可以拿历史的数据进行回测，80%的数据用来训练，20%的用来验证，验证通过之后，再来跑实盘*
