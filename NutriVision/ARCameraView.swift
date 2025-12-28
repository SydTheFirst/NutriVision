//
//  ARCameraView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 27/12/2025.
//

import SwiftUI
import ARKit
import Vision

struct ARCameraView: UIViewRepresentable {
    @Binding var detectedIngredients: [Ingredient]
    
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session.delegate = context.coordinator
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        view.session.run(configuration)
        
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARCameraView
        private var requests = [VNRequest]()
        
        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            setupVision()
        }
        
        private func setupVision() {
            guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc"),
                  let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
                print("Failed to load model")
                return
            }
            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    self?.handleDetections(results)
                }
            }
            request.imageCropAndScaleOption = .scaleFill
            self.requests = [request]
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .right)
            try? handler.perform(self.requests)
        }
        
        private func handleDetections(_ observations: [VNRecognizedObjectObservation]) {
            DispatchQueue.main.async {
                for observation in observations {
                    let label = observation.labels[0].identifier
                    
                    // Only add if not already in the list to avoid duplicates
                    if !self.parent.detectedIngredients.contains(where: { $0.name == label }) {
                        // Creating a placeholder ingredient based on your AI Detected init
                        let newIngredient = Ingredient(aiDetectedName: label)
                        self.parent.detectedIngredients.append(newIngredient)
                    }
                }
            }
        }
    }
}

/*let newMeal = Meal(
 userID: uid,
 name: finalName,
 isSaved: true,
 ingredients: detectedIngredients
)*/
