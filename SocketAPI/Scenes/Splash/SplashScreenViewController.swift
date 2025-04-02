import UIKit

class SplashScreenViewController: UIViewController {
    
    let appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "socketapi_logo") // Logoyu buraya ekleyin
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let appTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "SocketAPI"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textAlignment = .center
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(appLogoImageView)
        view.addSubview(appTitleLabel)
        
        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            appLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appLogoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            appLogoImageView.widthAnchor.constraint(equalToConstant: 80),
            appLogoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            appTitleLabel.topAnchor.constraint(equalTo: appLogoImageView.bottomAnchor, constant: 10),
            appTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Splash Screen 2 saniye sonra Main Tab Bar Controller'a yönlendirme
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showMainTabBarController()
        }
    }
    
    // Splash ekranını kapatıp Main Tab Bar'a geçiş
    func showMainTabBarController() {
        let mainTabBarController = MainTabBarController() // MainTabBarController'ı kullanarak geçiş
        let navController = UINavigationController(rootViewController: mainTabBarController)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
    }
}
