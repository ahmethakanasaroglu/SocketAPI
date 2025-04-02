import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    let viewModel = LoginViewModel()
    
    // Başlık Label'ı
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hoş Geldiniz" // Başlık
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.textColor = UIColor.systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .none
        textField.paddingLeft(10)
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .none
        textField.isSecureTextEntry = true
        textField.paddingLeft(10)
        return textField
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Adınız"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .none
        textField.paddingLeft(10)
        return textField
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Giriş Yap", for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kayıt Ol", for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
        bindViewModel()
    }
    
    func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [nameTextField, emailTextField, passwordTextField, loginButton, registerButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel) // Başlık Label'ı ekliyoruz
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    func bindViewModel() {
        viewModel.onLoginSuccess = {
            DispatchQueue.main.async {
                let chatVC = UsersViewController()
                chatVC.modalPresentationStyle = .fullScreen
                self.present(chatVC, animated: true, completion: nil)
            }
        }
        
        viewModel.onError = { errorMessage in
            DispatchQueue.main.async {
                self.hataMesaji(titleInput: "Hata!", messageInput: errorMessage)
            }
        }
    }
    
    @objc func loginTapped() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text, !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            hataMesaji(titleInput: "Hata!", messageInput: "İsim, Email ve Şifre Giriniz")
            return
        }
        viewModel.login(email: email, password: password)
    }
    
    @objc func registerTapped() {
        guard let name = nameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            hataMesaji(titleInput: "Hata!", messageInput: "İsim, Email ve Şifre Giriniz")
            return
        }
        
        viewModel.register(name: name, email: email, password: password) { success in
            DispatchQueue.main.async {
                if success {
                    let alert = UIAlertController(title: "Başarılı",
                                                  message: "Kayıt işlemi başarıyla tamamlandı!",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
                        // Kullanıcı başarılı kayıt olduktan sonra UsersViewController'a yönlendir
                        let usersVC = MainTabBarController()
                        let navController = UINavigationController(rootViewController: usersVC)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first{
                            window.rootViewController = navController
                            window.makeKeyAndVisible()
                        }
                    })
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.hataMesaji(titleInput: "Hata!", messageInput: "Kayıt sırasında bir hata oluştu.")
                }
            }
        }
    }

    
    func hataMesaji(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

extension UITextField {
    func paddingLeft(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
