//
// CandleModelRegressor.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class CandleModelRegressorInput : MLFeatureProvider {

    /// 0 as double value
    var _0: Double

    /// 1 as double value
    var _1: Double

    /// 2 as double value
    var _2: Double

    /// 3 as double value
    var _3: Double

    /// 4 as double value
    var _4: Double

    var featureNames: Set<String> {
        get {
            return ["0", "1", "2", "3", "4"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "0") {
            return MLFeatureValue(double: _0)
        }
        if (featureName == "1") {
            return MLFeatureValue(double: _1)
        }
        if (featureName == "2") {
            return MLFeatureValue(double: _2)
        }
        if (featureName == "3") {
            return MLFeatureValue(double: _3)
        }
        if (featureName == "4") {
            return MLFeatureValue(double: _4)
        }
        return nil
    }
    
    init(_0: Double, _1: Double, _2: Double, _3: Double, _4: Double) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
    }

}


/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class CandleModelRegressorOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// rate as double value
    var rate: Double {
        return self.provider.featureValue(for: "rate")!.doubleValue
    }

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(rate: Double) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["rate" : MLFeatureValue(double: rate)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class CandleModelRegressor {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "CandleModelRegressor", withExtension:"mlmodelc")!
    }

    /**
        Construct CandleModelRegressor instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of CandleModelRegressor.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `CandleModelRegressor.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct CandleModelRegressor instance by automatically loading the model from the app's bundle.
    */
    @available(*, deprecated, message: "Use init(configuration:) instead and handle errors appropriately.")
    convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct CandleModelRegressor instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct CandleModelRegressor instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<CandleModelRegressor, Error>) -> Void) {
        return self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct CandleModelRegressor instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> CandleModelRegressor {
        return try await self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct CandleModelRegressor instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<CandleModelRegressor, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(CandleModelRegressor(model: model)))
            }
        }
    }

    /**
        Construct CandleModelRegressor instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> CandleModelRegressor {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return CandleModelRegressor(model: model)
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as CandleModelRegressorInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as CandleModelRegressorOutput
    */
    func prediction(input: CandleModelRegressorInput) throws -> CandleModelRegressorOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as CandleModelRegressorInput
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as CandleModelRegressorOutput
    */
    func prediction(input: CandleModelRegressorInput, options: MLPredictionOptions) throws -> CandleModelRegressorOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return CandleModelRegressorOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        - parameters:
           - input: the input to the prediction as CandleModelRegressorInput
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as CandleModelRegressorOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
    func prediction(input: CandleModelRegressorInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> CandleModelRegressorOutput {
        let outFeatures = try await model.prediction(from: input, options:options)
        return CandleModelRegressorOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - _0 as double value
            - _1 as double value
            - _2 as double value
            - _3 as double value
            - _4 as double value

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as CandleModelRegressorOutput
    */
    func prediction(_0: Double, _1: Double, _2: Double, _3: Double, _4: Double) throws -> CandleModelRegressorOutput {
        let input_ = CandleModelRegressorInput(_0: _0, _1: _1, _2: _2, _3: _3, _4: _4)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        - parameters:
           - inputs: the inputs to the prediction as [CandleModelRegressorInput]
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [CandleModelRegressorOutput]
    */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    func predictions(inputs: [CandleModelRegressorInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [CandleModelRegressorOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [CandleModelRegressorOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  CandleModelRegressorOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
