//
//  SceneDelegate.swift
//  SocketAPI
//
//  Created by Ahmet Hakan Asaroğlu on 25.03.2025.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene

        // Kullanıcı oturumu kontrolü
        if Auth.auth().currentUser != nil {
            window?.rootViewController = MainTabBarController()
        } else {
            window?.rootViewController = LoginViewController()
        }
        
        window?.makeKeyAndVisible()
        applySavedTheme()
    }
    
    private func applySavedTheme() {
        let isDark = UserDefaults.standard.bool(forKey: "selectedTheme")
        window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

}
