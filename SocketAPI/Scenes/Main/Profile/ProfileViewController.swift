import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    private let themeSwitchButton = ThemeSwitchButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 50
        view.clipsToBounds = true
        view.backgroundColor = .systemGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = UIImage(systemName: "person.circle.fill")
        return view
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        textField.textColor = .label
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false // Başlangıçta değiştirilemez
        return textField
    }()
    
    private let changeNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeNameTapped), for: .touchUpInside)
        return button
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
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kaydet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.isEnabled = false // Başlangıçta devre dışı
        button.alpha = 0.5 // Aktif değilken opasiteyi %50 yaparak daha soluk göster
        return button
    }()
    
    // Aktif olmadığında butonun rengini soluklaştıran özellik
    func updateSaveButtonState(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5 // Eğer buton aktifse tam renk, değilse daha soluk
    }
    
    
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
        setupRightBarButton()
    }
    
    private func setupRightBarButton() {
        let rightBarButton = UIBarButtonItem(customView: themeSwitchButton)
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    private func setupUI() {
        navigationItem.title = "Profil"
        
        let profileStackView = UIStackView()
        profileStackView.axis = .vertical
        profileStackView.spacing = 16
        profileStackView.alignment = .center
        profileStackView.translatesAutoresizingMaskIntoConstraints = false
        
        profileStackView.addArrangedSubview(profileImageView)
        profileStackView.addArrangedSubview(nameTextField)
        profileStackView.addArrangedSubview(changeNameButton)
        profileStackView.addArrangedSubview(emailLabel)
        profileStackView.addArrangedSubview(uidLabel)
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 40
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(profileStackView)
        mainStackView.addArrangedSubview(saveButton)
        mainStackView.addArrangedSubview(logoutButton)
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.nameTextField.text = data["name"] as? String ?? ""
            self.emailLabel.text = user.email
            self.uidLabel.text = user.uid
        }
    }
    
    @objc private func saveTapped() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let newName = nameTextField.text ?? ""
        
        db.collection("users").document(user.uid).updateData(["name": newName]) { error in
            if let error = error {
                print("İsim güncellenirken hata oluştu: \(error.localizedDescription)")
            } else {
                print("İsim başarıyla güncellendi!")
                self.nameTextField.isUserInteractionEnabled = false // Kaydettikten sonra değiştiremez
                self.changeNameButton.isEnabled = true // "Değiştir" butonunu aktif et
                self.updateSaveButtonState(isEnabled: false) // "Kaydet" butonunu devre dışı bırak
            }
        }
    }
    
    @objc private func changeNameTapped() {
        nameTextField.isUserInteractionEnabled = true // Değiştirme butonuna tıklanınca textfield aktif olacak
        self.updateSaveButtonState(isEnabled: true) // "Kaydet" butonunu aktif et
        changeNameButton.isEnabled = false // "Değiştir" butonunu devre dışı bırak
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
            print("Çıkış yapılamadı: \(error.localizedDescription)")
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
