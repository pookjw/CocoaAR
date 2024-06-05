//
//  ProgressViewController.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa
import RealityKit
import UniformTypeIdentifiers

@MainActor
final class ProgressViewController: NSViewController {
    @IBOutlet @ViewLoading private var label: NSTextField
    @IBOutlet @ViewLoading private var progressIndicator: NSProgressIndicator
    
    @ViewLoading var session: PhotogrammetrySession
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task = .init {
            do {
                var bounds: BoundingBox?
                var pointCloud: PhotogrammetrySession.PointCloud?
                var poses: PhotogrammetrySession.Poses?
                
                for try await output in session.outputs {
                    label.stringValue = output.localizedDescription
                    
                    switch output {
                    case .inputComplete:
                        progressIndicator.doubleValue = .zero
                    case .processingComplete:
                        progressIndicator.doubleValue = progressIndicator.maxValue
                    case .processingCancelled:
                        break
                    case .requestProgress(let request, let fractionComplete):
                        progressIndicator.doubleValue = progressIndicator.maxValue * fractionComplete
                    case .requestComplete(_, let result):
                        switch result {
                        case .bounds(let boundingBox):
                            bounds = boundingBox
                            
                            if let bounds, let pointCloud, let poses {
                                transitToPreviewViewController(bounds: bounds, pointCloud: pointCloud, poses: poses)
                            }
                        case .pointCloud(let _pointCloud):
                            pointCloud = _pointCloud
                            
                            if let bounds, let pointCloud, let poses {
                                transitToPreviewViewController(bounds: bounds, pointCloud: pointCloud, poses: poses)
                            }
                        case .poses(let _poses):
                            poses = _poses
                            
                            if let bounds, let pointCloud, let poses {
                                transitToPreviewViewController(bounds: bounds, pointCloud: pointCloud, poses: poses)
                            }
                        default:
                            break
                        }
                    case .requestError(_, let error):
                        fatalError(String(describing: error))
                    case .invalidSample(let id, let reason):
                        print(reason, id)
                    case .automaticDownsampling:
                        break
                    case .skippedSample(let id):
                        print("Skipped: \(id)")
                    case .requestProgressInfo(_, let progressInfo):
                        print(progressInfo)
                    case .stitchingIncomplete:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                fatalError(String(describing: error))
            }
        }
    }
    
    private func transitToPreviewViewController(
        bounds: BoundingBox,
        pointCloud: PhotogrammetrySession.PointCloud,
        poses: PhotogrammetrySession.Poses
    ) {
        let pointCloudViewController: PreviewViewController = storyboard!.instantiateController(withIdentifier: "PreviewViewController") as! PreviewViewController
        
        pointCloudViewController.session = session
        pointCloudViewController.bounds = bounds
        pointCloudViewController.pointCloud = pointCloud
        pointCloudViewController.poses = poses
        
        let homeViewController: HomeViewController = parent as! HomeViewController
        
        pointCloudViewController.view.frame = homeViewController.view.bounds
        pointCloudViewController.view.autoresizingMask = [.width, .height]
        homeViewController.view.addSubview(pointCloudViewController.view)
        homeViewController.addChild(pointCloudViewController)
        
        homeViewController.transition(
            from: self,
            to: pointCloudViewController,
            options: .slideLeft
        ) { [self] in
            view.removeFromSuperview()
            removeFromParent()
        }
    }
}
