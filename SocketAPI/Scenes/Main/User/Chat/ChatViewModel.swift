import Foundation

struct ChatMessage {
    let text: String
    let isFromCurrentUser: Bool
    let messageId: String
    
    var displayText: String {
        return isFromCurrentUser ? "🟢 Sen: \(text)" : "🔵 Karşı Taraf: \(text)"
    }
}

class ChatViewModel: WebSocketManagerDelegate {
    private let webSocketManager = WebSocketManager()
    var messages: [ChatMessage] = []
    var onMessageReceived: (() -> Void)?
    var onMessagesDeleted: (() -> Void)?
    private var currentUserID: String = ""
    private var otherUserID: String = ""

    init() {
        webSocketManager.delegate = self
        // Bağlantıyı hemen kurma, channelId gelince kur
    }
    
    // Yeni fonksiyon: Channel ID ile socket'i ayarla
    func setupSocket(withChannelId channelId: String, currentUserID: String, otherUserID: String) {
        self.currentUserID = currentUserID
        self.otherUserID = otherUserID
        webSocketManager.setupSocketWithChannelId(channelId, currentUserID: currentUserID, otherUserID: otherUserID)
        webSocketManager.connect()
        print("🔌 Socket \(channelId) kanalına bağlandı")
    }
    
    // Socket bağlantısını kapat
    func disconnectSocket() {
        webSocketManager.disconnect()
    }

    func sendMessage(_ message: String) {
        webSocketManager.sendMessage(message)
        // Mesaj artık Firestore'a kaydedilip oradan alındığında delegate'e iletilecek
    }
    
    // Delegate metodları
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String) {
        // Aynı mesajı tekrar eklememek için kontrol et
        if !messages.contains(where: { $0.messageId == messageId }) {
            messages.append(ChatMessage(text: message, isFromCurrentUser: isFromCurrentUser, messageId: messageId))
            onMessageReceived?()
        }
    }
    
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String)]) {
        // Firestore'dan gelen mesajları ChatMessage modeline dönüştür
        self.messages = messages.map {
            ChatMessage(
                text: $0.text,
                isFromCurrentUser: $0.isFromCurrentUser,
                messageId: $0.messageId
            )
        }

        // UI'ı güncelle
        onMessageReceived?()
    }

    
    // Mesaj silme işlemleri
    func deleteMessage(at index: Int) {
        guard index >= 0 && index < messages.count else { return }
        
        let messageId = messages[index].messageId
        webSocketManager.deleteMessage(messageId: messageId)
        
        // Mesajı yerel listeden de kaldır
        messages.remove(at: index)
        onMessageReceived?()
    }
    
    func deleteAllMessages(completion: @escaping (Bool) -> Void) {
        webSocketManager.deleteAllMessages { [weak self] success in
            if success {
                self?.messages = []
                self?.onMessagesDeleted?()
            }
            completion(success)
        }
    }
}
