//
//  SceneDelegate.swift
//  LsdSandbox
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)

        let lsdVC = ViewController()
        lsdVC.tabBarItem = UITabBarItem(title: "LSD 沙箱", image: nil, tag: 0)

        let fileVC = FileBrowserViewController()
        let navFile = UINavigationController(rootViewController: fileVC)
        navFile.tabBarItem = UITabBarItem(title: "文件管理", image: nil, tag: 1)

        let tabBar = UITabBarController()
        tabBar.viewControllers = [lsdVC, navFile]

        window.rootViewController = tabBar
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}