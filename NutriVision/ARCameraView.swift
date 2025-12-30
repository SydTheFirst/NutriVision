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
        
        private func setupVision() {
            guard let modelURL = Bundle.main.url(forResource: "food_90_conf", withExtension: "mlmodelc"),
                  let visionModel = try? VNCoreMLModel(for: MLModel(contentsOf: modelURL)) else {
                print("Failed to load ML model")
                return
            }

            let request = VNCoreMLRequest(model: visionModel) { request, _ in
                // Results are handled in session(_:didUpdate:)
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

            if let results = self.requests.first?.results as? [VNRecognizedObjectObservation] {
                handleDetections(results, frame: frame)
            }
        }

        private func handleDetections(
            _ observations: [VNRecognizedObjectObservation],
            frame: ARFrame
        ) {
            DispatchQueue.main.async {
                let camera = frame.camera
                let fx = CGFloat(camera.intrinsics[0][0])
                let fy = CGFloat(camera.intrinsics[1][1])
                let imageWidth = CGFloat(CVPixelBufferGetWidth(frame.capturedImage))
                let imageHeight = CGFloat(CVPixelBufferGetHeight(frame.capturedImage))
                let estimatedDistance: CGFloat = 0.4 // meters

                // Step 1: Compute summed area per label in this frame
                var areasPerLabel: [String: CGFloat] = [:]

                for observation in observations {
                    guard let label = observation.labels.first?.identifier else { continue }

                    // Bounding box in pixels
                    let bbox = observation.boundingBox
                    let bboxWidthPixels = bbox.width * imageWidth
                    let bboxHeightPixels = bbox.height * imageHeight

                    // Convert to real-world dimensions in meters
                    let widthMeters = bboxWidthPixels * estimatedDistance / fx
                    let heightMeters = bboxHeightPixels * estimatedDistance / fy

                    // Convert to cm²
                    let areaCM2 = widthMeters * 100 * heightMeters * 100

                    // Sum multiple instances of the same label in this frame
                    areasPerLabel[label, default: 0] += areaCM2
                }

                // Step 2: Update detectedIngredients using max
                for (label, frameArea) in areasPerLabel {
                    if let index = self.parent.detectedIngredients.firstIndex(where: { $0.name == label }) {
                        // Take max to avoid jitter accumulation
                        self.parent.detectedIngredients[index].areaScore =
                            max(self.parent.detectedIngredients[index].areaScore, frameArea)
                    } else {
                        var ingredient = Ingredient(aiDetectedName: label)
                        ingredient.areaScore = frameArea
                        self.parent.detectedIngredients.append(ingredient)
                    }
                }
            }
        }
        
        func areaFromBoundingBox(
            _ bbox: CGRect,
            frameSize: CGSize
        ) -> CGFloat {
            let width = bbox.width * frameSize.width
            let height = bbox.height * frameSize.height
            return width * height
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
