import CXShim
import CXTestUtility
import Dispatch
import Nimble
import Quick

class JustSpec: QuickSpec {
    
    override func spec() {
        
        afterEach {
            TestResources.release()
        }
        
        // MARK: - Send Values
        describe("Send Values") {
            
            // MARK: 1.1 should send a value then send finished
            it("should send value then send finished") {
                let pub = Just<Int>(1)
                let sub = pub.subscribeTracingSubscriber(initialDemand: .unlimited)
                
                expect(sub.eventsWithoutSubscription) == [.value(1), .completion(.finished)]
            }
            
            #if !SWIFT_PACKAGE
            // MARK: 1.2 should throw assertion when none demand is requested
            it("should throw assertion when less than one demand is requested") {
                let pub = Just<Int>(1)
                expect {
                    pub.subscribeTracingSubscriber(initialDemand: .max(0))
                }.to(throwAssertion())
            }
            
            // MARK: 1.3 should throw assertion when none demand is requested even after completion
            it("should throw assertion when less than one demand is requested even after completion") {
                var subscription: Subscription?
                
                let pub = Just<Int>(1)
                let sub = TracingSubscriber<Int, Never>(receiveSubscription: { s in
                    subscription = s
                    s.request(.unlimited)
                }, receiveValue: { _ in
                    return .none
                }, receiveCompletion: { _ in
                })
                pub.subscribe(sub)
                
                expect {
                    subscription?.request(.max(0))
                }.to(throwAssertion())
            }
            #endif
        }
        
        // MARK: - Release Resources
        describe("Release Resources") {
            
            // MARK: 2.1 subscription should release the subscriber after complete
            it("subscription should release the subscriber after complete") {
                var subscription: Subscription?
                weak var subObj: AnyObject?
                
                do {
                    let pub = Just<Int>(1)
                    let sub = TracingSubscriber<Int, Never>(receiveSubscription: { s in
                        subscription = s
                    }, receiveValue: { _ in
                        return .none
                    }, receiveCompletion: { _ in
                    })
                    subObj = sub
                    pub.subscribe(sub)
                }
                
                expect(subObj).toNot(beNil())
                subscription?.request(.unlimited)
                expect(subObj).to(beNil())
                
                _ = subscription
            }
            
            // MARK: 2.2 subscription should release the subscriber after cancel
            it("subscription should release the subscriber after cancel") {
                var subscription: Subscription?
                weak var subObj: AnyObject?
                
                do {
                    let pub = Just<Int>(1)
                    let sub = TracingSubscriber<Int, Never>(receiveSubscription: { s in
                        subscription = s
                    }, receiveValue: { _ in
                        return .none
                    }, receiveCompletion: { _ in
                    })
                    
                    subObj = sub
                    pub.subscribe(sub)
                }
                
                expect(subObj).toNot(beNil())
                subscription?.cancel()
                expect(subObj).to(beNil())
                
                _ = subscription
            }
            
            // MARK: 2.3 subscription should not release the initial object after complete
            it("subscription should not release the initial object after complete") {
                var subscription: Subscription?
                weak var testObj: AnyObject?
                
                do {
                    let obj = NSObject()
                    testObj = obj
                    
                    let pub = Just(obj)
                    let sub = TracingSubscriber<NSObject, Never>(receiveSubscription: { s in
                        subscription = s
                    }, receiveValue: { _ in
                        return .none
                    }, receiveCompletion: { _ in
                    })
                    
                    pub.subscribe(sub)
                }
                
                expect(testObj).toNot(beNil())
                subscription?.request(.unlimited)
                expect(testObj).toNot(beNil())
                
                _ = subscription
            }
            
            // MARK: 2.4 subscription should not release the initial object after cancel
            it("subscription should not release the initial object after cancel") {
                var subscription: Subscription?
                weak var testObj: AnyObject?
                
                do {
                    let obj = NSObject()
                    testObj = obj
                    
                    let pub = Just<NSObject>(obj)
                    let sub = TracingSubscriber<NSObject, Never>(receiveSubscription: { s in
                        subscription = s
                    }, receiveValue: { _ in
                        return .none
                    }, receiveCompletion: { _ in
                    })
                    
                    pub.subscribe(sub)
                }

                expect(testObj).toNot(beNil())
                subscription?.cancel()
                expect(testObj).toNot(beNil())
            }
        }
        
        // MARK: - Concurrent
        describe("Concurrent") {
            
            // MARK: 3.1 should only send only one value even if the subscription requests it multiple times concurrently
            it("should only send only one value even if the subscription requests it multiple times concurrently") {
                var subscription: Subscription?
                
                let pub = Just<Int>(1)
                let sub = TracingSubscriber<Int, Never>(receiveSubscription: { s in
                    subscription = s
                }, receiveValue: { _ in
                    return .none
                }, receiveCompletion: { _ in
                })
                
                pub.subscribe(sub)
                
                let g = DispatchGroup()
                for _ in 0..<100 {
                    DispatchQueue.global().async(group: g) {
                        subscription?.request(.max(1))
                    }
                }
                g.wait()
                
                expect(sub.eventsWithoutSubscription) == [.value(1), .completion(.finished)]
            }
        }
    }
}
