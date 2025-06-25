//
//  GitShutdownNotification.swift
//  Pyto
//
//  Created by Emma on 15-02-25.
//  Copyright © 2025 Emma Labbé. All rights reserved.
//

import Foundation

let GitShutdownNotificationName = Notification.Name("GitShutdownNotification")

#if !MAIN
@_cdecl("git_send_shutdown_notification") func sendGitShutdownNotification(_ repoPath: UnsafePointer<CChar>) {
    let repoStr = String(cString: repoPath)
    let curDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    DispatchQueue.main.async {
        NotificationCenter.default.post(Notification(name: GitShutdownNotificationName, object: URL(string: repoStr, relativeTo: curDir)))
    }
}
#endif
