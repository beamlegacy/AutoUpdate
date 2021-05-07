//
//  UpdateInstallerProtocol.h
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation
// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.

@objc public protocol UpdateInstallerProtocol {


    /// Gives information to the XPC service to handle unarchiving and installation of the update from outside the sandbox
    /// - Parameters:
    ///   - archiveURL: Archive URL on the file system
    ///   - binaryToReplaceURL: Current binary URL (the one to be updated)
    ///   - appPID: Current binary UNIX PID, used to watch for the app relaunch
    ///   - reply: callback when te XPC service finished the update
    func installUpdate(archiveURL: URL, binaryToReplaceURL: URL, appPID: Int32, reply: @escaping (Bool, String?) -> Void)
}

enum UpdateInstallerError: String, Error {
    case genericUnzipError
    case unzippedContentNotFound
    case archiveContentNotCoherent
    case failedToUnquarantine
    case signatureFailed
    case appReplacementFailed
}
