import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - UsersViewModel
class UsersViewModel {
    // MARK: - Properties
    private var currentUserID: String = ""
    
    // Kullanıcı verileri
    var users: [User] = []
    var chatUsers: [User] = []
    
    // Callback'ler
    var onUsersLoaded: (() -> Void)?
    var onChatUsersLoaded: (() -> Void)?
    var onError: ((String) -> Void)?
    
    var onInternetStatusChanged: ((Bool, String) -> Void)?
    
    // MARK: - Cache System
    static let imageCache = NSCache<NSString, UIImage>()
    static var imageLoadTimestamps = [String: Date]()
    static let maxCacheAge: TimeInterval = 3600 // 1 saat cache geçerlilik süresi
    
    // MARK: - Initialization
    init() {
        if let currentUser = Auth.auth().currentUser {
            currentUserID = currentUser.uid
        }
        
        observeInternetConnection()
        setupMessageListener()
    }
    
    // MARK: - Public Methods
    func loadInitialData() {
        // Önce chat users'ı yükle, böylece boş durum hemen güncellenecek
        fetchChatUsers { [weak self] chatUsers in
            guard let self = self else { return }
            self.chatUsers = chatUsers
            self.onChatUsersLoaded?()
            
            // Sonra tüm kullanıcıları arka planda yükle
            self.fetchAllUsers { allUsers in
                self.users = allUsers
                self.onUsersLoaded?()
            }
        }
    }
    
    private func observeInternetConnection() {
        NetworkMonitor.shared.connectionStatusChanged = { [weak self] isConnected in
            let statusText = isConnected ? "" : "İnternet bağlantınız yok!"
            self?.onInternetStatusChanged?(isConnected, statusText)
        }
    }
    
    func checkInternetConnection() {
        let isConnected = NetworkMonitor.shared.isConnected
        let statusText = isConnected ? "" : "İnternet bağlantınız yok! Çıkış Yapılıyor."
        onInternetStatusChanged?(isConnected, statusText)
    }
    
    func filterUsers(with searchText: String, inChatMode: Bool) -> [User] {
        let baseList = inChatMode ? chatUsers : users
        
        if searchText.isEmpty {
            return baseList
        } else {
            return baseList.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    func getCurrentUserID() -> String {
        return currentUserID
    }
    
    // MARK: - Firebase Methods
    
    // Tüm kullanıcıları getir
    func fetchAllUsers(completion: @escaping ([User]) -> Void) {
        let db = Firestore.firestore()
        
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("Giriş yapan kullanıcı bulunamadı.")
            completion([])
            return
        }
        
        db.collection("users").whereField("email", isNotEqualTo: currentUserEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Kullanıcılar getirilemedi: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var users: [User] = []
            for document in snapshot!.documents {
                let data = document.data()
                let name = data["name"] as? String ?? "Bilinmeyen"
                let email = data["email"] as? String ?? "Bilinmeyen"
                let uid = data["uid"] as? String ?? ""
                let username = data["username"] as? String ?? "Bilinmeyen"

                let user = User(uid: uid, name: name, email: email, username: username)
                users.append(user)
            }
            
            completion(users)
        }
    }
    
    // Sohbet geçmişi olan kullanıcıları getir
    func fetchChatUsers(completion: @escaping ([User]) -> Void) {
        guard !currentUserID.isEmpty else {
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        
        // Önce kullanıcının sohbet ettiği kişileri al
        db.collection("chat_users").document(currentUserID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Sohbet kullanıcıları getirilemedi: \(error.localizedDescription)")
                completion([])
                return
            }
            
            // Kullanıcı kayıtlı değilse boş liste döndür
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
                  let chatUserIDs = data["chat_users"] as? [String] else {
                completion([])
                return
            }
            
            if chatUserIDs.isEmpty {
                completion([])
                return
            }
            
            // Sohbet edilen kullanıcıların bilgilerini getir
            var chatUsers: [User] = []
            let dispatchGroup = DispatchGroup()
            
            for userID in chatUserIDs {
                dispatchGroup.enter()
                
                db.collection("users").document(userID).getDocument { userSnapshot, userError in
                    defer { dispatchGroup.leave() }
                    
                    if let userError = userError {
                        print("Kullanıcı bilgisi getirilemedi: \(userError.localizedDescription)")
                        return
                    }
                    
                    guard let userData = userSnapshot?.data() else { return }
                    
                    let name = userData["name"] as? String ?? "Bilinmeyen"
                    let email = userData["email"] as? String ?? "Bilinmeyen"
                    let uid = userData["uid"] as? String ?? ""
                    let username = userData["username"] as? String ?? "Bilinmeyen"
                    
                    let user = User(uid: uid, name: name, email: email, username: username)
                    chatUsers.append(user)
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(chatUsers)
            }
        }
    }
    
    // MARK: - Profile Image Cache Methods
    
    // Profil resmi yükleme (Cache kullanarak)
    func loadProfileImage(userId: String, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = NSString(string: "profile_\(userId)")
        
        // Önce cache'i kontrol et ve taze ise kullan
        if let cachedImage = UsersViewModel.imageCache.object(forKey: cacheKey),
           let timestamp = UsersViewModel.imageLoadTimestamps[userId],
           Date().timeIntervalSince(timestamp) < UsersViewModel.maxCacheAge {
            print("Cache'den profil resmi yükleniyor: \(userId)")
            completion(cachedImage)
            return
        }
        
        // Cache'de yok veya bayat ise Firebase'den yükle
        print("Firebase'den profil resmi yükleniyor: \(userId)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
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
            UsersViewModel.imageCache.setObject(image, forKey: cacheKey)
            UsersViewModel.imageLoadTimestamps[userId] = Date()
            
            completion(image)
        }
    }
    
    // Cache temizleme
    func clearImageCache() {
        UsersViewModel.imageCache.removeAllObjects()
        UsersViewModel.imageLoadTimestamps.removeAll()
    }
    
    // Belirli bir kullanıcının cache'ini geçersiz kılma
    func invalidateImageCache(forUserId userId: String) {
        let cacheKey = NSString(string: "profile_\(userId)")
        UsersViewModel.imageCache.removeObject(forKey: cacheKey)
        UsersViewModel.imageLoadTimestamps.removeValue(forKey: userId)
    }
    
    // Kullanıcıyı sohbet listesine ekle
    func addUserToChats(userID: String, completion: @escaping (Bool) -> Void) {
        guard !currentUserID.isEmpty else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let chatUsersRef = db.collection("chat_users").document(currentUserID)
        
        // Önce mevcut listeyi al, sonra güncelle
        chatUsersRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            var chatUserIDs: [String] = []
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
               let existingUsers = data["chat_users"] as? [String] {
                chatUserIDs = existingUsers
            }
            
            // Kullanıcı zaten listede mi kontrol et
            if !chatUserIDs.contains(userID) {
                chatUserIDs.append(userID)
                
                // Listeyi güncelle
                chatUsersRef.setData(["chat_users": chatUserIDs]) { error in
                    if let error = error {
                        print("Sohbet kullanıcıları güncellenemedi: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Kullanıcı sohbet listesine eklendi: \(userID)")
                        completion(true)
                    }
                }
            } else {
                completion(true)
            }
        }
    }
    
    // Her iki kullanıcıyı da sohbet listelerine ekle
    func addUserToBothChatLists(otherUserID: String, completion: @escaping (Bool) -> Void = {_ in }) {
        guard !currentUserID.isEmpty else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        // 1. Mevcut kullanıcının listesine diğer kullanıcıyı ekle
        let currentUserChatRef = db.collection("chat_users").document(currentUserID)
        
        currentUserChatRef.getDocument { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            var currentUserChatList: [String] = []
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
               let existingUsers = data["chat_users"] as? [String] {
                currentUserChatList = existingUsers
            }
            
            // Kullanıcı zaten listede mi kontrol et
            if !currentUserChatList.contains(otherUserID) {
                currentUserChatList.append(otherUserID)
                
                // Listeyi güncelle
                currentUserChatRef.setData(["chat_users": currentUserChatList]) { error in
                    if let error = error {
                        print("Sohbet kullanıcıları güncellenemedi: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Kullanıcı sohbet listesine eklendi: \(otherUserID)")
                        // Listeyi reload et
                        self.loadInitialData()
                        
                        // Diğer kullanıcının listesini güncelle
                        self.addOtherUserList(otherUserID: otherUserID) { success in
                            completion(success)
                        }
                    }
                }
            } else {
                // Diğer kullanıcının listesini güncelle
                self.addOtherUserList(otherUserID: otherUserID) { success in
                    completion(success)
                }
            }
        }
    }
    
    // Diğer kullanıcının listesine mevcut kullanıcıyı ekle
    private func addOtherUserList(otherUserID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let otherUserChatRef = db.collection("chat_users").document(otherUserID)
        
        otherUserChatRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            var otherUserChatList: [String] = []
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
               let existingUsers = data["chat_users"] as? [String] {
                otherUserChatList = existingUsers
            }
            
            // Kullanıcı zaten listede mi kontrol et
            if !otherUserChatList.contains(self.currentUserID) {
                otherUserChatList.append(self.currentUserID)
                
                // Listeyi güncelle
                otherUserChatRef.setData(["chat_users": otherUserChatList]) { error in
                    if let error = error {
                        print("Sohbet kullanıcıları güncellenemedi: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Karşı kullanıcının sohbet listesine eklendi: \(self.currentUserID)")
                        completion(true)
                    }
                }
            } else {
                completion(true)
            }
        }
    }
    
    // Kullanıcıyı sohbet listesinden çıkar
    func removeUserFromChats(userID: String, completion: @escaping (Bool) -> Void) {
        guard !currentUserID.isEmpty else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let chatUsersRef = db.collection("chat_users").document(currentUserID)
        
        // Önce mevcut listeyi al, sonra güncelle
        chatUsersRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            var chatUserIDs: [String] = []
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
               let existingUsers = data["chat_users"] as? [String] {
                chatUserIDs = existingUsers
                
                // Kullanıcıyı listeden çıkar
                if let index = chatUserIDs.firstIndex(of: userID) {
                    chatUserIDs.remove(at: index)
                    
                    // Listeyi güncelle
                    chatUsersRef.setData(["chat_users": chatUserIDs]) { error in
                        if let error = error {
                            print("Sohbet kullanıcıları güncellenemedi: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("Kullanıcı sohbet listesinden çıkarıldı: \(userID)")
                            completion(true)
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    // Mesaj dinleyicisi
    private func setupMessageListener() {
        guard !currentUserID.isEmpty else { return }
        
        let db = Firestore.firestore()
        
        // Kullanıcının kanallarını dinle
        db.collection("messages")
            .whereField("receiverId", isEqualTo: currentUserID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else {
                    print("Mesaj dinleyicisi hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    return
                }
                
                // Yeni mesajlar için kontrol et
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let data = change.document.data()
                        if let senderId = data["senderId"] as? String {
                            // Yeni mesaj geldiğinde göndereni sohbet listesine ekle
                            self.addUserToBothChatLists(otherUserID: senderId)
                        }
                    }
                }
            }
    }
}
