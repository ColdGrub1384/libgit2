//
//  ask.swift
//  git
//
//  Created by Emma on 04-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import UIKit

@_cdecl("git_ask_password")
func gitAskPassword(out: UnsafeMutablePointer<UnsafeMutablePointer<CChar>>, title: UnsafePointer<CChar>, message: UnsafePointer<CChar>) -> Int {
    guard let password = ask(title: String(cString: title), message: String(cString: message), isPassword: true) else {
        return -1
    }
    guard let cPassword = UnsafeMutablePointer<CChar>(mutating: (password as NSString).utf8String) else {
        return -1
    }
    out.pointee = cPassword
    return 0
}

@_cdecl("git_ask_input")
func gitAskInput(out: UnsafeMutablePointer<UnsafeMutablePointer<CChar>>, title: UnsafePointer<CChar>, message: UnsafePointer<CChar>) -> Int {
    guard let input = ask(title: String(cString: title), message: String(cString: message), isPassword: false) else {
        return -1
    }
    guard let cInput = UnsafeMutablePointer<CChar>(mutating: (input as NSString).utf8String) else {
        return -1
    }
    out.pointee = cInput
    return 0
}

fileprivate struct Password {
    
    @MainActor static var password: String?
}

/// Asks for input in an alert view controller.
func ask(title: String, message: String, isPassword: Bool) -> String? {
    
    #if os(watchOS)
    nil
    #else
    
    guard !Thread.current.isMainThread else {
        fatalError()
    }

    let semaphore = DispatchSemaphore(value: 0)
    
    DispatchQueue.main.async {
        var vc: UIViewController?
        
        for scene in UIApplication.shared.connectedScenes.map({ $0 as? UIWindowScene }) {
            guard let scene else {
                continue
            }
            
            if scene.activationState == .foregroundActive {
		if #available(iOS 15.0, tvOS 15.0, *) {
                    vc = scene.keyWindow?.rootViewController?.presentedViewController ?? scene.keyWindow?.rootViewController
                } else {
                    vc = scene.windows.first?.rootViewController?.presentedViewController ?? scene.windows.first?.rootViewController
                }
                
                if vc?.presentedViewController != nil {
                    vc = vc?.presentedViewController
                }
                
                break
            }
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField {
            $0.isSecureTextEntry = isPassword
            $0.placeholder = title
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
	    Password.password = nil
            semaphore.signal()
        }))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
	    Password.password = alert.textFields?.first?.text ?? ""
            semaphore.signal()
        }))
        
        vc?.present(alert, animated: true)
    }
    
    semaphore.wait()
    
    var password: String?
    DispatchQueue.main.sync {
	password = Password.password
    }
    
    return password
    #endif
}
