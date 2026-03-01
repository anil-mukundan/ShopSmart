import WatchConnectivity
import UIKit

/// Manages the WatchConnectivity session on the iPhone side.
/// Pushes shopping list data to the Watch and handles check-off messages back.
final class PhoneSession: NSObject, WCSessionDelegate {

    private var dataStore: AppDataStore?

    // MARK: - Setup

    func configure(dataStore: AppDataStore) {
        self.dataStore = dataStore
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Push to Watch

    func pushToWatch() {
        guard let dataStore,
              WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let payload = buildPayload(from: dataStore)
        try? WCSession.default.updateApplicationContext(payload)
    }

    private func buildPayload(from dataStore: AppDataStore) -> [String: Any] {
        let lists: [[String: Any]] = dataStore.shoppingLists.map { list in
            let entries: [[String: Any]] = dataStore.sortedEntries(for: list).map { entry in
                var dict: [String: Any] = [
                    "id":       entry.id,
                    "itemID":   entry.itemID,
                    "itemName": entry.itemName,
                    "count":    entry.count,
                    "isInCart": entry.isInCart
                ]
                let item = dataStore.items.first { $0.id == entry.itemID }
                if let brand = item?.brand, !brand.isEmpty  { dict["brand"] = brand }
                if let notes = entry.notes, !notes.isEmpty  { dict["notes"] = notes }
                if let data = item?.imageData,
                   let img  = UIImage(data: data),
                   let small = img.resized(maxDimension: 80)
                               .jpegData(compressionQuality: 0.6) {
                    dict["imageData"] = small
                }
                return dict
            }
            return [
                "id":        list.id,
                "storeName": list.storeName,
                "date":      list.date.timeIntervalSince1970,
                "entries":   entries
            ]
        }
        return ["lists": lists]
    }

    // MARK: - Receive from Watch

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleToggle(from: message)
    }

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        handleToggle(from: message)
        replyHandler(["ok": true])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleToggle(from: userInfo)
    }

    private func handleToggle(from dict: [String: Any]) {
        guard let entryID = dict["toggleEntry"] as? String else { return }
        DispatchQueue.main.async { self.dataStore?.toggleEntryInCart(id: entryID) }
    }

    // MARK: - WCSessionDelegate (required iOS-only methods)

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if activationState == .activated { pushToWatch() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
