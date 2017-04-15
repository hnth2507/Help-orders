//
//  ViewModel.swift
//  dahmakan-help
//
//  Created by Thi Huynh on 4/15/17.
//  Copyright © 2017 Nexx. All rights reserved.
//

import UIKit
import RxSwift


class ViewModel: NSObject {

    //INPUT
    var refreshPage: PublishSubject<Void> = PublishSubject<Void>()
    //OUTPUT
    var result: Observable<[OrderItem]>!

    
    override init() {
        super.init()
        self.setUpOutput()
    }
    
    func setUpOutput() {
        
        self.result = self.refreshPage
            .debounce(1, scheduler: MainScheduler.instance)
            .debug()
            .flatMapLatest {
            return APIService.sharedInstance
                            .getOrders()
                            .map{ list in list.sorted(by: { $0.arrives_at_utc > $1.arrives_at_utc }) }
            }
            .shareReplay(1)

    }
        
}
