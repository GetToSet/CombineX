import CXShim
import CXUtility

public enum TestSubscriptionEvent: Equatable {
    case request(demand: Subscribers.Demand)
    case cancel
}

public class TestSubscription: Subscription, TestLogging {
    
    public typealias Event = TestSubscriptionEvent
    
    public let name: String?
    let requestBody: ((Subscribers.Demand) -> Void)?
    let cancelBody: (() -> Void)?
    
    private let lock = Lock()
    private var _events: [Event] = []
    
    public var events: [Event] {
        return self.lock.withLockGet(self._events)
    }
    
    public init(name: String? = nil, request: ((Subscribers.Demand) -> Void)? = nil, cancel: (() -> Void)? = nil) {
        self.name = name
        self.requestBody = request
        self.cancelBody = cancel
    }
    
    public func request(_ demand: Subscribers.Demand) {
        self.trace("request demand", demand)
        self.lock.withLock {
            self._events.append(.request(demand: demand))
        }
        self.requestBody?(demand)
    }
    
    public func cancel() {
        self.trace("cancel")
        self.lock.withLock {
            self._events.append(.cancel)
        }
        self.cancelBody?()
    }
    
    deinit {
        self.trace("deinit")
    }
}
