//
//  MyAppWatchApp.swift
//  MyAppWatch Watch App
//
//  Created by Siegmund Murer on 11.11.26.
//

import SwiftUI

@main
struct MyAppWatch_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
