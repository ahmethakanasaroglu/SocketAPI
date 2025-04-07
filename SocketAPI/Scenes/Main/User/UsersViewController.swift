import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var users: [User] = [] // Tüm kullanıcıları burada saklayacağız
    var chatUsers: [User] = [] // Sadece sohbet geçmişi olanlar
    var filteredUsers: [User] = [] // Filtrelenmiş kullanıcılar
    var isSearchActive = false // Arama modu aktif mi?
    
    let tableView = UITableView()
    let searchBar = UISearchBar()
    let segmentedControl = UISegmentedControl(items: ["Sohbetler", "Tüm Kullanıcılar"])
    
    // Kullanıcının ID'si
    private var currentUserID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Mevcut kullanıcı ID'sini al
        if let currentUser = Auth.auth().currentUser {
            currentUserID = currentUser.uid
        }
        
        setupUI()
        setupTableView()
        setupTapGesture() // Klavyeyi kapatmak için dokunma jesti ekle
        
        // Başlangıçta "Sohbetler" sekmesini seç
        segmentedControl.selectedSegmentIndex = 0
        segmentChanged(segmentedControl)
        
        // Mesaj dinleyicisini ekle
        setupMessageListener()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hem tüm kullanıcıları hem de sohbet geçmişi olanları getir
        fetchAllUsers { [weak self] allUsers in
            guard let self = self else { return }
            self.users = allUsers
            
            // Sohbet geçmişi olan kullanıcıları getir
            self.fetchChatUsers { chatUsers in
                self.chatUsers = chatUsers
                
                // Segmented control'e göre hangi liste gösterilecek
                if self.segmentedControl.selectedSegmentIndex == 0 {
                    self.filteredUsers = self.chatUsers
                } else {
                    self.filteredUsers = self.users
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // Mesaj dinleyicisi ekleyelim (yeni eklenen)
    func setupMessageListener() {
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
                            self.addUserToBothChatLists(currentUserID: self.currentUserID, otherUserID: senderId)
                        }
                    }
                }
            }
    }
    
    func setupUI() {
        navigationItem.title = "Sohbetler"
        
        // Segmented Control
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Search Bar
        searchBar.placeholder = "Kullanıcı ara"
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.backgroundImage = UIImage()
        searchBar.isTranslucent = true
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        
        // Constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    // Segmented Control değişikliği
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        isSearchActive = false
        searchBar.text = ""
        
        if sender.selectedSegmentIndex == 0 {
            // Sohbetler
            filteredUsers = chatUsers
            navigationItem.title = "Sohbetler"
        } else {
            // Tüm Kullanıcılar
            filteredUsers = users
            navigationItem.title = "Tüm Kullanıcılar"
        }
        
        tableView.reloadData()
    }
    
    // Ekrana dokunma jesti ekleyerek klavyeyi kapatma
    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // Diğer dokunma işlemlerini engelleme
        view.addGestureRecognizer(tapGesture)
    }
    
    // Klavyeyi kapatma methodu
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 16) // Profil resmi hizasında çizgi başlasın
        tableView.backgroundColor = .systemGroupedBackground
        
        // Search bar'ı header'a ekle
        tableView.tableHeaderView = searchBar
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshUserList), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func refreshUserList() {
        fetchAllUsers { [weak self] allUsers in
            guard let self = self else { return }
            self.users = allUsers
            
            self.fetchChatUsers { chatUsers in
                self.chatUsers = chatUsers
                
                if self.segmentedControl.selectedSegmentIndex == 0 {
                    self.filteredUsers = self.chatUsers
                } else {
                    self.filteredUsers = self.users
                }
                
                if self.isSearchActive, let searchText = self.searchBar.text, !searchText.isEmpty {
                    self.filterUsers(with: searchText)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
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
    
    // Kullanıcıyı sohbet listesine ekle
    func addUserToChats(userID: String) {
        guard !currentUserID.isEmpty else { return }
        
        let db = Firestore.firestore()
        let chatUsersRef = db.collection("chat_users").document(currentUserID)
        
        // Önce mevcut listeyi al, sonra güncelle
        chatUsersRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
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
                    } else {
                        print("Kullanıcı sohbet listesine eklendi: \(userID)")
                    }
                }
            }
        }
    }
    
    // YENİ EKLENEN: Her iki kullanıcıyı da sohbet listelerine ekle
    func addUserToBothChatLists(currentUserID: String, otherUserID: String) {
        let db = Firestore.firestore()
        
        // 1. Mevcut kullanıcının listesine diğer kullanıcıyı ekle
        let currentUserChatRef = db.collection("chat_users").document(currentUserID)
        
        currentUserChatRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
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
                    } else {
                        print("Kullanıcı sohbet listesine eklendi: \(otherUserID)")
                        
                        // Sohbet listesini güncelledikten sonra UI güncellemesi yap
                        DispatchQueue.main.async {
                            self.refreshUserList()
                        }
                    }
                }
            }
        }
        
        // 2. Diğer kullanıcının listesine mevcut kullanıcıyı ekle
        let otherUserChatRef = db.collection("chat_users").document(otherUserID)
        
        otherUserChatRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
                return
            }
            
            var otherUserChatList: [String] = []
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data(),
               let existingUsers = data["chat_users"] as? [String] {
                otherUserChatList = existingUsers
            }
            
            // Kullanıcı zaten listede mi kontrol et
            if !otherUserChatList.contains(currentUserID) {
                otherUserChatList.append(currentUserID)
                
                // Listeyi güncelle
                otherUserChatRef.setData(["chat_users": otherUserChatList]) { error in
                    if let error = error {
                        print("Sohbet kullanıcıları güncellenemedi: \(error.localizedDescription)")
                    } else {
                        print("Karşı kullanıcının sohbet listesine eklendi: \(currentUserID)")
                    }
                }
            }
        }
    }
    
    // Kullanıcıyı sohbet listesinden çıkar
    func removeUserFromChats(userID: String) {
        guard !currentUserID.isEmpty else { return }
        
        let db = Firestore.firestore()
        let chatUsersRef = db.collection("chat_users").document(currentUserID)
        
        // Önce mevcut listeyi al, sonra güncelle
        chatUsersRef.getDocument { snapshot, error in
            if let error = error {
                print("Sohbet kullanıcıları alınamadı: \(error.localizedDescription)")
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
                        } else {
                            print("Kullanıcı sohbet listesinden çıkarıldı: \(userID)")
                        }
                    }
                }
            }
        }
    }
    
    // Kullanıcı arama
    func filterUsers(with searchText: String) {
        let baseList = segmentedControl.selectedSegmentIndex == 0 ? chatUsers : users
        
        if searchText.isEmpty {
            filteredUsers = baseList
        } else {
            filteredUsers = baseList.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearchActive = !searchText.isEmpty
        filterUsers(with: searchText)
        tableView.reloadData()
    }
    
    // Arama yapılırken Search butonuna basıldığında klavyeyi kapat
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - TableView Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        let user = filteredUsers[indexPath.row]
        cell.configure(with: user)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Hücreye tıklandığında klavyeyi kapat
        view.endEditing(true)
        
        let selectedUser = filteredUsers[indexPath.row]
        
        // İki kullanıcıyı da birbirinin sohbet listesine ekle
        if let currentUser = Auth.auth().currentUser {
            addUserToBothChatLists(currentUserID: currentUser.uid, otherUserID: selectedUser.uid)
        }
        
        openChat(with: selectedUser)
    }
    
    // Kaydırmalı silme işlemi ekle
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Sadece sohbetler sekmesinde silme özelliği olsun
        if segmentedControl.selectedSegmentIndex == 0 {
            let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] (_, _, completionHandler) in
                guard let self = self else { return }
                
                let userToRemove = self.filteredUsers[indexPath.row]
                
                // Kullanıcıyı sohbet listesinden çıkar
                self.removeUserFromChats(userID: userToRemove.uid)
                
                // Yerel listeden de çıkar
                if let index = self.chatUsers.firstIndex(where: { $0.uid == userToRemove.uid }) {
                    self.chatUsers.remove(at: index)
                }
                
                self.filteredUsers.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                completionHandler(true)
            }
            
            deleteAction.image = UIImage(systemName: "trash")
            
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
        }
        
        return nil
    }
    
    func openChat(with user: User) {
        let chatVC = ChatViewController()
        chatVC.selectedUser = user
        
        // Mevcut kullanıcının UID'sini al
        if let currentUser = Auth.auth().currentUser {
            let currentUserId = currentUser.uid
            
            // İki kullanıcı ID'sinden unique channel ID oluştur
            let channelId = WebSocketManager.createChannelId(currentUserId: currentUserId, otherUserId: user.uid)
            chatVC.channelId = channelId
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UINavigationController(rootViewController: chatVC)
                window.makeKeyAndVisible()
            }
        } else {
            print("Mevcut kullanıcı oturum açmamış!")
        }
    }
}

// Kullanıcı modeli
struct User {
    let uid: String
    let name: String
    let email: String
    let username: String
}

// Custom TableViewCell
class UserTableViewCell: UITableViewCell {
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        profileImageView.layer.cornerRadius = 30
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        emailLabel.font = UIFont.systemFont(ofSize: 14)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emailLabel)
        
        // AutoLayout constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        profileImageView.image = UIImage(systemName: "person.circle.fill") // Placeholder
    }
}
