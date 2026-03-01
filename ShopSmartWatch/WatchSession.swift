import WatchConnectivity

@Observable
final class WatchSession: NSObject, WCSessionDelegate {

    var lists: [WatchList] = []

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Toggle (Watch → iPhone)

    func toggleEntry(id: String, inList listID: String) {
        // Optimistic local update so the animation fires immediately
        if let li = lists.firstIndex(where: { $0.id == listID }),
           let ei = lists[li].entries.firstIndex(where: { $0.id == id }) {
            lists[li].entries[ei].isInCart.toggle()
        }
        let msg: [String: Any] = ["toggleEntry": id]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil) { [weak self] _ in
                // Fallback to queued transfer if immediate send fails
                self?.transferToggle(msg)
            }
        } else {
            transferToggle(msg)
        }
    }

    private func transferToggle(_ msg: [String: Any]) {
        WCSession.default.transferUserInfo(msg)
    }

    // MARK: - Receive from iPhone

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.decode(applicationContext) }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        // iPhone may also push via transferUserInfo
        if userInfo["lists"] != nil {
            DispatchQueue.main.async { self.decode(userInfo) }
        }
    }

    private func decode(_ context: [String: Any]) {
        guard let raw = context["lists"] as? [[String: Any]] else { return }
        lists = raw.compactMap { WatchList(from: $0) }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        // Restore last-known context so the Watch shows data immediately
        let ctx = WCSession.default.receivedApplicationContext
        if !ctx.isEmpty {
            DispatchQueue.main.async { self.decode(ctx) }
        }
    }
}
