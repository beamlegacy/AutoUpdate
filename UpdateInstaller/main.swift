//
//  main.swift
//  UpdateInstaller
//
//  Created by Ludovic Ollagnier on 04/05/2021.
//

import Foundation

let delegate = UpdateInstallerDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
