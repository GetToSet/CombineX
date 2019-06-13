//
//  testJust.swift
//  TestCombine
//
//  Created by Quentin Jin on 2019/6/12.
//  Copyright © 2019 Quentin Jin. All rights reserved.
//

import Foundation
#if CombineQ
import CombineQ
#else
import Combine
#endif

func testJust() {
    let pub = Publishers.Just(1)
    
    var subscription: Subscription?
    let sub = AnySubscriber<Int, Never>(receiveSubscription: { (s) in
        subscription = s
        
        print(type(of: s))
        debugPrint(s)

        print("[AnySub] receive subscription", s)
        
//        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
//            print("[AnySub] try to cancel subscription")
//            subscription?.cancel()
//            print("[AnySub] subscription is canceld")
//        }
        s.request(.max(1))
    }, receiveValue: { i in
        print("[AnySub] receive value", i)
        
        print("[AnySub] cancel subscription when receive value", subscription as Any)
        subscription?.cancel()
        return .max(0)
    }, receiveCompletion: {
        print("[AnySub] receive completion", $0)
    })
    
    pub.subscribe(sub)
}

/*
 [AnySub] receive subscription Just
 [AnySub] receive value 1
 [AnySub] cancel subscription when receive value Optional(Just)
 [AnySub] receive completion finished
 */
