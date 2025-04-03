import UIKit
import Firebase
import FirebaseAuth

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var users: [User] = [] // Kullanıcıları burada saklayacağız
    var filteredUsers: [User] = [] // Filtrelenmiş kullanıcılar
    let tableView = UITableView()
    let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUsers { fetchedUsers in
            self.users = fetchedUsers
            self.filteredUsers = fetchedUsers
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func setupUI() {
        navigationItem.title = "Sohbetler"
        
        searchBar.placeholder = "Kullanıcı ara"
        searchBar.delegate = self
        searchBar.sizeToFit()
        searchBar.backgroundImage = UIImage()
        searchBar.isTranslucent = true
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        
        tableView.tableHeaderView = searchBar // Arama çubuğunu başlık olarak ekledik
    }
    
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 16) // Profil resmi hizasında çizgi başlasın
        tableView.backgroundColor = .systemGroupedBackground
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshUserList), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshUserList() {
        fetchUsers { [weak self] fetchedUsers in
            guard let self = self else { return }
            self.users = fetchedUsers
            self.filteredUsers = fetchedUsers
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    func fetchUsers(completion: @escaping ([User]) -> Void) {
        let db = Firestore.firestore()
        
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("❌ Giriş yapan kullanıcı bulunamadı.")
            completion([])
            return
        }
        
        db.collection("users").whereField("email", isNotEqualTo: currentUserEmail).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Kullanıcılar getirilemedi: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var users: [User] = []
            for document in snapshot!.documents {
                let data = document.data()
                let name = data["name"] as? String ?? "Bilinmeyen"
                let email = data["email"] as? String ?? "Bilinmeyen"
                let uid = data["uid"] as? String ?? ""
                
                let user = User(uid: uid, name: name, email: email)
                users.append(user)
            }
            
            completion(users)
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
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
        let selectedUser = filteredUsers[indexPath.row]
        openChat(with: selectedUser)
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
            print("❌ Mevcut kullanıcı oturum açmamış!")
        }
    }
}

// Kullanıcı modeli
struct User {
    let uid: String
    let name: String
    let email: String
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
