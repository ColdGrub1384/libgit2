//
//  askPassword.swift
//  git
//
//  Created by Emma on 04-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import UIKit

@_cdecl("git_ask_password")
func gitAskPassword(title: UnsafePointer<CChar>, message: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    let password = askPassword(title: String(cString: title), message: String(cString: message))
    let cPassword = UnsafeMutablePointer<CChar>(mutating: (password as NSString).utf8String)
    return cPassword
}

/// Asks for password in an alert view controller.
func askPassword(title: String, message: String) -> String {
    guard !Thread.current.isMainThread else {
        fatalError()
    }
    
    var password = ""
    let semaphore = DispatchSemaphore(value: 0)
    
    DispatchQueue.main.async {
        var vc: UIViewController?
        
        for scene in UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }) {
            guard let scene else {
                continue
            }
            
            if scene.activationState == .foregroundActive {
                if #available(iOS 15.0, *) {
                    vc = scene.keyWindow?.rootViewController?.presentedViewController ?? scene.keyWindow?.rootViewController
                } else {
                    vc = scene.windows.first?.rootViewController?.presentedViewController ?? scene.windows.first?.rootViewController
                }
                break
            }
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: "No \(title.lowercased())", style: .cancel, handler: { _ in
            password = ""
            semaphore.signal()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            password = alert.textFields?.first?.text ?? ""
            semaphore.signal()
        }))
        
        vc?.present(alert, animated: true)
    }
    
    semaphore.wait()
    
    return password
}
