import UIKit
import Firebase
import FirebaseAuth

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var users: [User] = [] // Kullanıcıları burada saklayacağız
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchUsers { fetchedUsers in
            self.users = fetchedUsers
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        
        tableView.separatorStyle = .none // Hücreler arasındaki çizgileri kaldırıyoruz
        tableView.backgroundColor = .systemGroupedBackground // Arka plan rengini şık yapıyoruz
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
    
    // MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        let user = users[indexPath.row]
        cell.configure(with: user)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        openChat(with: selectedUser)
    }
    
    func openChat(with user: User) {
        let chatVC = ChatViewController()
        chatVC.selectedUser = user
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
        
        // Profil fotoğrafı eklenmesi
        // Profil fotoğrafı eklenmediyse varsayılan bir fotoğraf kullanılabilir
        // Burada bir placeholder görüntü veya profil fotoğrafı URL'si yüklenebilir
        profileImageView.image = UIImage(systemName: "person.circle.fill") // Placeholder
    }
}
