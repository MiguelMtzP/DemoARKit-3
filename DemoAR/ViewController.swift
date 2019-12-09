//
//  ViewController.swift
//  DemoAR
//
//  Created by Francisco on 12/8/19.
//  Copyright © 2019 Francisco. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import simd
import SceneKit

class ViewController: UIViewController {
    @IBOutlet var arView: ARView!
    @IBOutlet weak var coachingOverlay: ARCoachingOverlayView!
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
           ".serialSceneKitQueue")
    var isLoadedScene = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        presentCoachingOverlay()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func setupARView(){
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources",
                                                                     bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.detectionImages = referenceImages
        arView.session.delegate = self
        arView.session.run(arConfiguration)
    }
    
    func presentCoachingOverlay() {
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = self
        coachingOverlay.goal = .verticalPlane
        coachingOverlay.activatesAutomatically = false
        self.coachingOverlay.setActive(true, animated: true)
    }
    
    private func loadScene(anchor: ARAnchor){
        Prueba.loadEscenaAsync { [weak self] (result) in
            switch result {
            case .success(let scene):
                guard let self = self else { return }
                guard let object = scene.objecto1 else {return}
                let anchorEntity = AnchorEntity(anchor: anchor)
                anchorEntity.addChild(object)
                self.arView.scene.addAnchor(anchorEntity)
                
                
                
            case .failure(let error):
                print("Unable to load the game with error: \(error.localizedDescription)")
            }
        }
    }
}


extension ViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.arView.session.delegate = self
        }
    }
}


extension ViewController: ARSessionDelegate {
    
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let anchor = anchors.first,
            let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        if !isLoadedScene {
            isLoadedScene = true
            DispatchQueue.main.async {
                self.loadScene(anchor: anchor)
                
                self.coachingOverlay.delegate = nil
                self.coachingOverlay.setActive(false, animated: false)
                self.coachingOverlay.isHidden = true
                
                self.arView.session.delegate = nil
            }
        }
        
    }
    
    

    
    func normalize(_ matrix: float4x4) -> float4x4 {
        var normalized = matrix
        normalized.columns.0 = simd.normalize(normalized.columns.0)
        normalized.columns.1 = simd.normalize(normalized.columns.1)
        normalized.columns.2 = simd.normalize(normalized.columns.2)
        return normalized
    }
}
