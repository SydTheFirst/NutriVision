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
        // Enable plane detection to improve distance accuracy for raycasting
        configuration.planeDetection = [.horizontal]
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
        
        private let nutritionService = NutritionService()
        private var pendingLabels = Set<String>()
        
        private var detectedIngredientNames = Set<String>()

        init(_ parent: ARCameraView) {
            self.parent = parent
            super.init()
            setupVision()
        }
        
        private func setupVision() {
            guard let modelURL = Bundle.main.url(forResource: "food_90_conf", withExtension: "mlmodelc"),
                  let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
                print("Failed to load ML model")
                return
            }

            let request = VNCoreMLRequest(model: visionModel) { _, _ in }
            request.imageCropAndScaleOption = .scaleFill
            self.requests = [request]
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: frame.capturedImage,
                orientation: .right
            )
            try? handler.perform(self.requests)

            if let results = self.requests.first?.results as? [VNRecognizedObjectObservation] {
                handleDetections(results)
            }
        }

        private func handleDetections(
            _ observations: [VNRecognizedObjectObservation]
        ) {
            var weightsPerLabel: [String: Double] = [:]

            for observation in observations {
                guard let label = observation.labels.first?.identifier else { continue }
                guard observation.confidence > 0.5 else { continue }
                
                // Use the raycast-based weight estimation
                let weight = estimateWeight(for: observation)
                weightsPerLabel[label, default: 0.0] += weight
            }

            guard !weightsPerLabel.isEmpty else { return }

            DispatchQueue.main.async {
                for (label, frameWeight) in weightsPerLabel {

                    if self.detectedIngredientNames.contains(label) {
                        if let index = self.parent.detectedIngredients.firstIndex(where: { $0.name == label }) {
                            self.parent.detectedIngredients[index].areaScore =
                                max(self.parent.detectedIngredients[index].areaScore,
                                    CGFloat(frameWeight))
                        }
                    } else {
                        self.detectedIngredientNames.insert(label)

                        var ingredient = Ingredient(aiDetectedName: label)
                        ingredient.areaScore = CGFloat(frameWeight)
                        self.parent.detectedIngredients.append(ingredient)

                        self.fetchNutritionForLabel(label, weight: frameWeight)
                    }
                }
            }
        }
        
        private func estimateWeight(for observation: VNRecognizedObjectObservation) -> Double {
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else { return 150.0 }
            
            let centerPoint = CGPoint(x: observation.boundingBox.midX, y: 1 - observation.boundingBox.midY)
            let results = sceneView.raycastQuery(from: centerPoint, allowing: .estimatedPlane, alignment: .any)
            
            if let query = results, let result = sceneView.session.raycast(query).first {
                let distance = simd_distance(result.worldTransform.columns.3, frame.camera.transform.columns.3)
                
                // Calculate physical width in cm using pinhole model
                let physicalWidth = Double(distance) * Double(observation.boundingBox.width) * 100
                
                // Volume Estimation (Cylinder model for plates/pizza/meals)
                let radius = physicalWidth / 2
                let area = Double.pi * pow(radius, 2)
                let thickness = 2.0 // Assume 2cm average food height
                let volume = area * thickness
                
                let weight = volume * 1.0 // Density 1.0g/cm3
                return max(50, min(weight, 1500)) // Clamped between 50g and 1.5kg
            }
            
            return 150.0
        }
        
        private func fetchNutritionForLabel(_ label: String, weight: Double) {
            guard !pendingLabels.contains(label) else { return }
            pendingLabels.insert(label)
            
            // Build the query (e.g., "350g pizza")
            let query = "\(Int(weight))g \(label)"
            
            Task {
                do {
                    if let ingredient = try await nutritionService.fetchNutrition(for: query) {
                        await MainActor.run {
                            if let index = self.parent.detectedIngredients.firstIndex(where: { $0.name == label }) {
                                var updated = ingredient
                                updated.areaScore = CGFloat(weight)
                                self.parent.detectedIngredients[index] = updated
                            }
                            self.pendingLabels.remove(label)
                        }
                    }
                } catch {
                    print("Nutrition API Error: \(error)")
                    await MainActor.run { self.pendingLabels.remove(label) }
                }
            }
        }

        func updateChartIfNeeded(ingredients: [Ingredient], calories: Double, protein: Double, carbs: Double, fats: Double) {
            guard !ingredients.isEmpty else { return }
            placeChart(calories: calories, protein: protein, carbs: carbs, fats: fats)
            hasPlacedChart = true
        }

        private func placeChart(calories: Double, protein: Double, carbs: Double, fats: Double) {
            guard let sceneView else { return }
            chartNode?.removeFromParentNode()
            let root = SCNNode()
            
            let values = [
                (calories, UIColor.orange),
                (protein, UIColor.green),
                (carbs, UIColor.purple),
                (fats, UIColor.red)
            ]
            
            for (index, item) in values.enumerated() {
                let height = max(0.02, Float(item.0) * 0.0005)
                let bar = SCNBox(width: 0.04, height: CGFloat(height), length: 0.04, chamferRadius: 0.005)
                bar.firstMaterial?.diffuse.contents = item.1
                let node = SCNNode(geometry: bar)
                node.position = SCNVector3(Float(index) * 0.06 - 0.09, height / 2, 0)
                root.addChildNode(node)
            }
            
            if let camera = sceneView.pointOfView {
                let transform = camera.transform
                // Position the chart 15cm below and 40cm in front of the camera
                let position = SCNVector3(transform.m41, transform.m42 - 0.15, transform.m43 - 0.4)
                root.position = position
            }
            
            sceneView.scene.rootNode.addChildNode(root)
            chartNode = root
        }
    }
}
