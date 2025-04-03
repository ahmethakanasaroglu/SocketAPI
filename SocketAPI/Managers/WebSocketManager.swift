import Foundation
import Starscream

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveMessage(_ message: String)
}

class WebSocketManager: NSObject, WebSocketDelegate {
    var socket: WebSocket?
    weak var delegate: WebSocketManagerDelegate?
    private var currentChannelId: String = ""
    private var isConnected: Bool = false
    
    override init() {
        super.init()
        // İlk başta socket'i oluşturmuyoruz, channelId belirlendiğinde oluşturacağız
    }
    
    func setupSocketWithChannelId(_ channelId: String) {
        // Eğer zaten bu channelId ile bağlıysak, tekrar bağlanmaya gerek yok
        if currentChannelId == channelId && isConnected {
            return
        }
        
        // Eğer farklı bir channel'a bağlıysak, önce onu kapatıyoruz
        if isConnected {
            disconnect()
        }
        
        currentChannelId = channelId
        let request = URLRequest(url: URL(string: "wss://free.blr2.piesocket.com/v3/\(channelId)?api_key=Prb34C9fTmugVUUMU30dCZNCfjS4019gFpzWEXJ8")!)
        socket = WebSocket(request: request)
        socket?.delegate = self
    }
    
    func connect() {
        if socket == nil {
            print("❌ Socket henüz kurulmadı. Önce setupSocketWithChannelId fonksiyonunu çağırın.")
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
    }
    
    // WebSocket olaylarını dinleyen fonksiyon
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(_):
            isConnected = true
            print("✅ WebSocket Bağlandı - Channel: \(currentChannelId)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("❌ WebSocket Koptu: \(reason) (Code: \(code))")
        case .text(let message):
            print("📩 Mesaj Alındı: \(message)")
            delegate?.didReceiveMessage(message)
        case .error(let error):
            print("⚠️ Hata Oluştu: \(String(describing: error))")
        default:
            break
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
