//
//  Constant.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Foundation

@MainActor
enum Constant {
    static let checkpointDirectory: URL = .temporaryDirectory
        .appending(component: "CocoaAR", directoryHint: .isDirectory)
        .appending(component: "Checkpoint", directoryHint: .isDirectory)
}
