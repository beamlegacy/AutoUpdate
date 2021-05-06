//
//  UpdateInstallerProtocol.h
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation
// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.

@objc public protocol UpdateInstallerProtocol {
    func installUpdate(archiveURL: URL, binaryToReplaceURL: URL, reply: @escaping (String) -> Void)
}

enum UpdateInstallerError: String, Error {
    case genericUnzipError
    case unzippedContentNotFound
    case archiveContentNotCoherent
    case failedToUnquarantine
    case signatureFailed
}
