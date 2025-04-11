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
    
    // MARK: - Yükleniyor Göstergesi
    private let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Kayıt yapılıyor..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Adınız - Soyadınız"
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
    
    // YENİ: Şifre onay alanı
    private let confirmPasswordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Şifre Onayı"
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
        textField.autocorrectionType = .no
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
    
    // MARK: - Password Visibility Buttons
    private let passwordToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .systemGray
        button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        return button
    }()
    
    private let confirmPasswordToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .systemGray
        button.addTarget(self, action: #selector(toggleConfirmPasswordVisibility), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupUI()
        setupLoadingView()
        setupPasswordVisibilityButtons()
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
            confirmPasswordTextField, // YENİ: Şifre onay alanı eklendi
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
    
    // MARK: - Loading View Setup
    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(loadingLabel)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -20),
            
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 20),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Show/Hide Loading
    private func showLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingView.isHidden = false
            self.activityIndicator.startAnimating()
            self.view.isUserInteractionEnabled = false
        }
    }
    
    private func hideLoading() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadingView.isHidden = true
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Password Visibility Buttons Setup
    private func setupPasswordVisibilityButtons() {
        // Şifre alanı için göz ikonu
        passwordTextField.rightView = passwordToggleButton
        passwordTextField.rightViewMode = .always
        
        // Şifre onay alanı için göz ikonu
        confirmPasswordTextField.rightView = confirmPasswordToggleButton
        confirmPasswordTextField.rightViewMode = .always
        
        // Butonlar için sağ kenar boşluğu ayarla
        passwordToggleButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        confirmPasswordToggleButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        passwordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func toggleConfirmPasswordVisibility() {
        confirmPasswordTextField.isSecureTextEntry.toggle()
        let imageName = confirmPasswordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        confirmPasswordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func setupTextFieldDelegates() {
        nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        usernameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged) // YENİ
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
        resetFieldBorder(textField: confirmPasswordTextField) // YENİ
        resetFieldBorder(textField: ageTextField)
        resetFieldBorder(textField: cityTextField)
    }
    
    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel.onRegisterSuccess = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Yükleme göstergesini gizle
                self.hideLoading()
                
                // Başarılı kayıt mesajı göster
                let alert = UIAlertController(title: "✅ Başarılı",
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
                // Yükleme göstergesini gizle
                self.hideLoading()
                
                // Hata mesajını göster
                self.hataMesaji(titleInput: title, messageInput: message)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func registerTapped() {
        // Önce tüm alanları normal border'a çevir
        resetFieldBorders()
        
        // Boş alan kontrollerini yap
        var emptyFields: [String] = []
        var formatErrors: [(field: String, message: String)] = []
        
        // Adınız-Soyadınız kontrolü
        if let name = nameTextField.text, !name.isEmpty {
            // İsim sadece harflerden ve boşluklardan oluşmalı
            let nonSpaceCharacters = name.filter { !$0.isWhitespace }
            
            // 1. Boşluk hariç en az 6 karakter olmalı
            if nonSpaceCharacters.count < 6 || name.count < 7 {
                formatErrors.append((field: "name", message: "Adınız ve Soyadınız boşluk hariç en az 6 karakter olmalıdır"))
                highlightFieldError(textField: nameTextField)
            }
            
            // 2. İsim sadece harflerden oluşmalı
            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
            if name.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                formatErrors.append((field: "name", message: "Adınız ve Soyadınız sadece harflerden oluşmalıdır"))
                highlightFieldError(textField: nameTextField)
            }
        } else {
            emptyFields.append("Adınız - Soyadınız")
            highlightFieldError(textField: nameTextField)
        }
        
        // Kullanıcı adı kontrolü
        if let username = usernameTextField.text, username.isEmpty {
            emptyFields.append("Kullanıcı Adı")
            highlightFieldError(textField: usernameTextField)
        }
        
        // Email kontrolü
        if let email = emailTextField.text, email.isEmpty {
            emptyFields.append("Email")
            highlightFieldError(textField: emailTextField)
        } else if let email = emailTextField.text, !email.isEmpty {
            // Basit bir email formatı kontrolü
            if !email.contains("@") || !email.contains(".") {
                formatErrors.append((field: "email", message: "Geçerli bir email adresi girin"))
                highlightFieldError(textField: emailTextField)
            }
        }
        
        // Şifre kontrolü
        if let password = passwordTextField.text, password.isEmpty {
            emptyFields.append("Şifre")
            highlightFieldError(textField: passwordTextField)
        } else if let password = passwordTextField.text, !password.isEmpty {
            // Şifre en az 6 karakter olmalı
            if password.count < 6 {
                formatErrors.append((field: "password", message: "Şifre en az 6 karakter olmalıdır"))
                highlightFieldError(textField: passwordTextField)
            }
            
            // Özel karakter kontrolü
            let specialCharacterRegex = ".*[^A-Za-z0-9].*"
            let containsSpecialCharacter = password.range(of: specialCharacterRegex, options: .regularExpression) != nil
            
            if !containsSpecialCharacter {
                formatErrors.append((field: "password", message: "Şifre en az bir özel karakter içermelidir"))
                highlightFieldError(textField: passwordTextField)
            }
        }
        
        // YENİ: Şifre onay kontrolü
        if let confirmPassword = confirmPasswordTextField.text, confirmPassword.isEmpty {
            emptyFields.append("Şifre Onayı")
            highlightFieldError(textField: confirmPasswordTextField)
        } else if let password = passwordTextField.text, let confirmPassword = confirmPasswordTextField.text,
                  !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
            formatErrors.append((field: "confirmPassword", message: "Şifreler eşleşmiyor"))
            highlightFieldError(textField: confirmPasswordTextField)
        }
        
        // Yaş kontrolü
        if let age = ageTextField.text, age.isEmpty {
            emptyFields.append("Yaş")
            highlightFieldError(textField: ageTextField)
        } else if let age = ageTextField.text, !age.isEmpty {
            // Yaş sadece rakamlardan oluşmalı
            if Int(age) == nil {
                formatErrors.append((field: "age", message: "Yaş sadece rakamlardan oluşmalıdır"))
                highlightFieldError(textField: ageTextField)
            } else if age.count > 3 {
                // En fazla 3 basamaklı olabilir
                formatErrors.append((field: "age", message: "Yaş en fazla 3 basamaklı olabilir"))
                highlightFieldError(textField: ageTextField)
            } else if let ageInt = Int(age) {
                // 1-999 arasında değer olmalı
                if ageInt < 1 || ageInt > 999 {
                    formatErrors.append((field: "age", message: "Yaş 1-999 arasında olmalıdır"))
                    highlightFieldError(textField: ageTextField)
                }
            }
        }
        
        // Şehir kontrolü
        if let city = cityTextField.text, city.isEmpty {
            emptyFields.append("Şehir")
            highlightFieldError(textField: cityTextField)
        } else if let city = cityTextField.text, !city.isEmpty {
            // Şehir sadece harflerden oluşmalı
            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
            if city.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                formatErrors.append((field: "city", message: "Şehir sadece harflerden oluşmalıdır"))
                highlightFieldError(textField: cityTextField)
            }
            
            // Şehir en az 3 karakter olmalı
            if city.count < 3 {
                formatErrors.append((field: "city", message: "Şehir en az 3 karakter olmalıdır"))
                highlightFieldError(textField: cityTextField)
            }
        }
        
        // Herhangi bir hata varsa kullanıcıyı bilgilendir
        if !emptyFields.isEmpty || !formatErrors.isEmpty {
            var errorMessage = ""
            
            // Boş alan hataları varsa
            if !emptyFields.isEmpty {
                errorMessage += "Lütfen aşağıdaki alanları doldurun:\n- " + emptyFields.joined(separator: "\n- ")
            }
            
            // Format hataları varsa
            if !formatErrors.isEmpty {
                if !errorMessage.isEmpty {
                    errorMessage += "\n\n"
                }
                errorMessage += "Format hataları:\n"
                for error in formatErrors {
                    errorMessage += "- \(error.message)\n"
                }
            }
            
            hataMesaji(titleInput: "Hata", messageInput: errorMessage)
            return
        }
        
        // Yükleniyor göstergesini göster
        showLoading()
        
        // Tüm kontroller geçildiyse, kayıt işlemini yap
        guard let name = nameTextField.text,
              let username = usernameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text, // YENİ
              let ageText = ageTextField.text, let age = Int(ageText),
              let city = cityTextField.text else {
            hideLoading()
            return
        }
        
        // Cinsiyet değerini al
        let genderOptions = ["Erkek", "Kadın", "Diğer"]
        let gender = genderOptions[genderSegmentedControl.selectedSegmentIndex]
        
        // ViewModel kullanarak kayıt işlemini yap
        viewModel.registerUser(name: name, username: username, email: email, password: password, confirmPassword: confirmPassword, age: age, city: city, gender: gender)
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
