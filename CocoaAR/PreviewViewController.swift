//
//  PreviewViewController.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa
import RealityKit

@MainActor
final class PreviewViewController: NSViewController {
    @ViewLoading var session: PhotogrammetrySession
    @ViewLoading var bounds: BoundingBox
    @ViewLoading var pointCloud: PhotogrammetrySession.PointCloud
    @ViewLoading var poses: PhotogrammetrySession.Poses
    
    @IBOutlet @ViewLoading private var myARView: MyARView
    @IBOutlet @ViewLoading private var widthTextField: NSTextField
    @IBOutlet @ViewLoading private var heightTextField: NSTextField
    @IBOutlet @ViewLoading private var depthTextField: NSTextField
    @ViewLoading private var boxEntity: ModelEntity
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        widthTextField.stringValue = String(bounds.extents.x)
        heightTextField.stringValue = String(bounds.extents.y)
        depthTextField.stringValue = String(bounds.extents.z)
        
        //
        
        let centerAnchor: AnchorEntity = .init(world: .zero)
        myARView.scene.addAnchor(centerAnchor)
        
        //
        
        let boxEntity: ModelEntity = .init(
            mesh: .generateBox(
                width: bounds.extents.x,
                height: bounds.extents.y,
                depth: bounds.extents.z
            ),
            materials: [
                SimpleMaterial(
                    color: .black.withAlphaComponent(0.5),
                    isMetallic: true
                )
            ]
        )
        
        boxEntity.position = bounds.center
        centerAnchor.addChild(boxEntity)
        self.boxEntity = boxEntity
        
        //
        
        for point in pointCloud.points {
            let sphereEntity: ModelEntity = .init(
                mesh: .generateSphere(radius: 0.005),
                materials: [
                    UnlitMaterial(
                        color: .init(
                            red: CGFloat(point.color.x) / 255.0,
                            green: CGFloat(point.color.y) / 255.0,
                            blue: CGFloat(point.color.z) / 255.0,
                            alpha: CGFloat(point.color.w) / 100.0
                        )
                    )
                ]
            )
            
            sphereEntity.position = point.position
            centerAnchor.addChild(sphereEntity)
        }
        
        //
        
        for (index, url) in poses.urlsBySample {
            let pose: PhotogrammetrySession.Pose = poses.posesBySample[index]!
            
            
        }
    }
    
    private func updateBoxBounds(width: Float? = nil, height: Float? = nil, depth: Float? = nil) {
        let width: Float = width ?? boxEntity.model!.mesh.bounds.extents.x
        let height: Float = height ?? boxEntity.model!.mesh.bounds.extents.y
        let depth: Float = depth ?? boxEntity.model!.mesh.bounds.extents.z
        
        boxEntity.model = .init(
            mesh: .generateBox(width: width, height: height, depth: depth),
            materials: [
                SimpleMaterial(
                    color: .black.withAlphaComponent(0.5),
                    isMetallic: true
                )
            ]
        )
    }
    
    @IBAction private func widthTextFieldDidChangeText(_ sender: NSTextField) {
        guard let newWidth: Float = Float(sender.stringValue) else {
            sender.stringValue = String(boxEntity.model!.mesh.bounds.extents.x)
            return
        }
        
        updateBoxBounds(width: newWidth)
    }
    
    @IBAction private func heightTextFieldDidChangeText(_ sender: NSTextField) {
        guard let newHeight: Float = Float(sender.stringValue) else {
            sender.stringValue = String(boxEntity.model!.mesh.bounds.extents.y)
            return
        }
        
        updateBoxBounds(height: newHeight)
    }
    
    @IBAction private func depthTextFieldDidChangeText(_ sender: NSTextField) {
        guard let newDepth: Float = Float(sender.stringValue) else {
            sender.stringValue = String(boxEntity.model!.mesh.bounds.extents.z)
            return
        }
        
        updateBoxBounds(depth: newDepth)
    }
    
    @IBAction private func continueButtonDidTrigger(_ sender: NSButton) {
        let progressViewController: ProgressViewController = storyboard!.instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
        
        progressViewController.session = session
        
        let outputURL: URL = .temporaryDirectory
            .appending(component: "output", directoryHint: .notDirectory)
            .appendingPathExtension(for: .usdz)
        
        let request: PhotogrammetrySession.Request = .modelFile(
            url: outputURL,
            detail: .reduced,
            geometry: .init(orientedBounds: .init(boundingBox: boxEntity.model!.mesh.bounds))
        )
        
        try! session.process(requests: [request])
        
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
