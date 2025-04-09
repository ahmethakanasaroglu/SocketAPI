import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private let viewModel = ChatViewModel()
    private let tableView = UITableView()
    private let messageInputField = UITextField()
    private let sendButton = UIButton()
    var selectedUser: User? // Kullanıcı buraya atanacak
    var channelId: String = "" // Eklediğimiz yeni özellik
    var currentUserID: String = ""
    
    // Emoji seçici için bileşenler
    private let emojiButton = UIButton()
    private let emojiPicker = UIView()
    private var isEmojiPickerVisible = false
    
    // Sık kullanılan emojiler
    private let popularEmojis = ["👍", "❤️", "😊", "😂", "🎉", "👏", "🙏", "😍", "👌", "😭"]
    
    // Klavye yüksekliğine göre güncellenen constraint
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private let inputContainer = UIView() // Input field ve buton için container
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Geçerli kullanıcı ID'sini al
        if let userID = Auth.auth().currentUser?.uid {
            currentUserID = userID
        } else {
            print("Kullanıcı oturumu bulunamadı!")
        }
        
        // WebSocketManager'ı channelId ile ayarla
        if let selectedUserID = selectedUser?.uid {
            viewModel.setupSocket(withChannelId: channelId, currentUserID: currentUserID, otherUserID: selectedUserID)
        }
        
        setupUI()
        setupEmojiPicker()
        setupGestures()
        setupCustomNavigationTitle()
        
        // Sağ üste "Temizle" butonunu ekle
        let clearButton = UIBarButtonItem(title: "Temizle", style: .plain, target: self, action: #selector(clearChat))
        navigationItem.rightBarButtonItem = clearButton
        
        viewModel.onMessageReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                
                // Yeni mesaj geldiğinde otomatik olarak en alta kaydır
                if let self = self {
                    let count = self.viewModel.messages.count
                    if count > 0 {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            }
        }
        
        viewModel.onMessagesDeleted = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        // Eğer otomatik bir geri butonu istiyorsanız:
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Geri",
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        
        // Klavye bildirimlerini dinle
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Kullanıcı profil resmi yükle
        loadUserProfileImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ekran her göründüğünde mesajların sonuna kaydır
        let count = self.viewModel.messages.count
        if count > 0 {
            let indexPath = IndexPath(row: count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    deinit {
        // Bildirimleri kaldır
        NotificationCenter.default.removeObserver(self)
        // WebSocket bağlantısını kapat
        viewModel.disconnectSocket()
    }
    
    // MARK: - Setup Methods
    
    private func setupCustomNavigationTitle() {
        guard let selectedUser = selectedUser else { return }
        
        // Custom title view oluştur
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        
        // Kullanıcı profil resmi
        let profileImageView = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
        profileImageView.layer.cornerRadius = 15
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.contentMode = .scaleAspectFill
        
        // Varsayılan profil resmi
        let defaultImage = UIImage(systemName: "person.circle.fill")
        profileImageView.image = defaultImage
        profileImageView.tintColor = .systemBlue
        
        // Kullanıcı adı etiketi
        let nameLabel = UILabel(frame: CGRect(x: 40, y: 7, width: 160, height: 30))
        nameLabel.text = selectedUser.name
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Bileşenleri titleView'a ekle
        titleView.addSubview(profileImageView)
        titleView.addSubview(nameLabel)
        
        // titleView'ı navigationItem.titleView olarak ayarla
        navigationItem.titleView = titleView
        
        // Profil fotoğrafını yüklemek için tag ekle
        profileImageView.tag = 100
    }
    
    private func setupUI() {
        // Sistem moduna göre renkleri ayarla
        if #available(iOS 13.0, *) {
            // Sistem modunu takip et
            view.backgroundColor = .systemBackground
        } else {
            // iOS 13 öncesi için
            view.backgroundColor = .white
        }
        
        // TableView ayarları
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = true
        tableView.keyboardDismissMode = .interactive // Önemli: Sürükleme ile klavyeyi kapatma
        tableView.backgroundColor = .clear // Arka planı şeffaf yap
        view.addSubview(tableView)
        
        // Hücreleri kaydır
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "messageCell")
        
        // Input container ayarları
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            inputContainer.backgroundColor = .systemBackground
        } else {
            inputContainer.backgroundColor = .white
        }
        view.addSubview(inputContainer)
        
        // Emoji butonu
        emojiButton.setTitle("😊", for: .normal)
        emojiButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        emojiButton.addTarget(self, action: #selector(toggleEmojiPicker), for: .touchUpInside)
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(emojiButton)
        
        // Mesaj giriş alanı
        messageInputField.delegate = self
        messageInputField.borderStyle = .roundedRect
        messageInputField.placeholder = "Mesajınızı yazın..."
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        messageInputField.autocorrectionType = .no
        if #available(iOS 13.0, *) {
            messageInputField.backgroundColor = .secondarySystemBackground
            messageInputField.textColor = .label
        } else {
            messageInputField.backgroundColor = .lightGray
            messageInputField.textColor = .black
        }
        inputContainer.addSubview(messageInputField)
        
        // Gönder butonu
        sendButton.setTitle("Gönder", for: .normal)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 5
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(sendButton)
        
        // Constraint'leri ayarla
        inputContainerBottomConstraint = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            // TableView constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            
            // Input container constraints
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            inputContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Emoji button constraints
            emojiButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
            emojiButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            emojiButton.widthAnchor.constraint(equalToConstant: 40),
            emojiButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Input field constraints
            messageInputField.leadingAnchor.constraint(equalTo: emojiButton.trailingAnchor, constant: 5),
            messageInputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageInputField.heightAnchor.constraint(equalToConstant: 40),
            
            // Send button constraints
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 80),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupEmojiPicker() {
        // Emoji Picker ayarları
        emojiPicker.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            emojiPicker.backgroundColor = .secondarySystemBackground
        } else {
            emojiPicker.backgroundColor = .lightGray
        }
        emojiPicker.layer.cornerRadius = 10
        emojiPicker.layer.shadowColor = UIColor.black.cgColor
        emojiPicker.layer.shadowOffset = CGSize(width: 0, height: 2)
        emojiPicker.layer.shadowOpacity = 0.3
        emojiPicker.layer.shadowRadius = 3
        emojiPicker.isHidden = true
        view.addSubview(emojiPicker)
        
        // Emoji Picker'ın konumunu ve boyutunu ayarla
        NSLayoutConstraint.activate([
            emojiPicker.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -5),
            emojiPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            emojiPicker.heightAnchor.constraint(equalToConstant: 50),
            emojiPicker.widthAnchor.constraint(equalToConstant: 330)
        ])
        
        // Emojileri ekle
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        emojiPicker.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: emojiPicker.topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: emojiPicker.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: emojiPicker.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: emojiPicker.bottomAnchor, constant: -5)
        ])
        
        // Emojileri ekle
        for emoji in popularEmojis {
            let emojiButton = UIButton()
            emojiButton.setTitle(emoji, for: .normal)
            emojiButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
            emojiButton.addTarget(self, action: #selector(emojiSelected(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(emojiButton)
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // TableView seçimlerini engellemez
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - User Profile Methods
    
    private func loadUserProfileImage() {
        guard let userId = selectedUser?.uid else { return }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        // Önce kullanıcının bir profil fotoğrafı olup olmadığını kontrol et
        profileImageRef.downloadURL { [weak self] (url, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Profil resmi yüklenirken hata: \(error.localizedDescription)")
                // Hata varsa varsayılan resim olarak bırak
                return
            }
            
            guard let url = url else { return }
            
            // Profil fotoğrafını indir
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else {
                    print("Profil resmi indirme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    return
                }
                
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // Navigasyon çubuğundaki resmi güncelle
                        if let titleView = self.navigationItem.titleView as? UIView,
                           let profileImageView = titleView.viewWithTag(100) as? UIImageView {
                            profileImageView.image = image
                            profileImageView.tintColor = .clear
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Chat Actions
    
    @objc private func toggleEmojiPicker() {
        isEmojiPickerVisible.toggle()
        emojiPicker.isHidden = !isEmojiPickerVisible
    }
    
    @objc func emojiSelected(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        
        if let currentText = messageInputField.text {
            messageInputField.text = currentText + emoji
        } else {
            messageInputField.text = emoji
        }
        
        // Emoji seçildiğinde picker'ı kapat
        toggleEmojiPicker()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        
        // Emoji picker'ı da kapat
        if isEmojiPickerVisible {
            toggleEmojiPicker()
        }
    }
    
    @objc private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty else { return }
        viewModel.sendMessage(text)
        messageInputField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
    
    // Klavye açıldığında input container'ı yukarı kaydır
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            
            // Input container'ı klavye üzerine taşı
            inputContainerBottomConstraint.constant = -keyboardHeight + view.safeAreaInsets.bottom
            
            // Animasyonlu bir şekilde güncelle
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                
                // En son mesaja kaydır
                let count = self.viewModel.messages.count
                if count > 0 {
                    let indexPath = IndexPath(row: count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                }
            }
        }
    }
    
    // Klavye kapandığında input container'ı eski haline getir
    @objc private func keyboardWillHide(notification: Notification) {
        // Input container'ı orijinal konumuna geri getir
        inputContainerBottomConstraint.constant = 0
        
        // Animasyonlu bir şekilde güncelle
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Other Actions
    
    @objc func clearChat() {
        let alertController = UIAlertController(
            title: "Sohbeti Temizle",
            message: "Tüm sohbet geçmişi silinecek. Bu işlem geri alınamaz.",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel)
        let deleteAction = UIAlertAction(title: "Tümünü Sil", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteAllMessages { success in
                if success {
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                } else {
                    // Silme başarısız olursa kullanıcıya bildir
                    let errorAlert = UIAlertController(
                        title: "Hata",
                        message: "Sohbet temizlenirken bir hata oluştu.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self?.present(errorAlert, animated: true)
                }
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true)
    }
    
    @objc func goBack() {
        let usersVC = MainTabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: usersVC)
            window.makeKeyAndVisible()
        }
    }
    
    // Mesaj tarihini formatla
    private func formatMessageTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        let message = viewModel.messages[indexPath.row]
        
        // Burada reaction parametresini de iletiyoruz
        cell.configure(
            with: message.text, // displayText değil, text kullanın
            isFromCurrentUser: message.isFromCurrentUser,
            timestamp: message.timestamp,
            reaction: message.reaction // Tepki bilgisini ilet
        )
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Mesaja tepki ekleme ve silme için context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // Tepki ekleme aksiyonları
            let emojiActions = self.popularEmojis.map { emoji in
                UIAction(title: "Tepki: \(emoji)", image: nil) { [weak self] _ in
                    guard let self = self else { return }
                    
                    let message = self.viewModel.messages[indexPath.row]
                    
                    // Aynı emoji varsa kaldır, yoksa ekle/değiştir
                    if message.reaction == emoji {
                        self.viewModel.setReaction(at: indexPath.row, reaction: nil)
                    } else {
                        self.viewModel.setReaction(at: indexPath.row, reaction: emoji)
                    }
                }
            }
            
            // Silme aksiyonu
            let deleteAction = UIAction(title: "Sil", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.viewModel.deleteMessage(at: indexPath.row)
            }
            
            // Tepki kaldır seçeneği
            let message = self.viewModel.messages[indexPath.row]
            let menuItems: [UIMenuElement]
            
            // Tepki varsa kaldırma seçeneğini göster
            if message.reaction != nil {
                let removeReactionAction = UIAction(title: "Tepkiyi Kaldır", image: UIImage(systemName: "xmark.circle")) { [weak self] _ in
                    self?.viewModel.setReaction(at: indexPath.row, reaction: nil)
                }
                
                menuItems = [
                    UIMenu(title: "Tepki Ekle", children: emojiActions),
                    removeReactionAction,
                    deleteAction
                ]
            } else {
                menuItems = [
                    UIMenu(title: "Tepki Ekle", children: emojiActions),
                    deleteAction
                ]
            }
            
            return UIMenu(title: "", children: menuItems)
        }
    }
    
    // TableView'i dokunma ile kaydırabilir yap
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Mesaja tıklandığında klavyeyi kapat
        dismissKeyboard()
    }
}

// Mesaj hücresi - tepki ekleme desteği ile
class MessageTableViewCell: UITableViewCell {
    private let messageLabel = UILabel()
    private let bubbleView = UIView()
    private let timeLabel = UILabel()
    
    // Tepki görünümü
    private let reactionView = UIView()
    private let reactionLabel = UILabel()
    
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    // Tepki konumlandırma kısıtlamaları
    private var reactionLeadingConstraint: NSLayoutConstraint?
    private var reactionTrailingConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Baloncuk görünümü
        bubbleView.layer.cornerRadius = 12
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // Mesaj etiketi
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Zaman etiketi
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .gray
        timeLabel.textAlignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(timeLabel)
        
        // Tepki görünümü
        reactionView.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.8)
        reactionView.layer.cornerRadius = 14
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        reactionView.isHidden = true // Başlangıçta gizli
        contentView.addSubview(reactionView)
        
        // Tepki etiketi
        reactionLabel.font = UIFont.systemFont(ofSize: 16)
        reactionLabel.textAlignment = .center
        reactionLabel.translatesAutoresizingMaskIntoConstraints = false
        reactionView.addSubview(reactionLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -4),
            
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4),
            timeLabel.heightAnchor.constraint(equalToConstant: 12),
            
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            // Tepki görünümü constraints
            reactionView.widthAnchor.constraint(equalToConstant: 28),
            reactionView.heightAnchor.constraint(equalToConstant: 28),
            reactionView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5),
            
            // Tepki etiketi constraints
            reactionLabel.centerXAnchor.constraint(equalTo: reactionView.centerXAnchor),
            reactionLabel.centerYAnchor.constraint(equalTo: reactionView.centerYAnchor)
        ])
        
        // Leading ve trailing constraint'leri tanımla
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        // Tepki constraint'leri tanımla
        reactionLeadingConstraint = reactionView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -10)
        reactionTrailingConstraint = reactionView.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 10)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Renk modu değiştiğinde UI'yi güncelle
                if let text = messageLabel.text, let isFromCurrentUser = isCurrentUserMessage() {
                    configure(with: text, isFromCurrentUser: isFromCurrentUser, timestamp: nil, reaction: nil)
                }
            }
        }
    }
    
    // Mevcut mesajın kimden geldiğini tahmin et
    private func isCurrentUserMessage() -> Bool? {
        // Eğer mesaj sağda ise kullanıcıdan gelmiştir
        if trailingConstraint?.isActive == true {
            return true
        } else if leadingConstraint?.isActive == true && trailingConstraint?.isActive == false {
            return false
        }
        return nil
    }
    
    // Zaman formatlama fonksiyonu
    private func formatMessageTime(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func configure(with message: String, isFromCurrentUser: Bool, timestamp: Date?, reaction: String? = nil) {
        // Mesaj içeriği ve zaman
        messageLabel.text = message
        timeLabel.text = formatMessageTime(timestamp)
        
        // Önceki constraint'leri devre dışı bırak
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        reactionLeadingConstraint?.isActive = false
        reactionTrailingConstraint?.isActive = false
        
        // Kullanıcıya göre baloncuk rengini ve konumunu ayarla
        if isFromCurrentUser {
            // Sağ taraf (kendi mesajlarım)
            trailingConstraint?.isActive = true
            leadingConstraint?.isActive = false
            
            // Tepki pozisyonu (sol tarafta olacak)
            reactionLeadingConstraint?.isActive = true
            reactionTrailingConstraint?.isActive = false
            
            // Sistem moduna göre renkler
            if #available(iOS 13.0, *) {
                bubbleView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
                messageLabel.textColor = .label
                timeLabel.textColor = .secondaryLabel
            } else {
                bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.3)
                messageLabel.textColor = .black
                timeLabel.textColor = .darkGray
            }
        } else {
            // Sol taraf (karşı tarafın mesajları)
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = false
            
            // Tepki pozisyonu (sağ tarafta olacak)
            reactionTrailingConstraint?.isActive = true
            reactionLeadingConstraint?.isActive = false
            
            // Sistem moduna göre renkler
            if #available(iOS 13.0, *) {
                bubbleView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
                messageLabel.textColor = .label
                timeLabel.textColor = .secondaryLabel
            } else {
                bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 0.3)
                messageLabel.textColor = .black
                timeLabel.textColor = .darkGray
            }
        }
        
        // Tepki ayarları
        if let reaction = reaction {
            reactionView.isHidden = false
            reactionLabel.text = reaction
        } else {
            reactionView.isHidden = true
        }
        
        setNeedsLayout()
    }
}
