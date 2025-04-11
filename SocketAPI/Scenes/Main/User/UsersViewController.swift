import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    // MARK: - Properties
    private let viewModel = UsersViewModel()
    
    var filteredUsers: [User] = [] // Filtrelenmiş kullanıcılar
    var isSearchActive = false // Arama modu aktif mi?
    
    // Son mesajları saklamak için dictionary ekliyorum
    var lastMessages: [String: (message: String, sender: String, timestamp: Date?)] = [:]
    
    let tableView = UITableView()
    let searchBar = UISearchBar()
    let segmentedControl = UISegmentedControl(items: ["Sohbetler", "Tüm Kullanıcılar"])
    
    private let noInternetLabel: UILabel = {
        let label = UILabel()
        label.text = "İnternet bağlantınız yok!"
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .red
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.alpha = 0 // Başlangıçta gizli
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.checkInternetConnection()  // Uygulama açıldığında interneti kontrol et

        setupUI()
        setupTableView()
        setupTapGesture() // Klavyeyi kapatmak için dokunma jesti ekle
        setupBindings()
        
        // Başlangıçta "Sohbetler" sekmesini seç
        segmentedControl.selectedSegmentIndex = 0
        segmentChanged(segmentedControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Veri yüklemeyi başlat
        viewModel.loadInitialData()
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        viewModel.onUsersLoaded = { [weak self] in
            guard let self = self else { return }
            
            if self.segmentedControl.selectedSegmentIndex == 1 {
                self.updateFilteredUsers()
            }
        }
        
        viewModel.onChatUsersLoaded = { [weak self] in
            guard let self = self else { return }
            
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.updateFilteredUsers()
                
                // Sohbet kullanıcıları yüklendiğinde her biri için son mesajları da yükle
                for user in self.viewModel.chatUsers {
                    self.loadLastMessageForUser(userId: user.uid)
                }
            }
        }
        
        // Internet bağlantısı kontrolü için callback
        viewModel.onInternetStatusChanged = { [weak self] (isConnected: Bool, message: String) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if !isConnected {
                    // İnternet bağlantısı yok
                    self.noInternetLabel.text = message
                    self.noInternetLabel.alpha = 1
                    
                    // Özel alert göster
                    self.showCustomNoInternetAlert()
                } else {
                    // İnternet bağlantısı var
                    self.noInternetLabel.alpha = 0
                }
            }
        }
    }
    
    // İnternet bağlantısı olmadığında gösterilecek uyarı
    private func showNoInternetAlert() {
        // Önce label'ı göster
        self.noInternetLabel.text = "İnternet bağlantınız yok!\nUygulama kapatılacaktır."
        self.noInternetLabel.alpha = 1
        
        // Sonra uyarı göster
        let alert = UIAlertController(title: "İnternet Bağlantısı Yok",
                                      message: "İnternet bağlantınız yok. Uygulamayı kullanabilmek için internet bağlantısı gereklidir. Uygulama kapatılacaktır.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            // Uygulamayı kapat
            exit(0)
        })
        
        self.present(alert, animated: true)
    }
    
    private func updateFilteredUsers() {
        if isSearchActive, let searchText = searchBar.text, !searchText.isEmpty {
            filteredUsers = viewModel.filterUsers(with: searchText, inChatMode: segmentedControl.selectedSegmentIndex == 0)
        } else {
            filteredUsers = segmentedControl.selectedSegmentIndex == 0 ? viewModel.chatUsers : viewModel.users
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func setupUI() {
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
        
        // İnternet bağlantısı uyarı etiketi
        view.addSubview(noInternetLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),
            
            // İnternet bağlantısı uyarı etiketi constraints
            noInternetLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noInternetLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noInternetLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            noInternetLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            noInternetLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // Segmented Control değişikliği
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        isSearchActive = false
        searchBar.text = ""
        
        if sender.selectedSegmentIndex == 0 {
            // Sohbetler
            filteredUsers = viewModel.chatUsers
            navigationItem.title = "Sohbetler"
            
            // Sohbetler sekmesinde son mesajları yükle
            for user in viewModel.chatUsers {
                loadLastMessageForUser(userId: user.uid)
            }
        } else {
            // Tüm Kullanıcılar
            filteredUsers = viewModel.users
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
        // Kullanıcıları yeniden yükle
        viewModel.loadInitialData()
        
        // Son mesajları yeniden yükle
        if segmentedControl.selectedSegmentIndex == 0 {
            for user in viewModel.chatUsers {
                loadLastMessageForUser(userId: user.uid)
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Last Message Loading
    
    // Son mesajları yüklemek için yeni fonksiyon
    func loadLastMessageForUser(userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // İki kullanıcı arasındaki channel ID'yi oluştur
        let channelId = WebSocketManager.createChannelId(currentUserId: currentUserId, otherUserId: userId)
        
        // Firestore'dan son mesajı çek
        let db = Firestore.firestore()
        db.collection("chats").document(channelId).collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Son mesaj yüklenirken hata: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let message = document.data()["message"] as? String,
                      let senderId = document.data()["senderId"] as? String else {
                    // Son mesaj yok
                    self?.lastMessages[userId] = ("Henüz mesaj yok", "", nil)
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    return
                }
                
                // Mesaj göndereni belirle (ben/diğer kullanıcı)
                let senderPrefix = (senderId == currentUserId) ? "Siz: " : ""
                
                // Timestamp varsa al
                var timestamp: Date? = nil
                if let timestampValue = document.data()["timestamp"] as? Timestamp {
                    timestamp = timestampValue.dateValue()
                }
                
                // Son mesaj bilgisini güncelle
                self?.lastMessages[userId] = (message: message, sender: senderPrefix, timestamp: timestamp)
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
    }
    
    // Mesaj zamanını formatlama fonksiyonu
    func formatMessageTime(_ date: Date?) -> String {
        guard let date = date else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Bugün içindeyse saat:dakika göster
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        // Dün ise "Dün" yaz
        else if calendar.isDateInYesterday(date) {
            return "Dün"
        }
        // Bu hafta içindeyse gün adını göster
        else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now), date > weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Gün adı
            formatter.locale = Locale(identifier: "tr_TR") // Türkçe gün adları için
            return formatter.string(from: date)
        }
        // Diğer durumlar için tarih göster
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearchActive = !searchText.isEmpty
        
        if isSearchActive {
            filteredUsers = viewModel.filterUsers(with: searchText, inChatMode: segmentedControl.selectedSegmentIndex == 0)
        } else {
            filteredUsers = segmentedControl.selectedSegmentIndex == 0 ? viewModel.chatUsers : viewModel.users
        }
        
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
        
        // Son mesaj bilgisini al
        let lastMessageInfo = lastMessages[user.uid]
        
        // Sohbetler sekmesinde son mesajı göster, Tüm Kullanıcılar sekmesinde email göster
        if segmentedControl.selectedSegmentIndex == 0 {
            let messageText = lastMessageInfo?.message ?? "Henüz mesaj yok"
            let senderPrefix = lastMessageInfo?.sender ?? ""
            let timestampStr = formatMessageTime(lastMessageInfo?.timestamp)
            
            cell.configure(with: user, subtitle: "\(senderPrefix)\(messageText)", time: timestampStr)
        } else {
            cell.configure(with: user, subtitle: user.username, time: "")
        }
        
        // Profil fotoğrafını cache kullanarak yükle
        cell.loadProfileImage(for: user.uid)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Hücreye tıklandığında klavyeyi kapat
        view.endEditing(true)
        
        let selectedUser = filteredUsers[indexPath.row]
        
        // Kullanıcıyı sohbet listesine ekle
        viewModel.addUserToBothChatLists(otherUserID: selectedUser.uid) { [weak self] success in
            guard let self = self, success else { return }
            self.openChat(with: selectedUser)
        }
    }
    
    // Kaydırmalı silme işlemi ekle
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Sadece sohbetler sekmesinde silme özelliği olsun
        if segmentedControl.selectedSegmentIndex == 0 {
            let deleteAction = UIContextualAction(style: .destructive, title: "Sil") { [weak self] (_, _, completionHandler) in
                guard let self = self else { return }
                
                let userToRemove = self.filteredUsers[indexPath.row]
                
                // Kullanıcıyı sohbet listesinden çıkar
                self.viewModel.removeUserFromChats(userID: userToRemove.uid) { success in
                    if success {
                        DispatchQueue.main.async {
                            // Filtrelenmiş ve gösterilen listeden kullanıcıyı çıkar
                            self.filteredUsers.remove(at: indexPath.row)
                            
                            // Yerel chatUsers listesinden de kullanıcıyı çıkar
                            if let index = self.viewModel.chatUsers.firstIndex(where: { $0.uid == userToRemove.uid }) {
                                self.viewModel.chatUsers.remove(at: index)
                            }
                            
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                    completionHandler(success)
                }
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
        let currentUserId = viewModel.getCurrentUserID()
        
        // İki kullanıcı ID'sinden unique channel ID oluştur
        let channelId = WebSocketManager.createChannelId(currentUserId: currentUserId, otherUserId: user.uid)
        chatVC.channelId = channelId
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: chatVC)
            window.makeKeyAndVisible()
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

// Custom TableViewCell - Güncellenmiş Versiyon
class UserTableViewCell: UITableViewCell {
    
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeLabel = UILabel() // Zaman etiketi
    
    // Yükleme göstergesi
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Profil fotoğrafının yüklenmesiyle ilgili değişkenler
    private var isLoadingProfileImage = false
    private var currentLoadingUserId: String?
    
    // ViewModel referansı
    private let viewModel = UsersViewModel()
    
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
        
        // Yükleme göstergesini ayarla
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.addSubview(loadingIndicator)
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Zaman etiketi eklendi
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.textAlignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
        
        // AutoLayout constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Yükleme göstergesi için constraints
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    // Hücre yeniden kullanıldığında içeriği temizle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Yüklemeyi iptal et ve yükleme göstergesini durdur
        if isLoadingProfileImage {
            loadingIndicator.stopAnimating()
            isLoadingProfileImage = false
            currentLoadingUserId = nil
        }
        
        // Varsayılan profil resmini göster
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        
        // Diğer içerikleri temizle
        nameLabel.text = nil
        subtitleLabel.text = nil
        timeLabel.text = nil
    }
    
    func configure(with user: User, subtitle: String, time: String) {
        nameLabel.text = user.name
        subtitleLabel.text = subtitle
        timeLabel.text = time
        
        // Başlangıçta varsayılan profil ikonu göster
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
    }
    
    // Profil fotoğrafını cache kullanarak yükle
    func loadProfileImage(for userId: String) {
        // Eğer zaten aynı kullanıcı için yükleme yapılıyorsa tekrar yükleme
        if currentLoadingUserId == userId && isLoadingProfileImage {
            return
        }
        
        // Yükleme durumunu güncelle
        isLoadingProfileImage = true
        currentLoadingUserId = userId
        
        // Yükleme göstergesini başlat
        loadingIndicator.startAnimating()
        
        // Cache kullanarak profil resmini yükle
        viewModel.loadProfileImage(userId: userId) { [weak self] image in
            DispatchQueue.main.async {
                // Yükleme göstergesini durdur
                self?.loadingIndicator.stopAnimating()
                self?.isLoadingProfileImage = false
                
                // Eğer hücre artık farklı bir kullanıcıya atanmışsa işlemi iptal et
                guard let self = self, self.currentLoadingUserId == userId else {
                    return
                }
                
                if let image = image {
                    self.profileImageView.image = image
                    self.profileImageView.tintColor = .clear
                } else {
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self.profileImageView.tintColor = .systemBlue
                }
                
                self.currentLoadingUserId = nil
            }
        }
    }
}

// ViewController içinde kullanım örneği
extension UsersViewController {
    func showCustomNoInternetAlert() {
        let customAlert = CustomAlertView(
            title: "İnternet Bağlantısı Yok",
            message: "İnternet bağlantınız yok. Uygulamayı kullanabilmek için internet bağlantısı gereklidir. Uygulama kapatılacaktır.",
            buttonTitle: "Tamam"
        )
        
        customAlert.onDismiss = {
            exit(0)
        }
        
        customAlert.show(in: self)
    }
}
