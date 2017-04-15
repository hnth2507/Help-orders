//
//  APIService.swift
//  dahmakan-help
//
//  Created by Thi Huynh on 4/15/17.
//  Copyright © 2017 Nexx. All rights reserved.
//

import UIKit
import Moya
import RxSwift
import Moya_ModelMapper
import Mapper

struct OrderItem: Mappable {
    var order_id: Int
    var arrives_at_utc: Double
    var paid_with: String
    
    init(map: Mapper) throws {
        try order_id = map.from("order_id")
        try arrives_at_utc = map.from("arrives_at_utc")
        try paid_with = map.from("paid_with")
    }
}

struct OrderResponse: Mappable {
    var orders: [OrderItem]
    init(map: Mapper) throws {
        try orders = map.from("orders")
    }
}

enum OrderTarget {
    case listOrder()
}

extension OrderTarget: TargetType {
    
    var baseURL: URL {
        let urlStr = "http://staging-api.dahmakan.com/test"
        let url = URL(string: urlStr)
        return url!
    }
    
    var path: String {
        switch self {
        case .listOrder():
            return "/orders"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .listOrder():
            return .get
        }
    }
    var parameters: [String: Any]? {
        switch self {
        case .listOrder():
            return nil
        }
    }
    var sampleData: Data {
        switch self {
        case .listOrder():
            return "".data(using: .utf8)!
        }
    }
    
    var task: Task {
        switch self {
        default:
            return .request
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        switch self {
        case .listOrder():
            return JSONEncoding.default
        }
        
    }
    var validate: Bool {
            return false
    }
}


class APIService: NSObject {
    static let sharedInstance = APIService()
    var provider = RxMoyaProvider<OrderTarget>()

    override init() {
        super.init()
    }

    func getOrders() -> Observable<[OrderItem]> {
        return self.provider.request(.listOrder()).debug()
            .parseModelWith(type: OrderResponse.self).flatMap { result ->  Observable<[OrderItem]>   in
                switch result {
                case .success(let model):
                    let object = model as! OrderResponse
                    return Observable.just(object.orders)
                case .error(_, _):
                    return Observable.just([])
                }
            }
            .catchError({ (error) -> Observable<[OrderItem]> in
                print("Unexpected Error", error.localizedDescription)
                return Observable.just([])
            })
    }
}


public enum NetworkError:String {
    case ErrorMessage = "Error"
    case NoInternet = "No Internet Connection"
    case InternalServerError = "Internal server error"
    case BadGateWay = "Bad gateway"
    case NotFound = "404 - Not found"
    case InvalidAuthorize = "401 - Invalid Authorization"
    case UnexpectedResult = "Unxepected result"
    case Other = "Some thing went wrong"
    case ObservableError = "Some thing went wrong with observable"
}


public enum NetworkResponse<T> {
    case success(T)
    case error(NetworkError,T)
}


public extension ObservableType where E == Response {
    
    /// Maps data received from the signal into an object (on the default Background thread) which
    /// implements the Mappable protocol and returns the NetworkResponse back on the MainScheduler.
    /// If the conversion fails, the signal errors.
    func parseModelWith<T: Mappable>(type: T.Type, keyPath: String? = nil) -> Observable<NetworkResponse<Any>> {
        return observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap { response -> Observable< NetworkResponse<Any>> in
                print(response)
                if (200..<299).contains(response.statusCode) {
                    return self.parseJsonFrom(type: type, response: response)
                } else if (400..<499).contains(response.statusCode) {
                    print("Status code error", response.statusCode)
                    return Observable.just(NetworkResponse.error(NetworkError.InvalidAuthorize,""))
                } else {
                    return Observable.just((NetworkResponse.error(NetworkError.Other,"")))
                }
            }
            .observeOn(MainScheduler.instance)
    }
    
    func parseJsonFrom<T:Mappable>(type:T.Type, response: Response) -> Observable<NetworkResponse<Any>> {
        do {
            let json = try response.mapJSON()
            if let dict = json as? NSDictionary{
                // obj is a string array. Do something with stringArray
                print("GET REPONSE FROM REQUETS: [\(describing: response.request)] : \(dict)")
                guard let object = T.from(dict) else {
                    throw MoyaError.jsonMapping(response)
                }
                return Observable.just(NetworkResponse.success(object))
            }
            else {
                // obj is not a string array
                if let array = json as? NSArray {
                    guard let list = T.from(array) else {
                        throw MoyaError.jsonMapping(response)
                    }
                    return Observable.just(NetworkResponse.success(list))
                }
                return Observable.just(NetworkResponse.error(NetworkError.Other,"Cannot parse json from response"))
            }
        } catch {
            return Observable.just(NetworkResponse.error(NetworkError.UnexpectedResult,error.localizedDescription))
        }
    }
    
    
}















