import UIKit
import AVFoundation
import FirebaseAuth

class ProfileViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private let viewModel = ProfileViewModel()
    private let themeSwitchButton = ThemeSwitchButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    // Cinsiyet seçimi için picker
    private let genderPicker = UIPickerView()
    
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
    
    // MARK: - Life Cycle Methods
    
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
    
    // MARK: - Setup Methods
    
    private func setupProfileImageTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
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
    
    private func setupRightBarButton() {
        let rightBarButton = UIBarButtonItem(customView: themeSwitchButton)
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    private func setupUI() {
            navigationItem.title = "Profil"

            view.addSubview(scrollView)
            scrollView.addSubview(contentView)

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

            let fieldsContainer = UIView()
            fieldsContainer.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(fieldsContainer)

            NSLayoutConstraint.activate([
                fieldsContainer.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
                fieldsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                fieldsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])

            let nameField = createFieldGroup(label: "İsim - Soyisim:", textField: nameTextField, button: changeNameButton)
            let usernameField = createFieldGroup(label: "Kullanıcı Adı:", textField: usernameTextField, button: changeUsernameButton)
            let ageField = createFieldGroup(label: "Yaş:", textField: ageTextField, button: changeAgeButton)
            let cityField = createFieldGroup(label: "Şehir:", textField: cityTextField, button: changeCityButton)
            let genderField = createFieldGroup(label: "Cinsiyet:", textField: genderTextField, button: changeGenderButton)

            let emailContainer = createInfoRow(titleLabel: emailInfoLabel, valueLabel: emailLabel)
            let uidContainer = createInfoRow(titleLabel: uidInfoLabel, valueLabel: uidLabel)

            let fieldsStackView = UIStackView(arrangedSubviews: [
                nameField, usernameField, ageField, cityField, genderField, emailContainer, uidContainer
            ])

            fieldsStackView.axis = .vertical
            fieldsStackView.spacing = 24
            fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
            fieldsContainer.addSubview(fieldsStackView)

            NSLayoutConstraint.activate([
                fieldsStackView.topAnchor.constraint(equalTo: fieldsContainer.topAnchor),
                fieldsStackView.leadingAnchor.constraint(equalTo: fieldsContainer.leadingAnchor),
                fieldsStackView.trailingAnchor.constraint(equalTo: fieldsContainer.trailingAnchor),
                fieldsStackView.bottomAnchor.constraint(equalTo: fieldsContainer.bottomAnchor)
            ])

            contentView.addSubview(saveButton)
            contentView.addSubview(logoutButton)

            NSLayoutConstraint.activate([
                saveButton.topAnchor.constraint(equalTo: fieldsContainer.bottomAnchor, constant: 40),
                saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                saveButton.heightAnchor.constraint(equalToConstant: 54),

                logoutButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
                logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                logoutButton.heightAnchor.constraint(equalToConstant: 54),
                logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
            ])
        }
    
    private func createInfoRow(titleLabel: UILabel, valueLabel: UILabel) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = UIColor.secondarySystemGroupedBackground
            container.layer.cornerRadius = 12
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.05
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4

            container.addSubview(titleLabel)
            container.addSubview(valueLabel)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

                valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
            ])

            return container
        }
    
    private func createFieldGroup(label: String, textField: UITextField, button: UIButton) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = UIColor.secondarySystemGroupedBackground
            container.layer.cornerRadius = 12
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.05
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4

            let labelView = UILabel()
            labelView.text = label
            labelView.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            labelView.textColor = .secondaryLabel
            labelView.translatesAutoresizingMaskIntoConstraints = false

            textField.layer.cornerRadius = 10
            textField.layer.borderWidth = 0.8
            textField.layer.borderColor = UIColor.systemGray4.cgColor
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 40))
            textField.leftViewMode = .always

            container.addSubview(labelView)
            container.addSubview(textField)
            container.addSubview(button)

            NSLayoutConstraint.activate([
                labelView.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                labelView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

                textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
                textField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                textField.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
                textField.heightAnchor.constraint(equalToConstant: 40),

                button.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                button.widthAnchor.constraint(equalToConstant: 70),

                textField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
            ])

            return container
        }
    
    // MARK: - Data Methods
    
    private func fetchUserData() {
        imageLoadingIndicator.startAnimating()
        
        viewModel.fetchUserData { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // UI'ı güncelle
                self.updateUIWithUserData()
                
                // Profil fotoğrafını yükle
                if let userId = Auth.auth().currentUser?.uid {
                    self.loadProfileImage(userId: userId)
                } else {
                    self.imageLoadingIndicator.stopAnimating()
                }
            } else {
                self.imageLoadingIndicator.stopAnimating()
                self.hataMesaji(titleInput: "Hata", messageInput: "Kullanıcı bilgileri yüklenemedi.")
            }
        }
    }
    
    private func updateUIWithUserData() {
        nameTextField.text = viewModel.name
        usernameTextField.text = viewModel.username
        
        if let age = viewModel.age {
            ageTextField.text = "\(age)"
        } else {
            ageTextField.text = ""
        }
        
        cityTextField.text = viewModel.city
        genderTextField.text = viewModel.gender
        
        // Eğer gender değeri varsa, picker'ı ona göre ayarla
        if let index = viewModel.genderOptions.firstIndex(of: viewModel.gender) {
            genderPicker.selectRow(index, inComponent: 0, animated: false)
        }
        
        emailLabel.text = viewModel.email
        uidLabel.text = viewModel.uid
    }
    
    private func loadProfileImage(userId: String) {
        viewModel.loadProfileImage(userId: userId) { [weak self] image in
            guard let self = self else { return }
            
            self.imageLoadingIndicator.stopAnimating()
            
            if let image = image {
                self.profileImageView.image = image
                self.profileImageView.tintColor = .clear
            } else {
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                self.profileImageView.tintColor = .systemBlue
            }
        }
    }
    
    // MARK: - Action Methods
    
    @objc private func profileImageTapped() {
        let actionSheet = UIAlertController(title: "Profil Fotoğrafı", message: "Seçiminizi yapın", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Galeriden Seç", style: .default, handler: { [weak self] _ in
            self?.showImagePicker(sourceType: .photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Fotoğraf Çek", style: .default, handler: { [weak self] _ in
            self?.showImagePicker(sourceType: .camera)
        }))
        
        // Kullanıcının zaten gerçek bir profil fotoğrafı varsa silme seçeneğini ekle
        // Varsayılan kişi simgesini kontrol et - tintColor kontrolü ile daha güvenilir
        if profileImageView.tintColor == .clear {
            actionSheet.addAction(UIAlertAction(title: "Fotoğrafı Kaldır", style: .destructive, handler: { [weak self] _ in
                self?.removeProfileImage()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        // Önce kamera kullanılabilirliğini kontrol et
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            hataMesaji(titleInput: "Hata", messageInput: "Kamera kullanılamıyor.")
            return
        }
        
        // Fotoğraf galerisi kullanılabilirliğini kontrol et
        if sourceType == .photoLibrary && !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            hataMesaji(titleInput: "Hata", messageInput: "Fotograf galerisi kullanılamıyor.")
            return
        }
        
        // Kamera izni kontrolü
        if sourceType == .camera {
            let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch cameraAuthStatus {
            case .notDetermined:
                // Kullanıcıdan izin iste
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.presentImagePicker(sourceType: sourceType)
                        } else {
                            self?.hataMesaji(titleInput: "İzin Hatası", messageInput: "Kamera erişim izni verilmedi.")
                        }
                    }
                }
                return
                
            case .restricted, .denied:
                // Kullanıcıya ayarlara gitmesini söyle
                hataMesaji(titleInput: "İzin Hatası", messageInput: "Kamera erişim izni verilmedi. Ayarlara giderek izin vermeniz gerekiyor.")
                return
                
            case .authorized:
                // İzin verilmiş, devam et
                break
                
            @unknown default:
                break
            }
        }
        
        presentImagePicker(sourceType: sourceType)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true)
    }
    
    private func removeProfileImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        viewModel.selectedProfileImage = nil
        viewModel.hasProfileImageChanged = true
        updateSaveButtonState(isEnabled: true)
    }
    
    @objc private func genderPickerDoneTapped() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = viewModel.genderOptions[selectedRow]
        viewModel.gender = viewModel.genderOptions[selectedRow]
        genderTextField.resignFirstResponder()
    }
    
    @objc private func genderPickerCancelTapped() {
        // Değişiklik yapmadan kapat
        genderTextField.resignFirstResponder()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
        let isEditing = !viewModel.editingFields["gender", default: false]
        
        // Eğer değiştirme iptal ediliyorsa, değeri orijinal değere geri al
        if !isEditing && viewModel.editingFields["gender", default: false] {
            genderTextField.text = viewModel.originalValues["gender"]
            viewModel.gender = viewModel.originalValues["gender"] ?? ""
        }
        
        viewModel.editingFields["gender"] = isEditing
        
        changeGenderButton.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            // Cinsiyet için UIPickerView'u göster
            showGenderPicker()
        }
        
        // Herhangi bir alan düzenleme durumunda ise kaydet butonunu aktif et
        updateSaveButtonState(isEnabled: viewModel.isAnyFieldEditing())
    }
    
    private func showGenderPicker() {
        // Sadece picker görünecek, manuel yazım olmayacak
        let actionSheet = UIAlertController(title: "Cinsiyet Seçiniz", message: nil, preferredStyle: .actionSheet)
        
        for option in viewModel.genderOptions {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.genderTextField.text = option
                self.viewModel.gender = option
            }
            actionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel) { [weak self] _ in
            guard let self = self else { return }
            
            // İptal edildiğinde, eğer metin boşsa orijinal değere dön
            if self.genderTextField.text?.isEmpty ?? true {
                self.genderTextField.text = self.viewModel.originalValues["gender"]
                self.viewModel.gender = self.viewModel.originalValues["gender"] ?? ""
            }
        }
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func toggleFieldEditing(field: String, textField: UITextField, button: UIButton) {
        let isEditing = !viewModel.editingFields[field, default: false]
        
        // Eğer değiştirme iptal ediliyorsa, değeri orijinal değere geri al
        if !isEditing && viewModel.editingFields[field, default: false] {
            textField.text = viewModel.originalValues[field]
            
            // ViewModel'deki ilgili değeri güncelle
            switch field {
            case "name":
                viewModel.name = viewModel.originalValues[field] ?? ""
            case "username":
                viewModel.username = viewModel.originalValues[field] ?? ""
            case "age":
                if let ageStr = viewModel.originalValues[field], let age = Int(ageStr) {
                    viewModel.age = age
                } else {
                    viewModel.age = nil
                }
            case "city":
                viewModel.city = viewModel.originalValues[field] ?? ""
            case "gender":
                viewModel.gender = viewModel.originalValues[field] ?? ""
            default:
                break
            }
        }
        
        viewModel.editingFields[field] = isEditing
        
        textField.isUserInteractionEnabled = isEditing
        button.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            textField.becomeFirstResponder()
        }
        
        // Herhangi bir alan düzenleme durumunda ise kaydet butonunu aktif et
        updateSaveButtonState(isEnabled: viewModel.isAnyFieldEditing())
    }
    
    // Aktif olmadığında butonun rengini soluklaştıran özellik
    private func updateSaveButtonState(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5 // Eğer buton aktifse tam renk, değilse daha soluk
    }
    
    @objc private func saveTapped() {
        // TextField'lardaki değerleri ViewModel'e aktar
        if viewModel.editingFields["name", default: false] {
            viewModel.name = nameTextField.text ?? ""
        }
        
        if viewModel.editingFields["username", default: false] {
            viewModel.username = usernameTextField.text ?? ""
        }
        
        if viewModel.editingFields["age", default: false] {
            if let ageText = ageTextField.text, let age = Int(ageText) {
                viewModel.age = age
            } else {
                viewModel.age = nil
            }
        }
        
        if viewModel.editingFields["city", default: false] {
            viewModel.city = cityTextField.text ?? ""
        }
        
        // Validasyon kontrolleri
        let validationErrors = viewModel.validateFields()
        
        // Validasyon hataları varsa, kullanıcıya göster ve işlemi durdur
        if !validationErrors.isEmpty {
            let errorMessage = validationErrors.joined(separator: "\n")
            hataMesaji(titleInput: "Hata", messageInput: errorMessage)
            return
        }
        
        guard let user = Auth.auth().currentUser else { return }
        
        // Tüm değişiklikleri bir sözlükte topla
        let updatedData = viewModel.collectUpdatedData()
        
        // Username değişikliği için önce benzersizlik kontrolü yap
        if viewModel.editingFields["username", default: false] {
            viewModel.checkUsernameUniqueness(username: viewModel.username) { [weak self] isUnique in
                guard let self = self else { return }
                
                if !isUnique {
                    // Eğer benzersiz değilse hata göster
                    DispatchQueue.main.async {
                        self.hataMesaji(titleInput: "Hata", messageInput: "Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir kullanıcı adı seçin.")
                        // Kullanıcı adını orijinal değere geri döndür
                        self.usernameTextField.text = self.viewModel.originalValues["username"]
                        self.viewModel.username = self.viewModel.originalValues["username"] ?? ""
                    }
                } else {
                    // Username benzersizse devam et
                    self.continueWithSaving(user: user, updatedData: updatedData)
                }
            }
        } else {
            // Username değişikliği yoksa direkt kaydet
            continueWithSaving(user: user, updatedData: updatedData)
        }
    }
    
    private func continueWithSaving(user: FirebaseAuth.User, updatedData: [String: Any]) {
        // Profil fotoğrafı değişimi veya text değişimi varsa güncelleme yap
        let hasTextChanges = !updatedData.isEmpty
        
        // Eğer hiçbir değişiklik yoksa ve profil fotoğrafı da değişmediyse işlemi sonlandır
        if !hasTextChanges && !viewModel.hasProfileImageChanged {
            updateEditingState(false)
            return
        }
        
        // Yükleme göstergesini başlat
        if viewModel.hasProfileImageChanged {
            imageLoadingIndicator.startAnimating()
        }
        
        // Önce profil fotoğrafını kaydet, sonra diğer verileri güncelle
        if viewModel.hasProfileImageChanged {
            viewModel.saveProfileImage(userId: user.uid) { [weak self] success in
                guard let self = self else { return }
                
                if success && hasTextChanges {
                    // Profil fotoğrafı başarıyla kaydedildiyse ve metin değişiklikleri varsa, metinleri de güncelle
                    self.updateProfileData(userId: user.uid, updatedData: updatedData)
                } else if success {
                    // Sadece profil fotoğrafı değiştiyse ve başarıyla kaydedildiyse
                    DispatchQueue.main.async {
                        self.imageLoadingIndicator.stopAnimating()
                        self.viewModel.hasProfileImageChanged = false
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
            updateProfileData(userId: user.uid, updatedData: updatedData)
        }
    }
    
    private func updateProfileData(userId: String, updatedData: [String: Any]) {
        viewModel.updateProfileData(userId: userId, updatedData: updatedData) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.imageLoadingIndicator.stopAnimating()
                
                if success {
                    // Başarılı güncelleme durumunda orijinal değerleri güncelle
                    self.viewModel.updateOriginalValues()
                    self.viewModel.hasProfileImageChanged = false
                    self.updateEditingState(false)
                    
                    // Başarılı güncelleme mesajı göster
                    self.hataMesaji(titleInput: "✅ Başarılı", messageInput: "Profil bilgileriniz başarıyla güncellendi.")
                } else {
                    // Hata durumunda değerleri eski haline getir
                    self.viewModel.resetFieldsToOriginalValues()
                    self.updateUIWithUserData()
                    self.hataMesaji(titleInput: "Hata", messageInput: "Bilgileriniz güncellenirken bir hata oluştu.")
                }
            }
        }
    }
    
    private func updateEditingState(_ isEditing: Bool) {
        // Tüm alanları düzenleme dışına çıkar
        for (field, _) in viewModel.editingFields {
            viewModel.editingFields[field] = isEditing
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
        alert.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive, handler: { [weak self] _ in
            self?.performLogout()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func performLogout() {
        if viewModel.logout() {
            redirectToLogin()
        } else {
            hataMesaji(titleInput: "Hata", messageInput: "Çıkış yapılırken bir hata oluştu.")
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
    
    // MARK: - UIImagePickerController Delegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            viewModel.selectedProfileImage = editedImage
            profileImageView.image = editedImage
            viewModel.hasProfileImageChanged = true
            updateSaveButtonState(isEnabled: true)
        } else if let originalImage = info[.originalImage] as? UIImage {
            viewModel.selectedProfileImage = originalImage
            profileImageView.image = originalImage
            viewModel.hasProfileImageChanged = true
            updateSaveButtonState(isEnabled: true)
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    // MARK: - UIPickerView Delegate & DataSource Methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.genderOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.genderOptions[row]
    }
}
