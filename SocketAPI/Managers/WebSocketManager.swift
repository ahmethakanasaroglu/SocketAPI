import Foundation
import Starscream

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveMessage(_ message: String)
}

class WebSocketManager: NSObject, WebSocketDelegate {
    var socket: WebSocket?
    weak var delegate: WebSocketManagerDelegate?

    override init() {
        super.init()
        var request = URLRequest(url: URL(string: "wss://socketsbay.com/wss/v2/1/demo/")!)
        socket = WebSocket(request: request)
        socket?.delegate = self
    }

    func connect() {
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func sendMessage(_ message: String) {
        socket?.write(string: message)
    }

    // WebSocket olaylarını dinleyen fonksiyon
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(_):
            print("✅ WebSocket Bağlandı")
        case .disconnected(let reason, let code):
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
}
