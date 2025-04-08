import Foundation
import FirebaseFirestore // Timestamp için eklendi

struct ChatMessage {
    let text: String
    let isFromCurrentUser: Bool
    let messageId: String
    let timestamp: Date? // Timestamp özelliği eklendi
    let reaction: String? // Tepki özelliği eklendi
    
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
    
    // Emoji ekleme gibi durumlar için mesaj güncelleme
    func updateMessage(at index: Int, newText: String) {
        guard index >= 0 && index < messages.count else { return }
        
        let oldMessage = messages[index]
        let newMessage = ChatMessage(
            text: newText,
            isFromCurrentUser: oldMessage.isFromCurrentUser,
            messageId: oldMessage.messageId,
            timestamp: oldMessage.timestamp,
            reaction: oldMessage.reaction
        )
        
        messages[index] = newMessage
        onMessageReceived?()
    }
    
    // Mesaja tepki ekleme/değiştirme/kaldırma
    func setReaction(at index: Int, reaction: String?) {
        guard index >= 0 && index < messages.count else { return }
        
        let oldMessage = messages[index]
        let newMessage = ChatMessage(
            text: oldMessage.text,
            isFromCurrentUser: oldMessage.isFromCurrentUser,
            messageId: oldMessage.messageId,
            timestamp: oldMessage.timestamp,
            reaction: reaction
        )
        
        messages[index] = newMessage
        onMessageReceived?()
        
        // Tepkiyi Firestore'a kaydet
        // webSocketManager.updateMessageReaction(messageId: oldMessage.messageId, reaction: reaction)
    }
    
    // Delegate metodları - orijinal sürümler (geri uyumluluk için)
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String) {
        // Bu metot geri uyumluluk için korundu
        didReceiveMessage(message, isFromCurrentUser: isFromCurrentUser, messageId: messageId, timestamp: Date(), reaction: nil)
    }
    
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String)]) {
        // Bu metot geri uyumluluk için korundu
        let messagesWithTimestamp = messages.map {
            (text: $0.text, isFromCurrentUser: $0.isFromCurrentUser, messageId: $0.messageId, timestamp: Date(), reaction: nil as String?)
        }
        didLoadMessages(messagesWithTimestamp)
    }
    
    // Timestamp destekli delegate metodları
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?) {
        // Bu metot geri uyumluluk için korundu
        didReceiveMessage(message, isFromCurrentUser: isFromCurrentUser, messageId: messageId, timestamp: timestamp, reaction: nil)
    }
    
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?)]) {
        // Bu metot geri uyumluluk için korundu
        let messagesWithReaction = messages.map {
            (text: $0.text, isFromCurrentUser: $0.isFromCurrentUser, messageId: $0.messageId, timestamp: $0.timestamp, reaction: nil as String?)
        }
        didLoadMessages(messagesWithReaction)
    }
    
    // Tepki desteği olan yeni delegate metodları
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?) {
        // Aynı mesajı tekrar eklememek için kontrol et
        if !messages.contains(where: { $0.messageId == messageId }) {
            messages.append(ChatMessage(
                text: message,
                isFromCurrentUser: isFromCurrentUser,
                messageId: messageId,
                timestamp: timestamp ?? Date(), // Timestamp yoksa şimdiki zamanı kullan
                reaction: reaction
            ))
            onMessageReceived?()
        }
    }
    
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?)]) {
        // Firestore'dan gelen mesajları ChatMessage modeline dönüştür
        self.messages = messages.map {
            ChatMessage(
                text: $0.text,
                isFromCurrentUser: $0.isFromCurrentUser,
                messageId: $0.messageId,
                timestamp: $0.timestamp ?? Date(), // Timestamp yoksa şimdiki zamanı kullan
                reaction: $0.reaction
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
