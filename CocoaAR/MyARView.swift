//
//  MyARView.swift
//  CocoaAR
//
//  Created by Jinwoo Kim on 6/5/24.
//

import Cocoa
import RealityKit

@MainActor
final class MyARView: ARView {
    let camera: PerspectiveCamera = .init()
    
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit_MyARView()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit_MyARView()
    }
    
    private func commonInit_MyARView() {
        let panGestureRecogninzer: NSPanGestureRecognizer = .init(target: self, action: #selector(panGestureRecognizerDidTrigger(_:)))
        addGestureRecognizer(panGestureRecogninzer)
        
        //
        
        let resetButton: NSButton = .init(title: "Reset Camera", target: self, action: #selector(resetButtonDidTrigger(_:)))
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20.0),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            resetButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0)
        ])
        
        //
        
        environment.background = .color(.gray)

        let pointLight: PointLight = .init()
        pointLight.light.intensity = 1E4
        
        let lightAnchor: AnchorEntity = .init(world: .zero)
        lightAnchor.addChild(pointLight)
        
        scene.addAnchor(lightAnchor)
        
        //
        
        let planeMesh: MeshResource = .generatePlane(width: 10.0, depth: 10.0)
        let planeMaterial: SimpleMaterial = .init(color: .white, roughness: 0.5, isMetallic: true)
        
        let planeEntity: ModelEntity = .init(mesh: planeMesh, materials: [planeMaterial])
        let planeAnchor: AnchorEntity = .init(world: .zero)
        
        planeAnchor.addChild(planeEntity)
        scene.addAnchor(planeAnchor)
        
        //
        
        let cameraAnchor: AnchorEntity = .init(world: [0.2, 1.0, 1.0])
        cameraAnchor.addChild(camera)
        scene.addAnchor(cameraAnchor)
    }
    
    @objc private func panGestureRecognizerDidTrigger(_ sender: NSPanGestureRecognizer) {
        switch sender.state {
        case .possible:
            break
        case .began:
            camera.components.set(CameraInitialTransformComponent(transform: camera.transform))
            
            let translation: NSPoint = sender.translation(in: sender.view)
            rotateCamera(translation: translation, initialTransform: camera.transform)
        case .changed:
            guard let transformComponent: CameraInitialTransformComponent = camera.components[CameraInitialTransformComponent.self] else {
                return
            }
            
            let translation: NSPoint = sender.translation(in: sender.view)
            rotateCamera(translation: translation, initialTransform: transformComponent.transform)
        case .ended:
            guard let transformComponent: CameraInitialTransformComponent = camera.components[CameraInitialTransformComponent.self] else {
                return
            }
            
            let translation: NSPoint = sender.translation(in: sender.view)
            rotateCamera(translation: translation, initialTransform: transformComponent.transform)
            
            camera.components.remove(CameraInitialTransformComponent.self)
        case .cancelled:
            camera.components.remove(CameraInitialTransformComponent.self)
        case .failed:
            camera.components.remove(CameraInitialTransformComponent.self)
        case .recognized:
            break
        @unknown default:
            break
        }
    }
    
    @objc private func resetButtonDidTrigger(_ sender: NSButton) {
        camera.position = .zero
        camera.transform = .identity
    }
    
    private func rotateCamera(translation: NSPoint, initialTransform: Transform) {
        camera.transform.rotation = initialTransform.rotation * 
            .init(angle: Float(translation.x) * 1E-2, axis: .init(x: .zero, y: 1.0, z: .zero)) *
            .init(angle: -Float(translation.y) * 1E-2, axis: .init(x: 1.0, y: .zero, z: .zero))
        
    }
    
    override func moveRight(_ sender: Any?) {
        camera.position.x += 0.1
    }
    
    override func moveLeft(_ sender: Any?) {
        camera.position.x -= 0.1
    }
    
    override func moveUp(_ sender: Any?) {
        camera.position.z -= 0.1
    }
    
    override func moveDown(_ sender: Any?) {
        camera.position.z += 0.1
    }
}

fileprivate struct CameraInitialTransformComponent: Component {
    let transform: Transform
}

fileprivate struct CameraInitialPositionComponent: Component {
    let position: SIMD3<Float>
}
