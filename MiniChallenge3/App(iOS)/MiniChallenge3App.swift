//
//  MiniChallenge3App.swift
//  MiniChallenge3
//
//  Created by Rangga Saputra on 29/07/24.
//

import SwiftUI
import CloudKit

@main
struct MiniChallenge3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        let container = CKContainer(identifier: "iCloud.com.dandenion.MiniChallenge3")
        
        WindowGroup {
//            iOSMainView()
//            ContentView() // Frontend
            
            
            DummyCloudKit(userVm: UserAppManager(container: container), reportVm: ReportManager(container: container))
        }
    }
}
