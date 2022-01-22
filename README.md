<img width="256" alt="Streamy_256@2x" src="https://user-images.githubusercontent.com/78187398/150638285-b8ebda70-286a-4096-a24c-16a606c4e4c9.png">

#  MetaWear Swift Combine SDK Demo Project

For an interactive code walkthrough of this barebones project, view the SDK's documentation in Xcode. Remember that the iOS simulator cannot use Bluetooth, so run this on macOS or actual iOS devices.

### Quick Guide

#### UseCases

- The basics of using the Combine SDK to discover, connect, and manage devices are in `Shared/Logic/Discovery`. 
- The basics of logging specific sensors and downloading data are in `Shared/Logic/SensorRecording. 
- Any SDK commands more than one line are in `Shared/Logic/SDKActions.swift`.

#### UI

This demo app uses SwiftUI. Views and logic are decoupled to make is easy for you to expand or reuse this app while toying with the SDK.

- **Views observe generic ObservableObjects using `KeyPaths`.** A ViewModel object defines these KeyPaths and closures. A separate mapping object configures a ViewModel for a concrete UseCase.

- **Views point to opaque other views, not actual implementations.** "Router views" in `UI/Views.swift` determine which specific implementations to configure and show for a given component (e.g., show the two or three pane implementation).

- **A factory object vends any dependencies** while the "router view" decides or prepares which view to show.
