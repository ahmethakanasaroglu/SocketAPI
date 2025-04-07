// CustomAlertView.swift
import UIKit

class CustomAlertView: UIView {
    
    // UI Elemanları
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let iconImageView = UIImageView()
    
    var onDismiss: (() -> Void)?
    
    init(title: String, message: String, buttonTitle: String) {
        super.init(frame: .zero)
        
        setupView()
        configure(title: title, message: message, buttonTitle: buttonTitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Ana görünüm (karartma efekti için)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Container view ayarları
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // İkon ayarları
        iconImageView.image = UIImage(systemName: "wifi.slash")
        iconImageView.tintColor = .red
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Başlık label ayarları
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Mesaj label ayarları
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Buton ayarları
        actionButton.backgroundColor = .systemBlue
        actionButton.layer.cornerRadius = 8
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        actionButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        // View hiyerarşisi
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(actionButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }
    
    private func configure(title: String, message: String, buttonTitle: String) {
        titleLabel.text = title
        messageLabel.text = message
        actionButton.setTitle(buttonTitle, for: .normal)
    }
    
    @objc private func dismissAlert() {
        // Animasyonla kapat
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
    
    // Alert'i gösterme metodu
    func show(in viewController: UIViewController, completion: (() -> Void)? = nil) {
        self.alpha = 0
        self.frame = viewController.view.bounds
        self.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(self)
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            self.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1
        }, completion: { _ in
            completion?()
        })
    }
}


