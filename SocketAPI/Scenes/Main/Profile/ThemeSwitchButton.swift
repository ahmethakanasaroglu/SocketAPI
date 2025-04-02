import UIKit

class ThemeSwitchButton: UIControl {
    private let backgroundView = UIView()
    private let thumbView = UIView()
    private let sunImageView = UIImageView(image: UIImage(systemName: "sun.max.fill"))
    private let moonImageView = UIImageView(image: UIImage(systemName: "moon.fill"))
    
    private var isDarkMode: Bool {
        return UserDefaults.standard.bool(forKey: "selectedTheme")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateUI(animated: false)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateUI(animated: false)
    }
    
    private func setupUI() {
        self.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        self.layer.cornerRadius = 15
        
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        
        thumbView.frame = CGRect(x: 2, y: 2, width: 26, height: 26)
        thumbView.layer.cornerRadius = 13
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowOpacity = 0.2
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 2)
        thumbView.layer.shadowRadius = 2
        thumbView.backgroundColor = .white
        addSubview(thumbView)
        
        sunImageView.tintColor = .black
        moonImageView.tintColor = .white
        sunImageView.frame = CGRect(x: 8, y: 8, width: 14, height: 14)
        moonImageView.frame = CGRect(x: 38, y: 8, width: 14, height: 14)
        
        addSubview(sunImageView)
        addSubview(moonImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSwitch))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleSwitch() {
        let newState = !isDarkMode
        UserDefaults.standard.set(newState, forKey: "selectedTheme")
        updateUI(animated: true)
        
        UIView.animate(withDuration: 0.3) {
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = newState ? .dark : .light
        }
        sendActions(for: .valueChanged)
    }
    
    private func updateUI(animated: Bool) {
        let isDark = isDarkMode
        let newBackgroundColor = isDark ? UIColor.gray : UIColor.systemYellow
        let newThumbX = isDark ? (self.bounds.width - 28) : 2
        
        let animations = {
            self.backgroundView.backgroundColor = newBackgroundColor
            self.thumbView.frame.origin.x = newThumbX
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: animations)
        } else {
            animations()
        }
    }
}
