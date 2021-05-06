//
//  VersionChecker.swift
//  BeamUpdaterProto
//
//  Created by Ludovic Ollagnier on 03/05/2021.
//

import Foundation
import Combine

class VersionChecker: ObservableObject {

    enum VersionCheckerError: Error {
        case checkFailed
        case noUpdates
    }

    enum State: Equatable {
        case neverChecked
        case checking
        case checked(lastCheck: Date)
        case error(errorDesc: String)
        case downloading(progress: Progress)
        case installing
    }

    var mockData: Data?
    var feedURL: URL?

    @Published var newRelease: AppRelease?
    @Published var state: State

    init(mockData: Data) {
        self.mockData = mockData
        self.state = .neverChecked
    }

    init(feedURL: URL) {
        self.feedURL = feedURL
        self.state = .neverChecked
    }

    func checkForUpdates() {
        state = .checking

        checkRemoteUpdates { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let latest):
                    self.newRelease = latest
                    self.state = .checked(lastCheck: Date())
                case .failure(let error):
                    self.newRelease = nil
                    if error == .noUpdates {
                        self.state = .checked(lastCheck: Date())
                    } else {
                        self.state = .error(errorDesc: "\(error)")
                    }
                }
            }
        }
    }

    var cancellable: AnyCancellable?
    var downloadTask: URLSessionDownloadTask?

    func downloadNewestRelease() {

        guard let release = newRelease else { return }

        let session = URLSession.shared
        downloadTask = session.downloadTask(with: release.downloadURL) { fileURL, response, error in
            let fileManager = FileManager.default

            guard error == nil,
                  let fileURL = fileURL,
                  let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    self.state = .error(errorDesc: error?.localizedDescription ?? "An error occured")
                }
                return
            }

            let finalURL = appSupportURL.appendingPathComponent("\(release.downloadURL.lastPathComponent)")
            try? fileManager.moveItem(at: fileURL, to: finalURL)
            DispatchQueue.main.async {
                self.state = .installing
                self.processInstallation()
            }
        }

        downloadTask?.resume()
        cancellable = downloadTask!
            .publisher(for: \.progress)
            .receive(on: RunLoop.main)
            .sink { value in
                self.objectWillChange.send()
                self.state = .downloading(progress: value)
            }

        self.state = .downloading(progress: downloadTask!.progress)
    }

    private func processInstallation() {
        let connection = NSXPCConnection(serviceName: "com.tectec.UpdateInstaller")
        connection.remoteObjectInterface = NSXPCInterface(with: UpdateInstallerProtocol.self)
        connection.resume()

        let service = connection.remoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? UpdateInstallerProtocol

        service?.upperCaseString("hello XPC") { response in
            print("Response from XPC service:", response)
        }
    }

    private func checkRemoteUpdates(completion: @escaping (Result<AppRelease, VersionCheckerError>)->()) {
        let decoder = JSONDecoder()
        if let mock = mockData {
            DispatchQueue.global(qos: .userInitiated).async {
                sleep(1)
                // Get current app version
                // Compare to the feed's highest version
                var version = try? decoder.decode([AppRelease].self, from: mock)
                version?.sort(by: >)
                guard let highestVersion = version?.first else {
                    completion(.failure(.noUpdates))
                    return
                }

                let compareToCurrent = self.currentAppVersion().versionCompare(highestVersion.version)

                if compareToCurrent == .orderedAscending {
                    completion(.success(highestVersion))
                    return
                } else {
                    completion(.failure(.noUpdates))
                    return
                }
            }
        } else {
            //Get the real data from the real feed
            fetchServerData { data in

            }
            
            completion(.failure(.checkFailed))
        }
    }

    private func fetchServerData(completion: @escaping (Data)->()) {
        
    }

    func currentAppVersion() -> String {
        guard let infos = Bundle.main.infoDictionary,
              let version = infos["CFBundleShortVersionString"] as? String else { fatalError("Cant' get apps version from CFBundleShortVersionString key in Info.plist")
        }

        return version
    }
}
