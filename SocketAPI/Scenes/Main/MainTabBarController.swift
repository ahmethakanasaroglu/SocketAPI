import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    private func setupTabBar() {
        tabBar.isTranslucent = false
        
        let homeVC = UsersViewController()
        let settingsVC = ProfileViewController()
        
        homeVC.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message"), selectedImage: UIImage(systemName: "message.fill"))
        settingsVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), selectedImage: UIImage(systemName: "person.circle.fill"))
        
        let homeNav = UINavigationController(rootViewController: homeVC)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        viewControllers = [homeNav, settingsNav]
        
        updateAppearance() // İlk yükleme sırasında güncelleme
    }
    
    private func updateAppearance() {
        if traitCollection.userInterfaceStyle == .dark {
            tabBar.backgroundColor = .black
            tabBar.tintColor = .white
            tabBar.unselectedItemTintColor = .white
            
            for item in tabBar.items ?? [] {
                item.image = item.image?.withRenderingMode(.alwaysOriginal).withTintColor(.white)
                item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal).withTintColor(.white)
            }
        } else {
            tabBar.backgroundColor = .white
            tabBar.tintColor = .blue
            tabBar.unselectedItemTintColor = .blue
            
            for item in tabBar.items ?? [] {
                item.image = item.image?.withRenderingMode(.alwaysOriginal).withTintColor(.blue.withAlphaComponent(0.6))
                item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal).withTintColor(.blue.withAlphaComponent(0.6))
            }
        }
    }
}
