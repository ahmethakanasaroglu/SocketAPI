import Foundation

class ChatViewModel: WebSocketManagerDelegate {
    private let webSocketManager = WebSocketManager()
    var messages: [String] = []
    var onMessageReceived: (() -> Void)?

    init() {
        webSocketManager.delegate = self
        webSocketManager.connect()
    }

    func sendMessage(_ message: String) {
        webSocketManager.sendMessage(message)
        messages.append("🟢 Sen: \(message)")
        onMessageReceived?()
    }

    func didReceiveMessage(_ message: String) {
        messages.append("🔵 Karşı Taraf: \(message)")
        onMessageReceived?()
    }
}
