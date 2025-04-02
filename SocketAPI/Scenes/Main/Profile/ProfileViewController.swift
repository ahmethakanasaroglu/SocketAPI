import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 30
        view.clipsToBounds = true
        view.backgroundColor = .systemGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = UIImage(systemName: "person.circle.fill") // Placeholder
        
        return view
    }()
    
    private let profileContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let uidLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Çıkış Yap", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        fetchUserData()
    }
    
    private func setupUI() {
        view.addSubview(profileContainerView)
        profileContainerView.addSubview(nameLabel)
        profileContainerView.addSubview(emailLabel)
        profileContainerView.addSubview(uidLabel)
        profileContainerView.addSubview(profileImageView)
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            profileImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -160),
            profileImageView.widthAnchor.constraint(equalToConstant: 65),
            profileImageView.heightAnchor.constraint(equalToConstant: 65),
            
            profileContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            profileContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            profileContainerView.heightAnchor.constraint(equalToConstant: 150),
            
            // 🆕 Name Label en üstte
            nameLabel.topAnchor.constraint(equalTo: profileContainerView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor, constant: -16),
            
            // 🆕 Email Label ortada
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor, constant: -16),
            
            // 🆕 UID Label en altta
            uidLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            uidLabel.leadingAnchor.constraint(equalTo: profileContainerView.leadingAnchor, constant: 16),
            uidLabel.trailingAnchor.constraint(equalTo: profileContainerView.trailingAnchor, constant: -16),
            uidLabel.bottomAnchor.constraint(equalTo: profileContainerView.bottomAnchor, constant: -12), // Alt kenara sabitledik
            
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            logoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").whereField("email", isEqualTo: user.email ?? "").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Kullanıcı bilgileri alınamadı: \(error.localizedDescription)")
                return
            }
            
            if let document = snapshot?.documents.first {
                let data = document.data()
                let name = data["name"] as? String ?? "Bilinmeyen Kullanıcı"
                let email = user.email ?? "Bilinmeyen E-posta"
                let uid = user.uid
                
                DispatchQueue.main.async {
                    self.uidLabel.text = "UID: \(uid)"
                    self.nameLabel.text = name
                    self.emailLabel.text = email
                }
            }
        }
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Çıkış Yap", message: "Hesabınızdan çıkış yapmak istediğinize emin misiniz?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive, handler: { _ in
            self.performLogout()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            redirectToLogin()
        } catch {
            print("❌ Çıkış yapılamadı: \(error.localizedDescription)")
        }
    }
    
    private func redirectToLogin() {
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
    }
}
