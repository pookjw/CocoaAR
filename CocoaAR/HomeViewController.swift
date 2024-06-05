//
//  HomeViewController.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa

@MainActor
final class HomeViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectPhotosViewController: SelectPhotosViewController = storyboard!.instantiateController(withIdentifier: "SelectPhotosViewController") as! SelectPhotosViewController
        selectPhotosViewController.view.frame = view.bounds
        selectPhotosViewController.view.autoresizingMask = [.width, .height]
        view.addSubview(selectPhotosViewController.view)
        addChild(selectPhotosViewController)
    }
}
