//
//  SelectPhotosViewController.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa
import RealityKit

@MainActor
final class SelectPhotosViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard PhotogrammetrySession.isSupported else {
            fatalError()
        }
    }
    
    @IBAction func buttonDidTrigger(_ sender: NSButton) {
        let openPanel: NSOpenPanel = .init()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.canSelectHiddenExtension = true
        
        let response: NSApplication.ModalResponse = openPanel.runModal()
        
        guard response == .OK,
              let url: URL = openPanel.urls.first
        else {
            return
        }
        
        let fileManager: FileManager = .default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path(), isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            fatalError()
        }
        
        //
        
        let progressViewController: ProgressViewController = storyboard?.instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
        
        var configuration: PhotogrammetrySession.Configuration = .init(checkpointDirectory: Constant.checkpointDirectory)
        configuration.isObjectMaskingEnabled = true // TODO: 한 번 꺼보기
        configuration.sampleOrdering = .sequential
        configuration.featureSensitivity = .normal
        
        assert(url.startAccessingSecurityScopedResource())
        let session: PhotogrammetrySession = try! .init(input: url, configuration: configuration)
        
        try! session.process(requests: [.pointCloud, .bounds, .poses])
        
        progressViewController.session = session
        
        //
        
        let homeViewController: HomeViewController = parent as! HomeViewController
        
        progressViewController.view.frame = homeViewController.view.bounds
        progressViewController.view.autoresizingMask = [.width, .height]
        homeViewController.view.addSubview(progressViewController.view)
        homeViewController.addChild(progressViewController)
        
        homeViewController.transition(
            from: self,
            to: progressViewController,
            options: .slideLeft
        ) { [self] in
            view.removeFromSuperview()
            removeFromParent()
        }
    }
}
