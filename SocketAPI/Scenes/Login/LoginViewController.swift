import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    let viewModel = LoginViewModel()
    
    // Arka plan gradient
    let gradientLayer = CAGradientLayer()
    
    // Logo/Icon için ImageView
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Başlık Label'ı
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hoş Geldiniz" // Başlık
        label.font = UIFont(name: "AvenirNext-Bold", size: 28) ?? UIFont.boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Alt başlık Label'ı
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hesabınıza giriş yapın" // Alt başlık
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Kullanıcı giriş bilgileri için konteyner görünümü
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let emailOrUsernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email veya Kullanıcı Adı"
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.returnKeyType = .next
        textField.paddingLeft(12)
        
        // Email ikonu ekle (3 boşluk sağa)
        let emailIcon = UIImageView(frame: CGRect(x: 12, y: 0, width: 20, height: 20))
        emailIcon.image = UIImage(systemName: "envelope.fill")
        emailIcon.tintColor = .systemBlue.withAlphaComponent(0.7)
        emailIcon.contentMode = .scaleAspectFit
        
        // Konteyner görünümü oluştur
        let emailIconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        emailIconContainerView.addSubview(emailIcon)
        
        // İkonu dikey olarak ortala
        emailIcon.center.y = emailIconContainerView.center.y
        
        textField.leftView = emailIconContainerView
        textField.leftViewMode = .always
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre"
        textField.borderStyle = .none
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.paddingLeft(12)
        
        // Şifre ikonu ekle (2 boşluk sağa)
        let passwordIcon = UIImageView(frame: CGRect(x: 12, y: 0, width: 20, height: 20))
        passwordIcon.image = UIImage(systemName: "lock.fill")
        passwordIcon.tintColor = .systemBlue.withAlphaComponent(0.7)
        passwordIcon.contentMode = .scaleAspectFit
        
        // Konteyner görünümü oluştur
        let passwordIconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        passwordIconContainerView.addSubview(passwordIcon)
        
        // İkonu dikey olarak ortala
        passwordIcon.center.y = passwordIconContainerView.center.y
        
        textField.leftView = passwordIconContainerView
        textField.leftViewMode = .always
        
        // Şifre görünürlük butonu ekle
        let showPasswordButton = UIButton(type: .custom)
        showPasswordButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        showPasswordButton.tintColor = .systemGray
        showPasswordButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        showPasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 50))
        rightView.addSubview(showPasswordButton)
        showPasswordButton.center = rightView.center
        
        textField.rightView = rightView
        textField.rightViewMode = .always
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    // Şifremi unuttum butonu
    let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Şifremi Unuttum", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Giriş Yap", for: .normal)
        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Gölge ekle
        button.layer.shadowColor = UIColor.systemBlue.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.4
        
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Hesabınız yok mu? metni
    let noAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Hesabınız yok mu?"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kayıt Ol", for: .normal)
        button.setTitleColor(.orange, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        bindViewModel()
        setupGestureRecognizers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        
        // İkonların dikey hizalaması için viewDidLayoutSubviews içinde kontrol ediyoruz
        adjustIconVerticalPositions()
    }
    
    // İkonların dikey hizalaması için yardımcı metod
    private func adjustIconVerticalPositions() {
        if let emailContainerView = emailOrUsernameTextField.leftView as? UIView,
           let emailIcon = emailContainerView.subviews.first as? UIImageView {
            emailIcon.center.y = emailContainerView.bounds.height / 2
        }
        
        if let passwordContainerView = passwordTextField.leftView as? UIView,
           let passwordIcon = passwordContainerView.subviews.first as? UIImageView {
            passwordIcon.center.y = passwordContainerView.bounds.height / 2
        }
    }
    
    func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor(red: 0/255, green: 91/255, blue: 187/255, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setupUI() {
        // Logo ve başlıklar
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        // Konteyner view
        view.addSubview(containerView)
        
        // Text field'lar ve butonlar
        containerView.addSubview(emailOrUsernameTextField)
        containerView.addSubview(passwordTextField)
        containerView.addSubview(forgotPasswordButton)
        containerView.addSubview(loginButton)
        
        // Kayıt ol bölümü (altta)
        let registerStack = UIStackView(arrangedSubviews: [noAccountLabel, registerButton])
        registerStack.axis = .horizontal
        registerStack.spacing = 8
        registerStack.alignment = .center
        registerStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(registerStack)
        
        NSLayoutConstraint.activate([
            // Logo
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Başlık
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Alt Başlık
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Konteyner View
            containerView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            
            // Email/Username TextField
            emailOrUsernameTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            emailOrUsernameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            emailOrUsernameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            emailOrUsernameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password TextField
            passwordTextField.topAnchor.constraint(equalTo: emailOrUsernameTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Şifremi Unuttum Butonu
            forgotPasswordButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            forgotPasswordButton.heightAnchor.constraint(equalToConstant: 20),
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 54),
            loginButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            
            // Kayıt ol stack
            registerStack.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            registerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupGestureRecognizers() {
        // Klavyeyi kapatmak için boş alana tıklama
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // TextField özelleştirmeleri için
        emailOrUsernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        
        if passwordTextField.isSecureTextEntry {
            sender.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        } else {
            sender.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        }
    }
    
    @objc func forgotPasswordTapped() {
        // Şifremi unuttum işlemi
        let alert = UIAlertController(title: "Şifre Sıfırlama", message: "Şifre sıfırlama bağlantısı e-posta adresinize gönderilecektir.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "E-posta adresinizi girin"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        let sendAction = UIAlertAction(title: "Gönder", style: .default) { [weak self] _ in
            guard let self = self, let email = alert.textFields?.first?.text, !email.isEmpty else {
                self?.hataMesaji(titleInput: "Hata", messageInput: "Lütfen geçerli bir e-posta adresi girin")
                return
            }
            
            // Burada şifre sıfırlama işlemini başlat
            self.viewModel.resetPassword(email: email)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(sendAction)
        present(alert, animated: true)
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
        
        viewModel.onPasswordResetSent = {
            DispatchQueue.main.async {
                self.hataMesaji(titleInput: "Başarılı", messageInput: "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.")
            }
        }
    }
    
    // Buton animasyonu için yardımcı metod
    func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform.identity
            }
        }
    }
    
    @objc func loginTapped() {
        // Buton animasyonu
        animateButton(loginButton)
        
        guard let emailOrUsername = emailOrUsernameTextField.text,
              let password = passwordTextField.text,
              !emailOrUsername.isEmpty,
              !password.isEmpty else {
            hataMesaji(titleInput: "Hata!", messageInput: "Email/Kullanıcı Adı ve Şifre Giriniz")
            
            // Hata animasyonu
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.duration = 0.6
            animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.5, 2.5, 0.0]
            
            if emailOrUsernameTextField.text?.isEmpty ?? true {
                emailOrUsernameTextField.layer.add(animation, forKey: "shake")
            }
            
            if passwordTextField.text?.isEmpty ?? true {
                passwordTextField.layer.add(animation, forKey: "shake")
            }
            
            return
        }
        
        // Yükleniyor animasyonu göster
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        
        let originalTitle = loginButton.title(for: .normal)
        loginButton.setTitle("", for: .normal)
        loginButton.addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: loginButton.bounds.midX, y: loginButton.bounds.midY)
        
        // Güncellenen login metodunu çağır
        viewModel.login(emailOrUsername: emailOrUsername, password: password)
        
        // Hata durumunda animasyonu geri al
        viewModel.onError = { [weak self] errorMessage in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                self.loginButton.setTitle(originalTitle, for: .normal)
                self.hataMesaji(titleInput: "Hata!", messageInput: errorMessage)
            }
        }
    }
    
    @objc func registerTapped() {
        // Buton animasyonu
        animateButton(registerButton)
        
        // Yeni Register ekranını aç
        let registerVC = RegisterViewController()
        registerVC.modalPresentationStyle = .fullScreen
        
        // Geçiş animasyonu ekle
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.window?.layer.add(transition, forKey: kCATransition)
        
        present(registerVC, animated: false)
    }
    
    func hataMesaji(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// TextField animasyonları ve özelleştirmeleri için extension
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            textField.layer.borderColor = UIColor.systemBlue.cgColor
            textField.layer.borderWidth = 2
            textField.backgroundColor = UIColor.white
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            textField.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
            textField.layer.borderWidth = 1
            
            // Eğer metin girildiyse arka plan rengini değiştir
            if !(textField.text?.isEmpty ?? true) {
                textField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)
            } else {
                textField.backgroundColor = UIColor.white
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailOrUsernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginTapped()
        }
        return true
    }
}

extension UITextField {
    func paddingLeft(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
