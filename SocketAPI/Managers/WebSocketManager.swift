import Foundation
import Starscream
import FirebaseFirestore

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String)
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String)])
    
    // Emoji tepkileri için yeni delegate metodları
    func didReceiveMessage(_ message: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?)
    func didLoadMessages(_ messages: [(text: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?)])
}

class WebSocketManager: NSObject, WebSocketDelegate {
    var socket: WebSocket?
    weak var delegate: WebSocketManagerDelegate?
    private var currentChannelId: String = ""
    private var isConnected: Bool = false
    private let db = Firestore.firestore()
    private var currentUserID: String = ""
    private var otherUserID: String = ""
    private var listener: ListenerRegistration?
    
    // Channel ID'yi dış sınıfların erişebilmesi için property ekledim
    var channelId: String? {
        return currentChannelId.isEmpty ? nil : currentChannelId
    }

    
    override init() {
        super.init()
        // İlk başta socket'i oluşturmuyoruz, channelId belirlendiğinde oluşturacağız
    }
    
    func setupSocketWithChannelId(_ channelId: String, currentUserID: String, otherUserID: String) {
        // Eğer zaten bu channelId ile bağlıysak, tekrar bağlanmaya gerek yok
        if currentChannelId == channelId && isConnected {
            return
        }
        
        // Eğer farklı bir channel'a bağlıysak, önce onu kapatıyoruz
        if isConnected {
            disconnect()
        }
        
        self.currentChannelId = channelId
        self.currentUserID = currentUserID
        self.otherUserID = otherUserID
        
        let request = URLRequest(url: URL(string: "wss://free.blr2.piesocket.com/v3/\(channelId)?api_key=Prb34C9fTmugVUUMU30dCZNCfjS4019gFpzWEXJ8")!)
        socket = WebSocket(request: request)
        socket?.delegate = self
        
        // Firestore'dan önceki mesajları yükle
        loadMessagesFromFirestore()
        listenToMessagesFromFirestore()
    }
    
    func connect() {
        if socket == nil {
            print("Socket henüz kurulmadı. Önce setupSocketWithChannelId fonksiyonunu çağırın.")
            return
        }
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        isConnected = false
    }
    
    func sendMessage(_ message: String) {
        socket?.write(string: message)
        
        // Mesajı Firestore'a kaydet
        saveMessageToFirestore(message: message, isFromCurrentUser: true)
    }
    
    // Mesaja tepki eklemek için yeni fonksiyon
    func updateMessageReaction(messageId: String, reaction: String?) {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, tepki güncellenemiyor")
            return
        }
        
        let messageRef = db.collection("chats").document(currentChannelId).collection("messages").document(messageId)
        
        if let reaction = reaction {
            // Tepki ekle veya güncelle
            messageRef.updateData(["reaction": reaction]) { error in
                if let error = error {
                    print("Tepki eklenirken hata oluştu: \(error.localizedDescription)")
                } else {
                    print("Tepki başarıyla eklendi: \(reaction)")
                }
            }
        } else {
            // Tepkiyi kaldır
            messageRef.updateData(["reaction": FieldValue.delete()]) { error in
                if let error = error {
                    print("Tepki kaldırılırken hata oluştu: \(error.localizedDescription)")
                } else {
                    print("Tepki başarıyla kaldırıldı")
                }
            }
        }
    }
    
    // WebSocket olaylarını dinleyen fonksiyon
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(_):
            isConnected = true
            print("WebSocket Bağlandı - Channel: \(currentChannelId)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("WebSocket Koptu: \(reason) (Code: \(code))")
        case .text(let message):
            print("Mesaj Alındı: \(message)")
            // Sadece göster, kaydetme
            delegate?.didReceiveMessage(message, isFromCurrentUser: false, messageId: UUID().uuidString)

        case .error(let error):
            print("Hata Oluştu: \(String(describing: error))")
        default:
            break
        }
    }
    
    private func listenToMessagesFromFirestore() {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, mesajlar dinlenemiyor")
            return
        }

        // Önceki dinleyiciyi kaldır
        listener?.remove()

        listener = db.collection("chats")
            .document(currentChannelId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Firestore dinleme hatası: \(error.localizedDescription)")
                    return
                }

                guard let self = self, let documents = snapshot?.documents else { return }

                var loadedMessages: [(text: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?)] = []

                for document in documents {
                    let data = document.data()
                    if let message = data["message"] as? String,
                       let senderId = data["senderId"] as? String {
                        let isFromCurrentUser = (senderId == self.currentUserID)
                        let messageId = document.documentID
                        
                        // Timestamp'i Date'e dönüştür
                        var timestamp: Date? = nil
                        if let firestoreTimestamp = data["timestamp"] as? Timestamp {
                            timestamp = firestoreTimestamp.dateValue()
                        }
                        
                        // Tepki bilgisini al
                        let reaction = data["reaction"] as? String
                        
                        loadedMessages.append((message, isFromCurrentUser, messageId, timestamp, reaction))
                    }
                }

                // Yeni delegate metodunu çağır
                self.delegate?.didLoadMessages(loadedMessages)
            }
    }

    
    // Firestore'a mesaj kaydetme
    private func saveMessageToFirestore(message: String, isFromCurrentUser: Bool) {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, mesaj kaydedilemiyor")
            return
        }

        let senderID = isFromCurrentUser ? currentUserID : otherUserID

        let messageData: [String: Any] = [
            "channelId": currentChannelId,
            "message": message,
            "senderId": senderID,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats").document(currentChannelId).collection("messages").addDocument(data: messageData) { [weak self] error in
            if let error = error {
                print("Mesaj Firestore'a kaydedilirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("Mesaj Firestore'a başarıyla kaydedildi")
                
                // Mesaj referansını almak için başka bir şekilde erişim sağlayabilirsiniz
                self?.db.collection("chats").document(self?.currentChannelId ?? "").collection("messages")
                    .order(by: "timestamp", descending: true)
                    .limit(to: 1)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Mesaj referansı alınırken hata oluştu: \(error.localizedDescription)")
                        } else if let snapshot = snapshot, let document = snapshot.documents.first {
                            // En son kaydedilen mesajın ID'sini al
                            let messageId = document.documentID
                            //self?.delegate?.didReceiveMessage(message, isFromCurrentUser: isFromCurrentUser, messageId: messageId)
                        }
                    }
            }
        }
    }


    
    // Firestore'dan mesajları yükleme - tepki (emoji) desteği eklenmiş versiyon
    private func loadMessagesFromFirestore() {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, mesajlar yüklenemiyor")
            return
        }
        
        db.collection("chats").document(currentChannelId).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Mesajlar Firestore'dan yüklenirken hata oluştu: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("Firestore'da hiç mesaj bulunamadı veya yüklendi")
                    return
                }
                
                var loadedMessages: [(text: String, isFromCurrentUser: Bool, messageId: String, timestamp: Date?, reaction: String?)] = []
                
                for document in documents {
                    let data = document.data()
                    if let message = data["message"] as? String,
                       let senderId = data["senderId"] as? String {
                        let isFromCurrentUser = (senderId == self?.currentUserID)
                        let messageId = document.documentID
                        
                        // Timestamp'i Date'e dönüştür
                        var timestamp: Date? = nil
                        if let firestoreTimestamp = data["timestamp"] as? Timestamp {
                            timestamp = firestoreTimestamp.dateValue()
                        }
                        
                        // Tepki bilgisini al
                        let reaction = data["reaction"] as? String
                        
                        loadedMessages.append((message, isFromCurrentUser, messageId, timestamp, reaction))
                    }
                }
                
                // Yüklenen tüm mesajları bir kerede delegate'e ilet
                self?.delegate?.didLoadMessages(loadedMessages)
                
                print("\(documents.count) mesaj Firestore'dan yüklendi")
            }
    }
    
    // Mesajı silme fonksiyonu
    func deleteMessage(messageId: String) {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, mesaj silinemiyor")
            return
        }
        
        db.collection("chats").document(currentChannelId).collection("messages").document(messageId).delete { error in
            if let error = error {
                print("Mesaj Firestore'dan silinirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("Mesaj Firestore'dan başarıyla silindi")
            }
        }
    }
    
    // Tüm sohbeti silme fonksiyonu
    func deleteAllMessages(completion: @escaping (Bool) -> Void) {
        guard !currentChannelId.isEmpty else {
            print("ChannelID boş, sohbet silinemiyor")
            completion(false)
            return
        }
        
        // Önce tüm mesaj dokümanlarını alıp sonra sil
        db.collection("chats").document(currentChannelId).collection("messages").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Mesajlar alınırken hata oluştu: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("Silinecek mesaj bulunamadı veya zaten silinmiş")
                completion(true)
                return
            }
            
            let batch = self?.db.batch()
            
            for document in documents {
                if let batch = batch, let self = self {
                    let docRef = self.db.collection("chats").document(self.currentChannelId).collection("messages").document(document.documentID)
                    batch.deleteDocument(docRef)
                }
            }
            
            batch?.commit { error in
                if let error = error {
                    print("Toplu silme işlemi sırasında hata oluştu: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Tüm sohbet başarıyla silindi")
                    completion(true)
                }
            }
        }
    }
    
    // İki kullanıcı ID'sinden channel ID oluşturan fonksiyon
    static func createChannelId(currentUserId: String, otherUserId: String) -> String {
        // ID'leri alfabetik olarak sıralayarak her zaman aynı channel ID'yi elde ediyoruz
        // böylece iki kullanıcı için her zaman aynı unique channel oluşuyor
        let sortedIds = [currentUserId, otherUserId].sorted()
        return "\(sortedIds[0])_\(sortedIds[1])"
    }
}
