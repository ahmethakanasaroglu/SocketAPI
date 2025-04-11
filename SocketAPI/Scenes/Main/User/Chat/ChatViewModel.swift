import Foundation
import FirebaseFirestore // Timestamp için eklendi
import UIKit
import FirebaseStorage

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
    var onMessageDeleted: ((Int) -> Void)?
    
    // Sadece tam liste yenilemesi için kullanılacak
    var onMessageReceived: (() -> Void)?
    var onMessagesDeleted: (() -> Void)?
    
    // Yeni callback: Sadece tepki değiştiğinde kullanılacak
    var onReactionUpdated: ((Int, String?) -> Void)?
    
    private var currentUserID: String = ""
    private var otherUserID: String = ""
    
    // MARK: - Cache System
    static let imageCache = NSCache<NSString, UIImage>()
    static var imageLoadTimestamps = [String: Date]()
    static let maxCacheAge: TimeInterval = 3600 // 1 saat cache geçerlilik süresi

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
    
    // MARK: - Profile Image Cache Methods
    
    // Profil resmi yükleme (Cache kullanarak)
    func loadProfileImage(userId: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: "profile_\(userId)")
        
        // Önce cache'i kontrol et ve taze ise kullan
        if let cachedImage = ChatViewModel.imageCache.object(forKey: cacheKey),
           let timestamp = ChatViewModel.imageLoadTimestamps[userId],
           Date().timeIntervalSince(timestamp) < ChatViewModel.maxCacheAge {
            print("Cache'den profil resmi yükleniyor: \(userId)")
            completion(cachedImage)
            return
        }
        
        // Cache'de yok veya bayat ise Firebase'den yükle
        print("Firebase'den profil resmi yükleniyor: \(userId)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        // Önce kullanıcının bir profil fotoğrafı olup olmadığını kontrol et
        profileImageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("Profil resmi yükleme hatası: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let imageData = data, let image = UIImage(data: imageData) else {
                completion(nil)
                return
            }
            
            // Resmi cache'e kaydet
            ChatViewModel.imageCache.setObject(image, forKey: cacheKey)
            ChatViewModel.imageLoadTimestamps[userId] = Date()
            
            completion(image)
        }
    }
    
    // Cache temizleme
    func clearImageCache() {
        ChatViewModel.imageCache.removeAllObjects()
        ChatViewModel.imageLoadTimestamps.removeAll()
    }
    
    // Belirli bir kullanıcının cache'ini geçersiz kılma
    func invalidateImageCache(forUserId userId: String) {
        let cacheKey = NSString(string: "profile_\(userId)")
        ChatViewModel.imageCache.removeObject(forKey: cacheKey)
        ChatViewModel.imageLoadTimestamps.removeValue(forKey: userId)
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
    
    // Mesaja tepki ekleme/değiştirme/kaldırma - ÖNEMLİ: Değiştirildi
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
        
        // Tepkiyi Firebase'e kaydet
        webSocketManager.updateMessageReaction(messageId: oldMessage.messageId, reaction: reaction)
        
        // Sadece tepki güncellemesi için özel callback'i çağır
        onReactionUpdated?(index, reaction)
        
        // NOT: onMessageReceived callback'i çağrılmıyor, böylece tüm tablo yenilenmeyecek
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
        if let existingIndex = messages.firstIndex(where: { $0.messageId == messageId }) {
            // Mesaj zaten varsa, sadece tepkiyi güncelle
            let oldMessage = messages[existingIndex]
            if oldMessage.reaction != reaction {
                let updatedMessage = ChatMessage(
                    text: oldMessage.text,
                    isFromCurrentUser: oldMessage.isFromCurrentUser,
                    messageId: oldMessage.messageId,
                    timestamp: oldMessage.timestamp,
                    reaction: reaction
                )
                
                messages[existingIndex] = updatedMessage
                onReactionUpdated?(existingIndex, reaction)
            }
        } else {
            // Yeni mesajsa ekle
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

        // Tüm mesajları yükledikten sonra UI'ı güncelle
        onMessageReceived?()
    }
    
    // Mesaj silme işlemleri
    func deleteMessage(at index: Int) {

            guard index >= 0 && index < messages.count else { return }
            
            let messageId = messages[index].messageId
            webSocketManager.deleteMessage(messageId: messageId)
            
            // Mesajı yerel listeden kaldır
            messages.remove(at: index)
            
            // YENİ: Silinen mesaj için özel callback'i çağır
            onMessageDeleted?(index)
            
            // ESKİ: Tüm tabloyu yenileme - artık gerek yok, yorum satırına al veya sil
            // onMessageReceived?()
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
