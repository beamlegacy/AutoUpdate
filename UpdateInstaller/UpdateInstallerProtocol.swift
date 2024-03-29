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
    ///   - reply: callback when te XPC service finished the update. Contains a Bool for install success, a String? for error rawValue, and path for updated app if available
    func installUpdate(archiveURL: URL, binaryToReplaceURL: URL, appPID: Int32, reply: @escaping (Bool, String?, String?) -> Void)
}

enum UpdateInstallerError: String, Error {
    case genericUnzipError
    case unzippedContentNotFound
    case archiveContentNotCoherent
    case failedToUnquarantine
    case signatureFailed
    case appReplacementFailed
    case existingAppAtDestination
    case diskPermissionError

    var localizedErrorString: String {
        switch self {
        case .genericUnzipError:
            return NSLocalizedString("Failed to unarchive update", comment: "")
        case .unzippedContentNotFound:
            return NSLocalizedString("Failed locate app in update", comment: "")
        case .archiveContentNotCoherent:
            return NSLocalizedString("Invalid update content", comment: "")
        case .failedToUnquarantine:
            return NSLocalizedString("Unable to unquarantine update", comment: "")
        case .signatureFailed:
            return NSLocalizedString("Update signature mismatch", comment: "")
        case .appReplacementFailed:
            return NSLocalizedString("Unable to move update to destination", comment: "")
        case .existingAppAtDestination:
            return NSLocalizedString("Another app exists with the name of the update. You could try moving the app manually.", comment: "")
        case .diskPermissionError:
            return NSLocalizedString("We can't write in the update destination folder. You could try moving the app manually.", comment: "")
        }
    }
}
