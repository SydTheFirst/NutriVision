import SwiftUI
import ARKit
import Vision
import SceneKit

struct ARCameraView: UIViewRepresentable {
    @Binding var detectedIngredients: [Ingredient]
    
    // Nutrition totals
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session.delegate = context.coordinator
        view.scene = SCNScene()
        view.automaticallyUpdatesLighting = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        view.session.run(configuration)
        
        context.coordinator.sceneView = view
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.updateChartIfNeeded(
            ingredients: detectedIngredients,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARCameraView
        weak var sceneView: ARSCNView?
        
        private var requests = [VNRequest]()
        private var chartNode: SCNNode?
        private var hasPlacedChart = false
        
        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            setupVision()
        }
        
        // MARK: - Vision
        private func setupVision() {
            guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc"),
                  let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
                print("❌ Failed to load ML model")
                return
            }
            
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                self?.handleDetections(results)
            }
            
            request.imageCropAndScaleOption = .scaleFill
            self.requests = [request]
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: frame.capturedImage,
                orientation: .right
            )
            try? handler.perform(self.requests)
        }
        
        private func handleDetections(_ observations: [VNRecognizedObjectObservation]) {
            DispatchQueue.main.async {
                for observation in observations {
                    let label = observation.labels.first?.identifier ?? ""
                    guard !label.isEmpty else { continue }
                    
                    if !self.parent.detectedIngredients.contains(where: { $0.name == label }) {
                        let ingredient = Ingredient(aiDetectedName: label)
                        self.parent.detectedIngredients.append(ingredient)
                    }
                }
            }
        }
        
        // MARK: - Chart logic
        func updateChartIfNeeded(
            ingredients: [Ingredient],
            calories: Double,
            protein: Double,
            carbs: Double,
            fats: Double
        ) {
            guard !ingredients.isEmpty else { return }
            
            // Place chart only once
            if !hasPlacedChart {
                placeChart(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fats: fats
                )
                hasPlacedChart = true
            }
        }
        
        private func placeChart(
            calories: Double,
            protein: Double,
            carbs: Double,
            fats: Double
        ) {
            guard let sceneView else { return }
            
            // Remove old chart
            chartNode?.removeFromParentNode()
            
            let root = SCNNode()
            
            let values = [
                (calories, UIColor.orange),
                (protein, UIColor.green),
                (carbs, UIColor.purple),
                (fats, UIColor.red)
            ]
            
            for (index, item) in values.enumerated() {
                let height = max(0.05, Float(item.0) * 0.002)
                
                let bar = SCNBox(
                    width: 0.04,
                    height: CGFloat(height),
                    length: 0.04,
                    chamferRadius: 0.005
                )
                
                bar.firstMaterial?.diffuse.contents = item.1
                
                let node = SCNNode(geometry: bar)
                node.position = SCNVector3(
                    Float(index) * 0.06 - 0.09,
                    height / 2,
                    0
                )
                
                root.addChildNode(node)
            }
            
            // Position chart in front of camera
            if let camera = sceneView.pointOfView {
                let transform = camera.transform
                let position = SCNVector3(
                    transform.m41,
                    transform.m42 - 0.15,
                    transform.m43 - 0.4
                )
                root.position = position
            }
            
            sceneView.scene.rootNode.addChildNode(root)
            chartNode = root
        }
    }
}
