import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()  // Apple'ın network framework kütüphanesinden gelir, cihazın internet baglantı durumunu takip eder
    private let queue = DispatchQueue.global(qos: .background) // işlemi arka planda en düşük öncelikle çalıştırır, çünkü ağ izleme işlemi kritik bi öncelik degil.
    
    var isConnected: Bool = false {   // cihazın internete baglı olup olmadıgını saklar.
        didSet {
            connectionStatusChanged?(isConnected)
        }
    }
    
    var connectionStatusChanged: ((Bool) -> Void)?
    
     init() {
        monitor.pathUpdateHandler = { [weak self] path in  // weak self kullanma sebebimiz NetworkManager nesnesinin retain cycle olusturmamasıdır. (bellek sızıntısı)
            self?.isConnected = path.status == .satisfied  // baglantı varsa satisfied olur, yoksa unsatisfied
        }
        monitor.start(queue: queue)
    }
}
