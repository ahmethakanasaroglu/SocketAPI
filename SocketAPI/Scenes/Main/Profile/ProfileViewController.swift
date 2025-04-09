import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let themeSwitchButton = ThemeSwitchButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    // Cinsiyet seçimi için picker
    private let genderPicker = UIPickerView()
    private let genderOptions = ["Erkek", "Kadın", "Diğer"]
    
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
        view.isUserInteractionEnabled = true // Etkileşim izni
        return view
    }()
    
    // Profile image loading indicator
    private let imageLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
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
        textField.placeholder = "İsim - Soyisim"
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
    
    // Profil fotoğrafı için değişken
    private var hasProfileImageChanged = false
    private var selectedProfileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupGenderPicker()
        setupProfileImageTapGesture()
        fetchUserData()
        setupRightBarButton()
        
        // Ekranı kapatma işlemi için klavye
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupProfileImageTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func profileImageTapped() {
        let actionSheet = UIAlertController(title: "Profil Fotoğrafı", message: "Seçiminizi yapın", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Galeriden Seç", style: .default, handler: { [weak self] _ in
            self?.showImagePicker(sourceType: .photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Fotoğraf Çek", style: .default, handler: { [weak self] _ in
            self?.showImagePicker(sourceType: .camera)
        }))
        
        // Kullanıcının zaten profil fotoğrafı varsa silme seçeneği
        if profileImageView.image != nil && profileImageView.image != UIImage(systemName: "person.circle.fill") {
            actionSheet.addAction(UIAlertAction(title: "Fotoğrafı Kaldır", style: .destructive, handler: { [weak self] _ in
                self?.removeProfileImage()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            imagePickerController.allowsEditing = true
            present(imagePickerController, animated: true)
        } else {
            hataMesaji(titleInput: "Hata", messageInput: sourceType == .camera ? "Kamera kullanılamıyor." : "Fotograf galerisi kullanılamıyor.")
        }
    }
    
    // UIImagePickerController delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            selectedProfileImage = editedImage
            profileImageView.image = editedImage
            hasProfileImageChanged = true
            updateSaveButtonState(isEnabled: true)
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedProfileImage = originalImage
            profileImageView.image = originalImage
            hasProfileImageChanged = true
            updateSaveButtonState(isEnabled: true)
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    private func removeProfileImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        selectedProfileImage = nil
        hasProfileImageChanged = true
        updateSaveButtonState(isEnabled: true)
    }
    
    private func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        
        // Cinsiyet seçici araç çubuğu oluştur
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Tamam butonu
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(genderPickerDoneTapped))
        // İptal butonu
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(genderPickerCancelTapped))
        // Ara boşluk
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([cancelButton, flexSpace, doneButton], animated: true)
        
        // Cinsiyet alanına picker'ı tanımla
        genderTextField.inputView = genderPicker
        genderTextField.inputAccessoryView = toolbar
    }
    
    @objc private func genderPickerDoneTapped() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = genderOptions[selectedRow]
        genderTextField.resignFirstResponder()
    }
    
    @objc private func genderPickerCancelTapped() {
        // Değişiklik yapmadan kapat
        genderTextField.resignFirstResponder()
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
        contentView.addSubview(imageLoadingIndicator)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            imageLoadingIndicator.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
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
        let nameField = createFieldGroup(label: "İsim - Soyisim:", textField: nameTextField, button: changeNameButton)
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
        
        imageLoadingIndicator.startAnimating()
        
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                self.imageLoadingIndicator.stopAnimating()
                return
            }
            
            guard let data = snapshot?.data() else {
                self.imageLoadingIndicator.stopAnimating()
                return
            }
            
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
            
            // Eğer gender değeri varsa, picker'ı ona göre ayarla
            if let index = self.genderOptions.firstIndex(of: gender) {
                self.genderPicker.selectRow(index, inComponent: 0, animated: false)
            }
            
            self.emailLabel.text = user.email
            self.uidLabel.text = user.uid
            
            // Orijinal değerleri sakla
            self.originalValues["name"] = name
            self.originalValues["username"] = username
            self.originalValues["age"] = age != nil ? "\(age!)" : ""
            self.originalValues["city"] = city
            self.originalValues["gender"] = gender
            
            // Profil fotoğrafını yükle
            self.loadProfileImage(userId: user.uid)
        }
    }
    
    private func loadProfileImage(userId: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        profileImageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            guard let self = self else { return }
            
            self.imageLoadingIndicator.stopAnimating()
            
            if let error = error {
                print("Profil fotoğrafı yükleme hatası: \(error.localizedDescription)")
                // Varsayılan profil ikonu göster
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                self.profileImageView.tintColor = .systemBlue
                return
            }
            
            if let imageData = data, let image = UIImage(data: imageData) {
                self.profileImageView.image = image
                self.profileImageView.tintColor = .clear
            } else {
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                self.profileImageView.tintColor = .systemBlue
            }
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
        let isEditing = !editingFields["gender", default: false]
        
        // Eğer değiştirme iptal ediliyorsa, değeri orijinal değere geri al
        if !isEditing && editingFields["gender", default: false] {
            genderTextField.text = originalValues["gender"]
        }
        
        editingFields["gender"] = isEditing
        
        changeGenderButton.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            // Cinsiyet için UIPickerView'u göster
            showGenderPicker()
        }
        
        // Herhangi bir alan düzenleme durumunda ise kaydet butonunu aktif et
        let anyFieldEditing = editingFields.values.contains(true)
        updateSaveButtonState(isEnabled: anyFieldEditing || hasProfileImageChanged)
    }
    
    private func showGenderPicker() {
        // Sadece picker görünecek, manuel yazım olmayacak
        let actionSheet = UIAlertController(title: "Cinsiyet Seçiniz", message: nil, preferredStyle: .actionSheet)
        
        for option in genderOptions {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.genderTextField.text = option
            }
            actionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            
            // İptal edildiğinde, eğer metin boşsa orijinal değere dön
            if self.genderTextField.text?.isEmpty ?? true {
                self.genderTextField.text = self.originalValues["gender"]
            }
        }
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
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
                updateSaveButtonState(isEnabled: anyFieldEditing || hasProfileImageChanged)
            }
            
            // Aktif olmadığında butonun rengini soluklaştıran özellik
            func updateSaveButtonState(isEnabled: Bool) {
                saveButton.isEnabled = isEnabled
                saveButton.alpha = isEnabled ? 1.0 : 0.5 // Eğer buton aktifse tam renk, değilse daha soluk
            }
            
            // saveTapped metodunda şehir validasyonu ekleyelim
            @objc private func saveTapped() {
                // Validasyon kontrolleri
                var validationErrors: [String] = []
                
                // İsim-soyisim validasyonu
                if editingFields["name", default: false] {
                    if let name = nameTextField.text {
                        if name.isEmpty {
                            validationErrors.append("İsim-Soyisim alanı boş bırakılamaz.")
                        } else {
                            // Sadece harflerden ve boşluklardan oluşmalı
                            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
                            if name.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                                validationErrors.append("İsim-Soyisim sadece harflerden oluşmalıdır.")
                            }
                            
                            // Boşluk dahil en az 7 karakter olmalı
                            if name.count < 7 {
                                validationErrors.append("İsim-Soyisim boşluk dahil en az 7 karakter olmalıdır.")
                            }
                            
                            // Boşluk hariç en az 6 karakter kontrolü
                            let nonSpaceCharacters = name.filter { !$0.isWhitespace }
                            if nonSpaceCharacters.count < 6 {
                                validationErrors.append("İsim-Soyisim boşluk hariç en az 6 karakter olmalıdır.")
                            }
                        }
                    }
                }
                
                // Yaş validasyonu
                if editingFields["age", default: false] {
                    if let ageText = ageTextField.text {
                        if ageText.isEmpty {
                            validationErrors.append("Yaş alanı boş bırakılamaz.")
                        } else {
                            // Sadece rakamlardan oluşmalı
                            if !ageText.allSatisfy({ $0.isNumber }) {
                                validationErrors.append("Yaş sadece rakamlardan oluşmalıdır.")
                            } else if ageText.count > 3 {
                                validationErrors.append("Yaş en fazla 3 basamaklı olabilir.")
                            } else if let age = Int(ageText), age < 1 {
                                validationErrors.append("Yaş 0'dan büyük olmalıdır.")
                            }
                        }
                    }
                }
                
                // Şehir validasyonu
                if editingFields["city", default: false] {
                    if let city = cityTextField.text {
                        if city.isEmpty {
                            validationErrors.append("Şehir alanı boş bırakılamaz.")
                        } else {
                            // Sadece harflerden ve boşluklardan oluşmalı
                            let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
                            if city.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                                validationErrors.append("Şehir sadece harflerden oluşmalıdır.")
                            }
                            
                            // En az 3 karakter olmalı
                            if city.count < 3 {
                                validationErrors.append("Şehir en az 3 karakter olmalıdır.")
                            }
                        }
                    }
                }
                
                // Validasyon hataları varsa, kullanıcıya göster ve işlemi durdur
                if !validationErrors.isEmpty {
                    let errorMessage = validationErrors.joined(separator: "\n")
                    hataMesaji(titleInput: "Hata", messageInput: errorMessage)
                    return
                }
                
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
                // Profil fotoğrafı değişimi veya text değişimi varsa güncelleme yap
                let hasTextChanges = !updatedData.isEmpty
                
                // Eğer hiçbir değişiklik yoksa ve profil fotoğrafı da değişmediyse işlemi sonlandır
                if !hasTextChanges && !hasProfileImageChanged {
                    updateEditingState(false)
                    return
                }
                
                // Yükleme göstergesini başlat
                if hasProfileImageChanged {
                    imageLoadingIndicator.startAnimating()
                }
                
                // Önce profil fotoğrafını kaydet, sonra diğer verileri güncelle
                if hasProfileImageChanged {
                    saveProfileImage(userId: user.uid) { [weak self] success in
                        guard let self = self else { return }
                        
                        if success && hasTextChanges {
                            // Profil fotoğrafı başarıyla kaydedildiyse ve metin değişiklikleri varsa, metinleri de güncelle
                            self.updateProfileData(userId: user.uid, db: db, updatedData: updatedData)
                        } else if success {
                            // Sadece profil fotoğrafı değiştiyse ve başarıyla kaydedildiyse
                            DispatchQueue.main.async {
                                self.imageLoadingIndicator.stopAnimating()
                                self.hasProfileImageChanged = false
                                self.updateEditingState(false)
                                self.hataMesaji(titleInput: "✅ Başarılı", messageInput: "Profil fotoğrafınız başarıyla güncellendi.")
                            }
                        } else {
                            // Profil fotoğrafı kaydedilemezse hata göster
                            DispatchQueue.main.async {
                                self.imageLoadingIndicator.stopAnimating()
                                self.hataMesaji(titleInput: "Hata", messageInput: "Profil fotoğrafı güncellenirken bir hata oluştu.")
                            }
                        }
                    }
                } else if hasTextChanges {
                    // Sadece metin değişiklikleri varsa onları güncelle
                    updateProfileData(userId: user.uid, db: db, updatedData: updatedData)
                }
            }
            
            private func saveProfileImage(userId: String, completion: @escaping (Bool) -> Void) {
                let storage = Storage.storage()
                let storageRef = storage.reference()
                let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
                
                // Eğer profil fotoğrafı kaldırıldıysa
                if selectedProfileImage == nil {
                    profileImageRef.delete { error in
                        if let error = error {
                            print("Profil fotoğrafı silinemedi: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                    return
                }
                
                // Yeni bir profil fotoğrafı yükleniyorsa
                guard let image = selectedProfileImage, let imageData = image.jpegData(compressionQuality: 0.7) else {
                    completion(false)
                    return
                }
                
                // Resmi Firebase'e yükle
                let uploadTask = profileImageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("Profil fotoğrafı yüklenemedi: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    // Başarıyla yüklendi
                    completion(true)
                }
            }
            
            private func updateProfileData(userId: String, db: Firestore, updatedData: [String: Any]) {
                // Firestore'da güncelle
                db.collection("users").document(userId).updateData(updatedData) { [weak self] error in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.imageLoadingIndicator.stopAnimating()
                        
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
                            
                            self.hasProfileImageChanged = false
                            self.updateEditingState(false)
                            
                            // Başarılı güncelleme mesajı göster
                            self.hataMesaji(titleInput: "✅ Başarılı", messageInput: "Profil bilgileriniz başarıyla güncellendi.")
                        }
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
            
            // MARK: - UIPickerView Delegate & DataSource Methods
            func numberOfComponents(in pickerView: UIPickerView) -> Int {
                return 1
            }
            
            func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
                return genderOptions.count
            }
            
            func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
                return genderOptions[row]
            }
        }
