<p align="center">
  <h1 align="center">AutoUpdate</h1>
  <p align="center"> A simple way to update your Mac app.</p>
</p>

## What's AutoUpdate
AutoUpdate is a complete "homemade" update solution for the Beam Mac app.
It's a simple, basic, pure Swift, update solution that works with sandboxed app, and integrates with the CI to generate update feed.

AutoUpdate contains 3 main components:
- `AutoUpdate` framework, and more precisely the `VersionChecker` class, to use in the app to update. It's responsible from checking the update feed (a JSON file), and downloads to disk the update archives.
- `UpdateInstaller` XPC service, which is not sandboxed, and that will perform the update sequence (Unzip, unquarantine, signature comparison, installation…).
- `AppFeedBuilder`, a Swift CLI app used to get the current update feed, and to add a new release to it.

## Documentation

### VersionChecker

You can simply init a VersionChecker instance by providing the URL of an update feed, and keep a reference to it to use AutoUpdate.

```swift
if let feed = URL(string: Configuration.updateFeedURL) {
    self.versionChecker = VersionChecker(feedURL: feed, autocheckEnabled: true)
}
```
The you can observe the `state` property to know what's going on (it a `@Published` property, easy to observe from SwiftUI). Then, you'll be able to `checkForUpdates()`, or `performUpdateIfAvailable()`. 

### UpdateInstaller features
The UpdateInstaller XPC service provides a unique public method, to initiate update installation, as seen in the `UpdateInstallerProtocol`.

```swift
@objc public protocol UpdateInstallerProtocol {

    /// Gives information to the XPC service to handle unarchiving and installation of the update from outside the sandbox
    /// - Parameters:
    ///   - archiveURL: Archive URL on the file system
    ///   - binaryToReplaceURL: Current binary URL (the one to be updated)
    ///   - appPID: Current binary UNIX PID, used to watch for the app relaunch
    ///   - reply: callback when the XPC service finished the update. Contains a Bool for install success, a String? for error rawValue, and path for updated app if available
    func installUpdate(archiveURL: URL, binaryToReplaceURL: URL, appPID: Int32, reply: @escaping (Bool, String?, String?) -> Void)
}
```
It will then go through the install sequence:
- Unarchive the update's `.zip` file
- Unquarantine the downloaded app
- Check the app signature the make sure that they are issued from the same developer team
- Check for app renames to make sure we can install the update (or fallback to a just move the updated app in the Downloads folder)
- Make sure we can replace the existing app where it sits (probably the Application folder), or fallback to a just move the updated app in the Downloads folder. For example if the user is not an administrator.
- Lastly, swap the outdated and updated apps and relaunch the app


### AppFeedBuilder usage
```cli
USAGE: app-feed-builder <feed-url> <version-name> <version> <build-number> <download-url> [--release-notes-url <release-notes-url>] [--verbose] [--output-path <output-path>]

ARGUMENTS:
  <feed-url>              The feed URL
  <version-name>          The new version name
  <version>               The new version string (like "2.0")
  <build-number>          The new version build number (should be String, can
                          be "dotted")
  <download-url>          The new version download URL. Must be an https URL
                          pointing to a .zip file

OPTIONS:
  --release-notes-url <release-notes-url>
                          The release notes URL to open on a tap on the release
  --verbose
  --output-path <output-path>
                          Specifies the path to write the file
  -h, --help              Show help information.
```

#### App Update Feed example
```json
[
   {
      "downloadURL":"https:\/\/github.com\/eLud\/update-proto\/raw\/main\/BeamUpdaterProto_v1.1.zip",
      "publicationDate":641738100,
      "releaseNoteURL":"https:\/\/raw.githubusercontent.com\/eLud\/update-proto\/main\/feed.json",
      "versionName":"Version 1.1",
      "buildNumber":"20230112.121854",
      "version":"1.1"
   },
   {
      "buildNumber":"20230127.171926",
      "versionName":"Beam 2.0",
      "version":"2.0",
      "releaseNoteURL":"https:\/\/raw.githubusercontent.com\/eLud\/update-proto\/main\/feed.json",
      "downloadURL":"https:\/\/github.com\/eLud\/update-proto\/raw\/main\/BeamUpdaterProto_v1.1.zip",
      "publicationDate":727361375.336093
   }
]
```
