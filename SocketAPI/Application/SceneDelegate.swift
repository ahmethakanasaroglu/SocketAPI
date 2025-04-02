//
//  SceneDelegate.swift
//  SocketAPI
//
//  Created by Ahmet Hakan Asaroğlu on 25.03.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = LoginViewController()
        window?.makeKeyAndVisible()
        applySavedTheme()
    }
    
    private func applySavedTheme() {
        let isDark = UserDefaults.standard.bool(forKey: "selectedTheme")
        window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

}

