//
//  UpdateInstaller.swift
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation

class UpdateInstaller: UpdateInstallerProtocol {
    
    func upperCaseString(_ string: String, withReply reply: @escaping (String) -> Void) {
        let response = string.uppercased()
                reply(response)
    }
}
