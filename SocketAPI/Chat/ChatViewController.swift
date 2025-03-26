import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    private let viewModel = ChatViewModel()
    private let tableView = UITableView()
    private let messageInputField = UITextField()
    private let sendButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // UITextField Delegate'i atandı (Enter tuşunu yakalamak için)
        messageInputField.delegate = self

        viewModel.onMessageReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }

        // Ekrana dokununca klavyeyi kapatacak Gesture ekledik
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        messageInputField.borderStyle = .roundedRect
        messageInputField.placeholder = "Mesajınızı yazın..."
        messageInputField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInputField)
        
        sendButton.setTitle("Gönder", for: .normal)
        sendButton.backgroundColor = .blue
        sendButton.layer.cornerRadius = 5
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputField.topAnchor, constant: -10),
            
            messageInputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            messageInputField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageInputField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            sendButton.widthAnchor.constraint(equalToConstant: 80),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func sendMessage() {
        guard let text = messageInputField.text, !text.isEmpty else { return }
        viewModel.sendMessage(text)
        messageInputField.text = ""
    }

    // 📌 Enter (Return) tuşuna basınca mesajı gönder
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }

    // 📌 Ekrana dokununca klavyeyi kapat
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = viewModel.messages[indexPath.row]
        return cell
    }
}
