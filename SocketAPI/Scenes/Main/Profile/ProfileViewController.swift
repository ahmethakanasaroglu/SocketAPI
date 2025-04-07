import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    private let themeSwitchButton = ThemeSwitchButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    // Orijinal değerleri saklayacak değişkenler
    private var originalValues: [String: String] = [
        "name": "",
        "username": "",
        "age": "",
        "city": "",
        "gender": ""
    ]
    
    // Scrollview
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    // Content View for ScrollView
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let profileImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 50
        view.clipsToBounds = true
        view.backgroundColor = .systemGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = UIImage(systemName: "person.circle.fill")
        view.tintColor = .systemBlue
        return view
    }()
    
    // MARK: - UI Components for Profile Fields
    
    // Name
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .label
        textField.textAlignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false
        textField.placeholder = "İsim"
        return textField
    }()
    
    private let changeNameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeNameTapped), for: .touchUpInside)
        return button
    }()
    
    // Username
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .label
        textField.textAlignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false
        textField.placeholder = "Kullanıcı Adı"
        return textField
    }()
    
    private let changeUsernameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeUsernameTapped), for: .touchUpInside)
        return button
    }()
    
    // Age
    private let ageTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .label
        textField.textAlignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false
        textField.placeholder = "Yaş"
        textField.keyboardType = .numberPad
        return textField
    }()
    
    private let changeAgeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeAgeTapped), for: .touchUpInside)
        return button
    }()
    
    // City
    private let cityTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .label
        textField.textAlignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false
        textField.placeholder = "Şehir"
        return textField
    }()
    
    private let changeCityButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeCityTapped), for: .touchUpInside)
        return button
    }()
    
    // Gender
    private let genderTextField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .label
        textField.textAlignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = false
        textField.placeholder = "Cinsiyet"
        return textField
    }()
    
    private let changeGenderButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Değiştir", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(changeGenderTapped), for: .touchUpInside)
        return button
    }()
    
    // Email Alanı
    private let emailInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "Email:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // UID Alanı
    private let uidInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "UID:"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let uidLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.textAlignment = .left
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
    
    // Track which fields are being edited
    private var editingFields: [String: Bool] = [
        "name": false,
        "username": false,
        "age": false,
        "city": false,
        "gender": false
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        fetchUserData()
        setupRightBarButton()
        
        // Ekranı kapatma işlemi için klavye
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupRightBarButton() {
        let rightBarButton = UIBarButtonItem(customView: themeSwitchButton)
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    private func setupUI() {
        navigationItem.title = "Profil"
        
        // ScrollView'u view'a ekle
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // ScrollView ve ContentView'in constraint'lerini ayarla
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Profil resmi üst kısma yerleştir
        contentView.addSubview(profileImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Alan düzenleri için container view
        let fieldsContainer = UIView()
        fieldsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fieldsContainer)
        
        NSLayoutConstraint.activate([
            fieldsContainer.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
            fieldsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fieldsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Her alan için bir görünüm oluştur
        let nameField = createFieldGroup(label: "İsim:", textField: nameTextField, button: changeNameButton)
        let usernameField = createFieldGroup(label: "Kullanıcı Adı:", textField: usernameTextField, button: changeUsernameButton)
        let ageField = createFieldGroup(label: "Yaş:", textField: ageTextField, button: changeAgeButton)
        let cityField = createFieldGroup(label: "Şehir:", textField: cityTextField, button: changeCityButton)
        let genderField = createFieldGroup(label: "Cinsiyet:", textField: genderTextField, button: changeGenderButton)
        
        // Email ve UID alanları
        let emailContainer = UIView()
        emailContainer.translatesAutoresizingMaskIntoConstraints = false
        
        emailContainer.addSubview(emailInfoLabel)
        emailContainer.addSubview(emailLabel)
        
        NSLayoutConstraint.activate([
            emailInfoLabel.topAnchor.constraint(equalTo: emailContainer.topAnchor),
            emailInfoLabel.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor),
            emailInfoLabel.bottomAnchor.constraint(equalTo: emailContainer.bottomAnchor),
            
            emailLabel.leadingAnchor.constraint(equalTo: emailInfoLabel.trailingAnchor, constant: 8),
            emailLabel.centerYAnchor.constraint(equalTo: emailInfoLabel.centerYAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor)
        ])
        
        let uidContainer = UIView()
        uidContainer.translatesAutoresizingMaskIntoConstraints = false
        
        uidContainer.addSubview(uidInfoLabel)
        uidContainer.addSubview(uidLabel)
        
        NSLayoutConstraint.activate([
            uidInfoLabel.topAnchor.constraint(equalTo: uidContainer.topAnchor),
            uidInfoLabel.leadingAnchor.constraint(equalTo: uidContainer.leadingAnchor),
            uidInfoLabel.bottomAnchor.constraint(equalTo: uidContainer.bottomAnchor),
            
            uidLabel.leadingAnchor.constraint(equalTo: uidInfoLabel.trailingAnchor, constant: 8),
            uidLabel.centerYAnchor.constraint(equalTo: uidInfoLabel.centerYAnchor),
            uidLabel.trailingAnchor.constraint(equalTo: uidContainer.trailingAnchor)
        ])
        
        // Veri alanlarını bir stack view'a koy
        let fieldsStackView = UIStackView(arrangedSubviews: [
            nameField, usernameField, ageField, cityField, genderField, emailContainer, uidContainer
        ])
        
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = 20
        fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        fieldsContainer.addSubview(fieldsStackView)
        
        NSLayoutConstraint.activate([
            fieldsStackView.topAnchor.constraint(equalTo: fieldsContainer.topAnchor),
            fieldsStackView.leadingAnchor.constraint(equalTo: fieldsContainer.leadingAnchor),
            fieldsStackView.trailingAnchor.constraint(equalTo: fieldsContainer.trailingAnchor),
            fieldsStackView.bottomAnchor.constraint(equalTo: fieldsContainer.bottomAnchor)
        ])
        
        // Butonları contentView'a ekle
        contentView.addSubview(saveButton)
        contentView.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: fieldsContainer.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            logoutButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createFieldGroup(label: String, textField: UITextField, button: UIButton) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelView)
        container.addSubview(textField)
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 100),
            
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            button.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        return container
    }
    
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            // Tüm alanları doldur
            let name = data["name"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            let age = data["age"] as? Int
            let city = data["city"] as? String ?? ""
            let gender = data["gender"] as? String ?? ""
            
            self.nameTextField.text = name
            self.usernameTextField.text = username
            
            if let age = age {
                self.ageTextField.text = "\(age)"
            }
            
            self.cityTextField.text = city
            self.genderTextField.text = gender
            self.emailLabel.text = user.email
            self.uidLabel.text = user.uid
            
            // Orijinal değerleri sakla
            self.originalValues["name"] = name
            self.originalValues["username"] = username
            self.originalValues["age"] = age != nil ? "\(age!)" : ""
            self.originalValues["city"] = city
            self.originalValues["gender"] = gender
        }
    }
    
    // Butonlara göre ilgili alan düzenleme durumunu değiştir
    @objc private func changeNameTapped() {
        toggleFieldEditing(field: "name", textField: nameTextField, button: changeNameButton)
    }
    
    @objc private func changeUsernameTapped() {
        toggleFieldEditing(field: "username", textField: usernameTextField, button: changeUsernameButton)
    }
    
    @objc private func changeAgeTapped() {
        toggleFieldEditing(field: "age", textField: ageTextField, button: changeAgeButton)
    }
    
    @objc private func changeCityTapped() {
        toggleFieldEditing(field: "city", textField: cityTextField, button: changeCityButton)
    }
    
    @objc private func changeGenderTapped() {
        toggleFieldEditing(field: "gender", textField: genderTextField, button: changeGenderButton)
    }
    
    private func toggleFieldEditing(field: String, textField: UITextField, button: UIButton) {
        let isEditing = !editingFields[field, default: false]
        
        // Eğer değiştirme iptal ediliyorsa, değeri orijinal değere geri al
        if !isEditing && editingFields[field, default: false] {
            textField.text = originalValues[field]
        }
        
        editingFields[field] = isEditing
        
        textField.isUserInteractionEnabled = isEditing
        button.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            textField.becomeFirstResponder()
        }
        
        // Herhangi bir alan düzenleme durumunda ise kaydet butonunu aktif et
        let anyFieldEditing = editingFields.values.contains(true)
        updateSaveButtonState(isEnabled: anyFieldEditing)
    }
    
    // Aktif olmadığında butonun rengini soluklaştıran özellik
    func updateSaveButtonState(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5 // Eğer buton aktifse tam renk, değilse daha soluk
    }
    
    @objc private func saveTapped() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        // Tüm değişiklikleri bir sözlükte topla
        var updatedData: [String: Any] = [:]
        
        if editingFields["name", default: false] {
            updatedData["name"] = nameTextField.text ?? ""
        }
        
        if editingFields["username", default: false] {
            // Username değişikliği için önce benzersizlik kontrolü yap
            let username = usernameTextField.text ?? ""
            updatedData["username"] = username
            
            checkUsernameUniqueness(username: username) { [weak self] isUnique in
                guard let self = self else { return }
                
                if !isUnique {
                    // Eğer benzersiz değilse hata göster
                    DispatchQueue.main.async {
                        self.hataMesaji(titleInput: "Hata", messageInput: "Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir kullanıcı adı seçin.")
                        // Kullanıcı adını orijinal değere geri döndür
                        self.usernameTextField.text = self.originalValues["username"]
                    }
                    return
                }
                
                // Username benzersizse devam et
                self.continueWithSaving(user: user, db: db, updatedData: updatedData)
            }
            return // Username kontrolü yapılıyorsa, asenkron işlem için burada dur
        }
        
        if editingFields["age", default: false] {
            if let ageText = ageTextField.text, let age = Int(ageText) {
                updatedData["age"] = age
            } else {
                hataMesaji(titleInput: "Geçersiz Yaş", messageInput: "Lütfen yaş için geçerli bir sayı girin.")
                ageTextField.text = originalValues["age"] // Geçersiz değeri eski haline getir
                return
            }
        }
        
        if editingFields["city", default: false] {
            updatedData["city"] = cityTextField.text ?? ""
        }
        
        if editingFields["gender", default: false] {
            updatedData["gender"] = genderTextField.text ?? ""
        }
        
        // Username değişikliği yoksa direkt kaydet
        continueWithSaving(user: user, db: db, updatedData: updatedData)
    }
    
    private func checkUsernameUniqueness(username: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(true) // Hata durumunda veya döküman yoksa benzersiz kabul et
                return
            }
            
            // Mevcut kullanıcının dışında aynı username'e sahip başka kullanıcı var mı?
            let isUnique = documents.allSatisfy { $0.documentID == currentUser.uid }
            completion(isUnique)
        }
    }
    
    private func continueWithSaving(user: FirebaseAuth.User, db: Firestore, updatedData: [String: Any]) {
        if updatedData.isEmpty {
            updateEditingState(false)
            return
        }
        
        // Firestore'da güncelle
        db.collection("users").document(user.uid).updateData(updatedData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Güncelleme hatası: \(error.localizedDescription)")
                self.hataMesaji(titleInput: "Hata", messageInput: "Bilgileriniz güncellenirken bir hata oluştu.")
                
                // Hata durumunda değerleri eski haline getir
                self.resetFieldsToOriginalValues()
            } else {
                print("Profil başarıyla güncellendi!")
                
                // Başarılı güncelleme durumunda orijinal değerleri güncelle
                if let nameText = self.nameTextField.text {
                    self.originalValues["name"] = nameText
                }
                
                if let usernameText = self.usernameTextField.text {
                    self.originalValues["username"] = usernameText
                }
                
                if let ageText = self.ageTextField.text {
                    self.originalValues["age"] = ageText
                }
                
                if let cityText = self.cityTextField.text {
                    self.originalValues["city"] = cityText
                }
                
                if let genderText = self.genderTextField.text {
                    self.originalValues["gender"] = genderText
                }
                
                self.updateEditingState(false)
                
                // Başarılı güncelleme mesajı göster
                self.hataMesaji(titleInput: "Başarılı", messageInput: "Profil bilgileriniz başarıyla güncellendi.")
            }
        }
    }
    
    private func resetFieldsToOriginalValues() {
        nameTextField.text = originalValues["name"]
        usernameTextField.text = originalValues["username"]
        ageTextField.text = originalValues["age"]
        cityTextField.text = originalValues["city"]
        genderTextField.text = originalValues["gender"]
    }
    
    private func updateEditingState(_ isEditing: Bool) {
        // Tüm alanları düzenleme dışına çıkar
        for (field, _) in editingFields {
            editingFields[field] = isEditing
        }
        
        // UI'ı güncelle
        nameTextField.isUserInteractionEnabled = isEditing
        usernameTextField.isUserInteractionEnabled = isEditing
        ageTextField.isUserInteractionEnabled = isEditing
        cityTextField.isUserInteractionEnabled = isEditing
        genderTextField.isUserInteractionEnabled = isEditing
        
        changeNameButton.setTitle("Değiştir", for: .normal)
        changeUsernameButton.setTitle("Değiştir", for: .normal)
        changeAgeButton.setTitle("Değiştir", for: .normal)
        changeCityButton.setTitle("Değiştir", for: .normal)
        changeGenderButton.setTitle("Değiştir", for: .normal)
        
        updateSaveButtonState(isEnabled: isEditing)
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
    
    private func hataMesaji(titleInput: String, messageInput: String) {
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
