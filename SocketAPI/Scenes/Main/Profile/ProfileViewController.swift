import UIKit
import AVFoundation
import FirebaseAuth

class ProfileViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    private let viewModel = ProfileViewModel()
    private let themeSwitchButton = ThemeSwitchButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    private let genderPicker = UIPickerView()
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 50
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemBlue
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        return iv
    }()
    
    private lazy var imageLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Yeni bir activity indicator ekliyoruz - kaydetme işlemi için
    private lazy var saveLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // Form Fields
    private lazy var nameTextField = createTextField(placeholder: "İsim - Soyisim")
    private lazy var usernameTextField = createTextField(placeholder: "Kullanıcı Adı")
    private lazy var ageTextField = createTextField(placeholder: "Yaş", keyboardType: .numberPad)
    private lazy var cityTextField = createTextField(placeholder: "Şehir")
    private lazy var genderTextField = createTextField(placeholder: "Cinsiyet")
    
    // Change Buttons
    private lazy var changeNameButton = createChangeButton(selector: #selector(changeNameTapped))
    private lazy var changeUsernameButton = createChangeButton(selector: #selector(changeUsernameTapped))
    private lazy var changeAgeButton = createChangeButton(selector: #selector(changeAgeTapped))
    private lazy var changeCityButton = createChangeButton(selector: #selector(changeCityTapped))
    private lazy var changeGenderButton = createChangeButton(selector: #selector(changeGenderTapped))
    
    // Info Labels
    private lazy var emailInfoLabel = createInfoLabel(text: "Email:")
    private lazy var emailLabel = createValueLabel()
    private lazy var uidInfoLabel = createInfoLabel(text: "UID:")
    private lazy var uidLabel = createValueLabel()
    
    // Action Buttons
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Kaydet", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private lazy var logoutButton: UIButton = {
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
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupGenderPicker()
        fetchUserData()
        setupRightBarButton()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        navigationItem.title = "Profil"
        
        // ScrollView & ContentView Setup
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
        
        // Profile Image Setup
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
        
        // Fields Container Setup
        let fieldsContainer = UIView()
        fieldsContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fieldsContainer)
        
        NSLayoutConstraint.activate([
            fieldsContainer.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
            fieldsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fieldsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Create Field Groups
        let nameField = createFieldGroup(label: "İsim - Soyisim:", textField: nameTextField, button: changeNameButton)
        let usernameField = createFieldGroup(label: "Kullanıcı Adı:", textField: usernameTextField, button: changeUsernameButton)
        let ageField = createFieldGroup(label: "Yaş:", textField: ageTextField, button: changeAgeButton)
        let cityField = createFieldGroup(label: "Şehir:", textField: cityTextField, button: changeCityButton)
        let genderField = createFieldGroup(label: "Cinsiyet:", textField: genderTextField, button: changeGenderButton)
        
        // Create Info Rows
        let emailContainer = createInfoRow(titleLabel: emailInfoLabel, valueLabel: emailLabel)
        let uidContainer = createInfoRow(titleLabel: uidInfoLabel, valueLabel: uidLabel)
        
        // Stack View Setup
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
        
        // Action Buttons Setup
        contentView.addSubview(saveButton)
        contentView.addSubview(logoutButton)
        
        // Save butonuna aktivite göstergesini ekleyelim
        saveButton.addSubview(saveLoadingIndicator)
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: fieldsContainer.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Save aktivite göstergesi için constraint'ler
            saveLoadingIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            saveLoadingIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor),
            
            logoutButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 54),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func setupGenderPicker() {
        genderPicker.delegate = self
        genderPicker.dataSource = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(genderPickerDoneTapped))
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(genderPickerCancelTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([cancelButton, flexSpace, doneButton], animated: true)
        
        genderTextField.inputView = genderPicker
        genderTextField.inputAccessoryView = toolbar
    }
    
    private func setupRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: themeSwitchButton)
    }
    
    // MARK: - Factory Methods
    private func createTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        tf.textColor = .label
        tf.textAlignment = .left
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .roundedRect
        tf.isUserInteractionEnabled = false
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.layer.cornerRadius = 10
        tf.layer.borderWidth = 0.8
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 40))
        tf.leftViewMode = .always
        return tf
    }
    
    private func createChangeButton(selector: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Değiştir", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: selector, for: .touchUpInside)
        return btn
    }
    
    private func createInfoLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createValueLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    // MARK: - Data Methods
    private func fetchUserData() {
        imageLoadingIndicator.startAnimating()
        
        viewModel.fetchUserData { [weak self] success in
            guard let self = self else { return }
            
            if success {
                self.updateUIWithUserData()
                
                if let userId = Auth.auth().currentUser?.uid {
                    self.loadProfileImage(userId: userId)
                } else {
                    self.imageLoadingIndicator.stopAnimating()
                }
            } else {
                self.imageLoadingIndicator.stopAnimating()
                self.showAlert(title: "Hata", message: "Kullanıcı bilgileri yüklenemedi.")
            }
        }
    }
    
    private func updateUIWithUserData() {
        nameTextField.text = viewModel.name
        usernameTextField.text = viewModel.username
        ageTextField.text = viewModel.age != nil ? "\(viewModel.age!)" : ""
        cityTextField.text = viewModel.city
        genderTextField.text = viewModel.gender
        
        if let index = viewModel.genderOptions.firstIndex(of: viewModel.gender) {
            genderPicker.selectRow(index, inComponent: 0, animated: false)
        }
        
        emailLabel.text = viewModel.email
        uidLabel.text = viewModel.uid
    }
    
    private func loadProfileImage(userId: String) {
        // Profil resmi yükleme başladığını göster
        if profileImageView.image == UIImage(systemName: "person.circle.fill") {
            imageLoadingIndicator.startAnimating()
        } else {
            // Eğer zaten bir resim varsa, loading sırasında resmi hafifçe soldur
            UIView.animate(withDuration: 0.2) {
                self.profileImageView.alpha = 0.7
            }
        }
        
        // Cache kullanarak profil resmini yükle
        viewModel.loadProfileImage(userId: userId) { [weak self] image in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Yükleme göstergesini durdur ve resmi normal opaklığa getir
                self.imageLoadingIndicator.stopAnimating()
                UIView.animate(withDuration: 0.2) {
                    self.profileImageView.alpha = 1.0
                }
                
                if let image = image {
                    self.profileImageView.image = image
                    self.profileImageView.tintColor = .clear
                } else {
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self.profileImageView.tintColor = .systemBlue
                }
            }
        }
    }
    
    // MARK: - Action Methods
    @objc private func profileImageTapped() {
        let actionSheet = UIAlertController(title: "Profil Fotoğrafı", message: "Seçiminizi yapın", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Galeriden Seç", style: .default) { [weak self] _ in
            self?.showImagePicker(sourceType: .photoLibrary)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Fotoğraf Çek", style: .default) { [weak self] _ in
            self?.showImagePicker(sourceType: .camera)
        })
        
        if profileImageView.tintColor == .clear {
            actionSheet.addAction(UIAlertAction(title: "Fotoğrafı Kaldır", style: .destructive) { [weak self] _ in
                self?.removeProfileImage()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        if (sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera)) ||
            (sourceType == .photoLibrary && !UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            showAlert(title: "Hata", message: sourceType == .camera ? "Kamera kullanılamıyor." : "Fotograf galerisi kullanılamıyor.")
            return
        }
        
        if sourceType == .camera {
            let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch cameraAuthStatus {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.presentImagePicker(sourceType: sourceType)
                        } else {
                            self?.showAlert(title: "İzin Hatası", message: "Kamera erişim izni verilmedi.")
                        }
                    }
                }
                return
            case .restricted, .denied:
                showAlert(title: "İzin Hatası", message: "Kamera erişim izni verilmedi. Ayarlara giderek izin vermeniz gerekiyor.")
                return
            case .authorized: break
            @unknown default: break
            }
        }
        
        presentImagePicker(sourceType: sourceType)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerController Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            viewModel.selectedProfileImage = editedImage
            profileImageView.image = editedImage
            profileImageView.tintColor = .clear
            viewModel.hasProfileImageChanged = true
            updateSaveButtonState(isEnabled: true)
        } else if let originalImage = info[.originalImage] as? UIImage {
            viewModel.selectedProfileImage = originalImage
            profileImageView.image = originalImage
            profileImageView.tintColor = .clear
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
    
    private func removeProfileImage() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        viewModel.selectedProfileImage = nil
        viewModel.hasProfileImageChanged = true
        updateSaveButtonState(isEnabled: true)
        
        // Profil resmi kaldırıldığında cache'ten de kaldır
        if let userId = Auth.auth().currentUser?.uid {
            viewModel.invalidateImageCache(forUserId: userId)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func genderPickerDoneTapped() {
        let selectedRow = genderPicker.selectedRow(inComponent: 0)
        genderTextField.text = viewModel.genderOptions[selectedRow]
        viewModel.gender = viewModel.genderOptions[selectedRow]
        genderTextField.resignFirstResponder()
    }
    
    @objc private func genderPickerCancelTapped() {
        genderTextField.resignFirstResponder()
    }
    
    // Field Edit Methods
    @objc private func changeNameTapped() { toggleFieldEditing(field: "name", textField: nameTextField, button: changeNameButton) }
    @objc private func changeUsernameTapped() { toggleFieldEditing(field: "username", textField: usernameTextField, button: changeUsernameButton) }
    @objc private func changeAgeTapped() { toggleFieldEditing(field: "age", textField: ageTextField, button: changeAgeButton) }
    @objc private func changeCityTapped() { toggleFieldEditing(field: "city", textField: cityTextField, button: changeCityButton) }
    
    @objc private func changeGenderTapped() {
        let isEditing = !viewModel.editingFields["gender", default: false]
        
        if !isEditing && viewModel.editingFields["gender", default: false] {
            genderTextField.text = viewModel.originalValues["gender"]
            viewModel.gender = viewModel.originalValues["gender"] ?? ""
        }
        
        viewModel.editingFields["gender"] = isEditing
        changeGenderButton.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            showGenderPicker()
        }
        
        updateSaveButtonState(isEnabled: viewModel.isAnyFieldEditing())
    }
    
    private func toggleFieldEditing(field: String, textField: UITextField, button: UIButton) {
        let isEditing = !viewModel.editingFields[field, default: false]
        
        if !isEditing && viewModel.editingFields[field, default: false] {
            textField.text = viewModel.originalValues[field]
            
            switch field {
            case "name": viewModel.name = viewModel.originalValues[field] ?? ""
            case "username": viewModel.username = viewModel.originalValues[field] ?? ""
            case "age":
                if let ageStr = viewModel.originalValues[field], let age = Int(ageStr) {
                    viewModel.age = age
                } else {
                    viewModel.age = nil
                }
            case "city": viewModel.city = viewModel.originalValues[field] ?? ""
            default: break
            }
        }
        
        viewModel.editingFields[field] = isEditing
        textField.isUserInteractionEnabled = isEditing
        button.setTitle(isEditing ? "İptal" : "Değiştir", for: .normal)
        
        if isEditing {
            textField.becomeFirstResponder()
        }
        
        updateSaveButtonState(isEnabled: viewModel.isAnyFieldEditing())
    }
    
    private func showGenderPicker() {
        let actionSheet = UIAlertController(title: "Cinsiyet Seçiniz", message: nil, preferredStyle: .actionSheet)
        
        for option in viewModel.genderOptions {
            actionSheet.addAction(UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.genderTextField.text = option
                self?.viewModel.gender = option
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "İptal", style: .cancel) { [weak self] _ in
            if self?.genderTextField.text?.isEmpty ?? true {
                self?.genderTextField.text = self?.viewModel.originalValues["gender"]
                self?.viewModel.gender = self?.viewModel.originalValues["gender"] ?? ""
            }
        })
        
        present(actionSheet, animated: true)
    }
    
    private func updateSaveButtonState(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    // Kaydetme işlemi başladığında UI'ı güncelleme
    private func showSavingState() {
        // Kaydet butonunun metnini gizle ve activity indicator'ı göster
        saveButton.setTitle("", for: .normal)
        saveLoadingIndicator.startAnimating()
        
        // Butonları ve alanları devre dışı bırak
        saveButton.isEnabled = false
        logoutButton.isEnabled = false
        
        // Tüm değiştir butonlarını devre dışı bırak
        changeNameButton.isEnabled = false
        changeUsernameButton.isEnabled = false
        changeAgeButton.isEnabled = false
        changeCityButton.isEnabled = false
        changeGenderButton.isEnabled = false
        
        // Alanların etkileşimini devre dışı bırak
        nameTextField.isUserInteractionEnabled = false
        usernameTextField.isUserInteractionEnabled = false
        ageTextField.isUserInteractionEnabled = false
        cityTextField.isUserInteractionEnabled = false
        genderTextField.isUserInteractionEnabled = false
        
        // Profil fotoğrafını devre dışı bırak
        profileImageView.isUserInteractionEnabled = false
    }
    
    // Kaydetme işlemi tamamlandığında UI'ı güncelleme
    private func hideSavingState() {
        // Kaydet butonunu normal durumuna getir
        saveButton.setTitle("Kaydet", for: .normal)
        saveLoadingIndicator.stopAnimating()
        
        // Butonları etkinleştir
        saveButton.isEnabled = viewModel.isAnyFieldEditing()
        saveButton.alpha = viewModel.isAnyFieldEditing() ? 1.0 : 0.5
        logoutButton.isEnabled = true
        
        // Değiştir butonlarını normal durumlarına getir
        changeNameButton.isEnabled = true
        changeUsernameButton.isEnabled = true
        changeAgeButton.isEnabled = true
        changeCityButton.isEnabled = true
        changeGenderButton.isEnabled = true
        
        // Profil fotoğrafını etkinleştir
        profileImageView.isUserInteractionEnabled = true
    }
    
    @objc private func saveTapped() {
        // Kaydetme işlemi başlamadan önce UI'ı güncelle
        showSavingState()
        
        // Update model from textfields
        if viewModel.editingFields["name", default: false] { viewModel.name = nameTextField.text ?? "" }
        if viewModel.editingFields["username", default: false] { viewModel.username = usernameTextField.text ?? "" }
        if viewModel.editingFields["age", default: false] {
            if let ageText = ageTextField.text, let age = Int(ageText) {
                viewModel.age = age
            } else {
                viewModel.age = nil
            }
        }
        if viewModel.editingFields["city", default: false] { viewModel.city = cityTextField.text ?? "" }
        
        // Validate fields
        let validationErrors = viewModel.validateFields()
        if !validationErrors.isEmpty {
            hideSavingState() // Hata durumunda yükleme göstergesini kapat
            showAlert(title: "Hata", message: validationErrors.joined(separator: "\n"))
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            hideSavingState() // Hata durumunda yükleme göstergesini kapat
            return
        }
        
        let updatedData = viewModel.collectUpdatedData()
        
        // Check username uniqueness if needed
        if viewModel.editingFields["username", default: false] {
            viewModel.checkUsernameUniqueness(username: viewModel.username) { [weak self] isUnique in
                guard let self = self else { return }
                
                if !isUnique {
                    DispatchQueue.main.async {
                        self.hideSavingState() // Hata durumunda yükleme göstergesini kapat
                        self.showAlert(title: "Hata", message: "Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir kullanıcı adı seçin.")
                        self.usernameTextField.text = self.viewModel.originalValues["username"]
                        self.viewModel.username = self.viewModel.originalValues["username"] ?? ""
                    }
                } else {
                    self.continueWithSaving(user: user, updatedData: updatedData)
                }
            }
        } else {
            continueWithSaving(user: user, updatedData: updatedData)
        }
    }
    
    private func continueWithSaving(user: FirebaseAuth.User, updatedData: [String: Any]) {
        let hasTextChanges = !updatedData.isEmpty
        
        if !hasTextChanges && !viewModel.hasProfileImageChanged {
            DispatchQueue.main.async {
                self.hideSavingState() // İşlem tamamlandığında yükleme göstergesini kapat
                self.updateEditingState(false)
            }
            return
        }
        
        if viewModel.hasProfileImageChanged {
            viewModel.saveProfileImage(userId: user.uid) { [weak self] success in
                guard let self = self else { return }
                
                if success && hasTextChanges {
                    self.updateProfileData(userId: user.uid, updatedData: updatedData)
                } else if success {
                    DispatchQueue.main.async {
                        self.hideSavingState() // İşlem tamamlandığında yükleme göstergesini kapat
                        self.viewModel.hasProfileImageChanged = false
                        self.updateEditingState(false)
                        self.showAlert(title: "✅ Başarılı", message: "Profil fotoğrafınız başarıyla güncellendi.")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hideSavingState() // Hata durumunda yükleme göstergesini kapat
                        self.showAlert(title: "Hata", message: "Profil fotoğrafı güncellenirken bir hata oluştu.")
                    }
                }
            }
        } else if hasTextChanges {
            updateProfileData(userId: user.uid, updatedData: updatedData)
        }
    }
    
    private func updateProfileData(userId: String, updatedData: [String: Any]) {
        viewModel.updateProfileData(userId: userId, updatedData: updatedData) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideSavingState() // İşlem tamamlandığında yükleme göstergesini kapat
                
                if success {
                    self.viewModel.updateOriginalValues()
                    self.viewModel.hasProfileImageChanged = false
                    self.updateEditingState(false)
                    self.showAlert(title: "✅ Başarılı", message: "Profil bilgileriniz başarıyla güncellendi.")
                } else {
                    self.viewModel.resetFieldsToOriginalValues()
                    self.updateUIWithUserData()
                    self.showAlert(title: "Hata", message: "Bilgileriniz güncellenirken bir hata oluştu.")
                }
            }
        }
    }
    
    private func updateEditingState(_ isEditing: Bool) {
        for (field, _) in viewModel.editingFields {
            viewModel.editingFields[field] = isEditing
        }
        
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
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        alert.addAction(UIAlertAction(title: "Çıkış Yap", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        // Çıkış yaparken cache'i temizle
        viewModel.clearImageCache()
        
        if viewModel.logout() {
            redirectToLogin()
        } else {
            showAlert(title: "Hata", message: "Çıkış yapılırken bir hata oluştu.")
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}
