//
//  PreviewViewController.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa
import RealityKit
import QuickLookUI
import ObjectiveC

@MainActor fileprivate let urlsKey: UnsafeMutableRawPointer = .allocate(byteCount: 1, alignment: 1)

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
    private var poseImagesTask: Task<Void, Never>?
    
    deinit {
        poseImagesTask?.cancel()
    }
    
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
        
        let poses: PhotogrammetrySession.Poses = poses
        let scene: Scene = myARView.scene
        let poseImagesAnchor: AnchorEntity = .init(world: .zero)
        
        scene.addAnchor(poseImagesAnchor)
        
        // do not capture `self`!
        poseImagesTask = .init { @MainActor in
            await withDiscardingTaskGroup { group in
                for (index, url) in poses.urlsBySample {
                    guard let pose: PhotogrammetrySession.Pose = poses.posesBySample[index] else {
                        print("Skipped: \(index)")
                        return
                    }
                    
                    group.addTask {
                        let image: NSImage = .init(contentsOf: url)!
                        
                        let textureResource: TextureResource = try! await TextureResource
                            .generateAsync(
                                from: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!,
                                options: .init(semantic: .raw)
                            )
                            .values
                            .first { _ in true }!
                        
                        await MainActor.run {
                            var material: UnlitMaterial = .init()
                            material.color = .init(tint: .white, texture: .init(textureResource))
                            
                            let poseImageEntity: ModelEntity = .init(
                                mesh: .generateBox(width: 0.1, height: 0.1, depth: .zero),
                                materials: [
                                    material
                                ]
                            )
                            
                            poseImageEntity.position = pose.translation
                            poseImageEntity.transform = pose.transform
                            poseImageEntity.transform.rotation = pose.rotation
                            
                            poseImageEntity.components.set(ImageURLComponent(fileURL: url))
                            poseImageEntity.components.set(CollisionComponent(shapes: [.generateBox(width: 0.1, height: 0.1, depth: .zero)]))
                            
                            poseImagesAnchor.addChild(poseImageEntity)
                        }
                    }
                }
            }
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
    
    @IBAction private func clickGestureRecognizerDidTrigger(_ sender: NSClickGestureRecognizer) {
        let location: NSPoint = sender.location(in: myARView)
        
        guard let entity: Entity = myARView.entity(at: location) else {
            return
        }
        
        guard let imageURLComponent: ImageURLComponent = entity.components[ImageURLComponent.self] else {
            return
        }
        
        let urls: [URL] = try! FileManager.default.contentsOfDirectory(at: imageURLComponent.fileURL.deletingLastPathComponent(), includingPropertiesForKeys: nil)
        
        let previewPanel: QLPreviewPanel = .shared()
        
        objc_setAssociatedObject(previewPanel, urlsKey, urls, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        previewPanel.makeKeyAndOrderFront(nil)
        previewPanel.dataSource = self
        previewPanel.currentPreviewItemIndex = urls.firstIndex(of: imageURLComponent.fileURL)!
        previewPanel.reloadData()
    }
}

extension PreviewViewController: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        let urls: [URL] = objc_getAssociatedObject(panel!, urlsKey) as! [URL]
        return urls.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        let urls: [URL] = objc_getAssociatedObject(panel!, urlsKey) as! [URL]
        return urls[index] as NSURL
    }
}

fileprivate struct ImageURLComponent: Component {
    let fileURL: URL
}
