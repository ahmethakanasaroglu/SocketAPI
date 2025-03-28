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
                }    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = users[indexPath.row].name
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
        }    }
}

// Kullanıcı modeli
struct User {
    let uid: String
    let name: String
    let email: String
}

