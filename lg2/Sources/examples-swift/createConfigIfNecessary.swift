//
//  createConfigIfNecessary.swift
//  git
//
//  Created by Emma on 05-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import Foundation

@_cdecl("git_create_config_if_necessary") func createConfigIfNecessary() {
    let gitConfig = ProcessInfo.processInfo.environment["GIT_CONFIG"] ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".config/git/config").path
    
    guard !FileManager.default.fileExists(atPath: gitConfig) else {
        return
    }
    
    let dir = URL(fileURLWithPath: gitConfig).deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    if !FileManager.default.fileExists(atPath: gitConfig) {
        try? """
        [user]
            name = Pyto
            email = support@pyto.app
        
        [init]
            defaultBranch = main
        """.write(to: URL(fileURLWithPath: gitConfig), atomically: false, encoding: .utf8)
    }
}
