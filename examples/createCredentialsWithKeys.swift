//
//  createCredentialsWithKeys.swift
//  git
//
//  Created by Emma on 04-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import Foundation

/// Returns the path of a key to use for connecting to the given host.
func getKeysForHost(_ _url: String) -> String? {
    guard let url = URL(string: _url) else {
        return nil
    }
    
    guard let host = url.host else {
        return nil
    }
    
    let user = url.user ?? ""
    
    var identityFiles = [String]()
    if let config = try? ssh.Config.load(path: "~/Documents/.ssh/config") {
        let server: ssh.Properties
        if config.hosts.contains(where: { $0.alias.components(separatedBy: " ").contains(user+"@"+host) }) {
            server = config.resolve(for: user+"@"+host)
        } else {
            server = config.resolve(for: host)
        }
        identityFiles = server.identityFile ?? []
    }
    
    var exist = false
    for file in identityFiles.map({ NSString(string: $0).expandingTildeInPath }) {
        if FileManager.default.fileExists(atPath: file) {
            exist = true
            break
        }
    }
    
    if identityFiles.isEmpty || !exist {
        identityFiles = ["id_rsa", "id_dsa", "id_ed25519"].map({
            "~/Documents/.ssh/\($0)"
        })
    }
    
    var identityFile: String?
    for file in identityFiles.map({ NSString(string: $0).expandingTildeInPath }) {
        if FileManager.default.fileExists(atPath: file) {
            identityFile = file
            break
        }
    }
    
    return identityFile
}

@_cdecl("git_create_credentials_with_keys") func createCredentialsWithKeys(_ out: UnsafeMutablePointer<UnsafeMutablePointer<git_credential>?>!, _ _username: UnsafePointer<CChar>!, _ _url: UnsafePointer<CChar>!) -> git_error_code {
    
    let username = String(cString: _username)
    let url = String(cString: _url)
    
    guard let keys = getKeysForHost(url) else {
        if let password = ask(title: "Password", message: "Enter SSH password", isPassword: true) {
            return git_error_code(rawValue: git_credential_userpass_plaintext_new(out, "\(username)", "\(password)"))
        } else {
            return git_error_code(-1);
        }
    }
    
    if let password = ask(title: "Passphrase", message: "Enter passphrase for '\(NSString(string: keys).lastPathComponent)'.", isPassword: true) {
        return git_error_code(rawValue: git_credential_ssh_key_new(out, "\(username)", "\(keys).pub", "\(keys)", password))
    } else {
        return git_error_code(-1);
    }
}
