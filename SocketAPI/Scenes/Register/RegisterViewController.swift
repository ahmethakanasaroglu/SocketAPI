import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {
    private let viewModel = RegisterViewModel()
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Kayıt Ol"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.textColor = UIColor.systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Adınız"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.paddingLeft(10)
        return textField
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Kullanıcı Adı"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.paddingLeft(10)
        return textField
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.paddingLeft(10)
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.isSecureTextEntry = true
        textField.paddingLeft(10)
        return textField
    }()
    
    private let ageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Yaş"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.keyboardType = .numberPad
        textField.paddingLeft(10)
        return textField
    }()
    
    private let cityTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şehir"
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.autocapitalizationType = .words
        textField.paddingLeft(10)
        return textField
    }()
    
    private let genderSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Erkek", "Kadın", "Diğer"])
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
    
    private let genderLabel: UILabel = {
        let label = UILabel()
        label.text = "Cinsiyet:"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kayıt Ol", for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Geri Dön", for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
        bindViewModel()
        setupTextFieldDelegates()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Cinsiyet için bir satır oluştur
        let genderStackView = UIStackView(arrangedSubviews: [genderLabel, genderSegmentedControl])
        genderStackView.axis = .horizontal
        genderStackView.spacing = 10
        genderStackView.distribution = .fillProportionally
        
        // Ana stack view oluştur
        let stackView = UIStackView(arrangedSubviews: [
            nameTextField,
            usernameTextField,
            emailTextField,
            passwordTextField,
            ageTextField,
            cityTextField,
            genderStackView,
            registerButton,
            backButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    private func setupTextFieldDelegates() {
        nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        usernameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        ageTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        cityTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldChanged(_ textField: UITextField) {
        // Kullanıcı yazarken normal border'a çevir
        resetFieldBorder(textField: textField)
    }
    
    // Text field'ın çerçevesini kırmızı yap
    private func highlightFieldError(textField: UITextField) {
        textField.layer.borderColor = UIColor.systemRed.cgColor
        textField.layer.borderWidth = 2
    }
    
    // Tek bir text field'ın çerçevesini normale çevir
    private func resetFieldBorder(textField: UITextField) {
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
    }
    
    // Tüm text field'ların çerçevelerini normale çevir
    private func resetFieldBorders() {
        resetFieldBorder(textField: nameTextField)
        resetFieldBorder(textField: usernameTextField)
        resetFieldBorder(textField: emailTextField)
        resetFieldBorder(textField: passwordTextField)
        resetFieldBorder(textField: ageTextField)
        resetFieldBorder(textField: cityTextField)
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel.onRegisterSuccess = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Başarılı kayıt mesajı göster
                let alert = UIAlertController(title: "Başarılı",
                                              message: "Kayıt işlemi başarıyla tamamlandı!",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
                    // Ana ekrana yönlendir
                    let splashVC = SplashScreenViewController()
                    let navController = UINavigationController(rootViewController: splashVC)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = navController
                        window.makeKeyAndVisible()
                    }
                })
                self.present(alert, animated: true)
            }
        }
        
        viewModel.onError = { [weak self] title, message in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hataMesaji(titleInput: title, messageInput: message)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func registerTapped() {
        // Önce tüm alanları normal border'a çevir
        resetFieldBorders()
        
        // Tüm alanların dolu olup olmadığını kontrol et
        let validationResult = viewModel.validateFields(
            name: nameTextField.text,
            username: usernameTextField.text,
            email: emailTextField.text,
            password: passwordTextField.text,
            age: ageTextField.text,
            city: cityTextField.text
        )
        
        if !validationResult.isValid {
            // Format hataları varsa
            if !validationResult.errors.isEmpty {
                var errorMessages = ""
                
                // Her hata için ilgili alanı kırmızı yap ve hata mesajını ekle
                for (field, message) in validationResult.errors {
                    if field == "name" {
                        highlightFieldError(textField: nameTextField)
                        errorMessages += "- \(message)\n"
                    }
                    if field == "age" {
                        highlightFieldError(textField: ageTextField)
                        errorMessages += "- \(message)\n"
                    }
                    if field == "city" {
                        highlightFieldError(textField: cityTextField)
                        errorMessages += "- \(message)\n"
                    }
                }
                
                hataMesaji(titleInput: "Format Hatası", messageInput: errorMessages)
                return
            }
            
            // Boş alan hataları varsa
            if !validationResult.emptyFields.isEmpty {
                // Boş alanları kırmızı yap
                if validationResult.emptyFields.contains("Adınız") {
                    highlightFieldError(textField: nameTextField)
                }
                if validationResult.emptyFields.contains("Kullanıcı Adı") {
                    highlightFieldError(textField: usernameTextField)
                }
                if validationResult.emptyFields.contains("Email") {
                    highlightFieldError(textField: emailTextField)
                }
                if validationResult.emptyFields.contains("Şifre") {
                    highlightFieldError(textField: passwordTextField)
                }
                if validationResult.emptyFields.contains("Yaş") {
                    highlightFieldError(textField: ageTextField)
                }
                if validationResult.emptyFields.contains("Şehir") {
                    highlightFieldError(textField: cityTextField)
                }
                
                let errorMessage = "Lütfen aşağıdaki alanları doldurun:\n- " + validationResult.emptyFields.joined(separator: "\n- ")
                hataMesaji(titleInput: "Eksik Bilgiler", messageInput: errorMessage)
                return
            }
        }
        
        guard let ageText = ageTextField.text, viewModel.validateAge(ageText), let age = Int(ageText) else {
            highlightFieldError(textField: ageTextField)
            hataMesaji(titleInput: "Geçersiz Yaş", messageInput: "Lütfen yaş için geçerli bir sayı girin.")
            return
        }
        
        // Unwrap diğer alanları (validasyon geçtiği için güvenle unwrap edebiliriz)
        guard let name = nameTextField.text,
              let username = usernameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              let city = cityTextField.text else {
            return
        }
        
        // Cinsiyet değerini al
        let genderOptions = ["Erkek", "Kadın", "Diğer"]
        let gender = genderOptions[genderSegmentedControl.selectedSegmentIndex]
        
        // ViewModel kullanarak kayıt işlemini yap
        viewModel.registerUser(name: name, username: username, email: email, password: password, age: age, city: city, gender: gender)
    }
    
    @objc private func backTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func hataMesaji(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
