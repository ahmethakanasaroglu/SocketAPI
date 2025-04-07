import UIKit
import FirebaseAuth

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private let viewModel = ChatViewModel()
    private let tableView = UITableView()
    private let messageInputField = UITextField()
    private let sendButton = UIButton()
    var selectedUser: User? // Kullanıcı buraya atanacak
    var channelId: String = "" // Eklediğimiz yeni özellik
    var currentUserID: String = ""
    
    // Klavye yüksekliğine göre güncellenen constraint
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private let inputContainer = UIView() // Input field ve buton için container
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedUser?.name
        
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
        setupGestures()
        
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
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // TableView ayarları
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = true
        tableView.keyboardDismissMode = .interactive // Önemli: Sürükleme ile klavyeyi kapatma
        view.addSubview(tableView)
        
        // Hücreleri kaydır
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: "messageCell")
        
        // Input container ayarları
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = .systemBackground
        view.addSubview(inputContainer)
        
        // Mesaj giriş alanı
        messageInputField.delegate = self
        messageInputField.borderStyle = .roundedRect
        messageInputField.placeholder = "Mesajınızı yazın..."
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        messageInputField.autocorrectionType = .no
        inputContainer.addSubview(messageInputField)
        
        // Gönder butonu
        sendButton.setTitle("Gönder", for: .normal)
        sendButton.backgroundColor = .blue
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
            
            // Input field constraints
            messageInputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
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
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // TableView seçimlerini engellemez
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
    
    // UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
        let message = viewModel.messages[indexPath.row]
        
        cell.configure(with: message.displayText, isFromCurrentUser: message.isFromCurrentUser)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Mesaj silme işlemi için context menu ekleyelim
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(title: "Sil", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.viewModel.deleteMessage(at: indexPath.row)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
    
    // TableView'i dokunma ile kaydırabilir yap
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Mesaja tıklandığında klavyeyi kapat
        dismissKeyboard()
    }
}

// Mesaj hücresi
class MessageTableViewCell: UITableViewCell {
    private let messageLabel = UILabel()
    private let bubbleView = UIView()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // Baloncuk görünümü
        bubbleView.layer.cornerRadius = 12
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        // Mesaj etiketi
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
        
        // Leading ve trailing constraint'leri ayrı ayrı tanımla
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    }
    
    
    func configure(with message: String, isFromCurrentUser: Bool) {
        messageLabel.text = message
        
        // Önceki constraint'leri devre dışı bırak
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        
        // Kullanıcıya göre baloncuk rengini ve konumunu ayarla
        if isFromCurrentUser {
            bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 0.2)
            leadingConstraint?.constant = 60
            trailingConstraint?.constant = -16
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = true
        } else {
            bubbleView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 0.2)
            leadingConstraint?.constant = 16
            trailingConstraint?.constant = -60
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = false
        }
        
        setNeedsLayout()
    }
}
