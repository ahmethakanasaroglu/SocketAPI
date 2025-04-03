import Foundation

class ChatViewModel: WebSocketManagerDelegate {
    private let webSocketManager = WebSocketManager()
    var messages: [String] = []
    var onMessageReceived: (() -> Void)?

    init() {
        webSocketManager.delegate = self
        // Bağlantıyı hemen kurma, channelId gelince kur
    }
    
    // Yeni fonksiyon: Channel ID ile socket'i ayarla
    func setupSocket(withChannelId channelId: String) {
        webSocketManager.setupSocketWithChannelId(channelId)
        webSocketManager.connect()
        print("🔌 Socket \(channelId) kanalına bağlandı")
    }
    
    // Socket bağlantısını kapat
    func disconnectSocket() {
        webSocketManager.disconnect()
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
