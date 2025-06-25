//
//  pathFromURL.swift
//  git
//
//  Created by Emma on 03-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import Foundation

/// Returns a default path where to save a given cloned repo.
@_cdecl("git_path_from_url") func pathFromURL(_ _url: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    let urlString = String(cString: _url)
    guard let url = URL(string: urlString) else {
        return nil
    }
    
    let name = url.deletingPathExtension().lastPathComponent
    let path = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(name)
    let cPath = UnsafeMutablePointer<CChar>(mutating: (path as NSString).utf8String)
    return cPath
}
