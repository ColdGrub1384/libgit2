//
//  authenticateUsingPassword.swift
//  git
//
//  Created by Emma on 04-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import Foundation

/// Returns wether git should authenticate using password instead of keys on the given url.
@_cdecl("git_authenticate_using_password") func authenticateUsingPassword(_ _url: UnsafePointer<CChar>) -> Bool {
    let urlString = String(cString: _url)
    guard let url = URL(string: urlString) else {
        return false
    }
    
    guard let host = url.host else {
        return false
    }
    
    let user = url.user ?? ""
    
    if let config = try? ssh.Config.load(path: "~/Documents/.ssh/config") {
        let server: ssh.Properties
        if config.hosts.contains(where: { $0.alias.components(separatedBy: " ").contains(user+"@"+host) }) {
            server = config.resolve(for: user+"@"+host)
        } else {
            server = config.resolve(for: host)
        }
        return server.pubkeyAuthentication != .yes && server.passwordAuthentication != .no
    }
    
    return false
}
