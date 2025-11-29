import UIKit
import ARKit
import Vision

class RecordingViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var cameraView: ARSCNView!
    @IBOutlet weak var scrollView: UIScrollView!

    private var visionModel: VNCoreMLModel!
    private var requests = [VNRequest]()

    private var detectionOverlay: CALayer! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recording"

        cameraView.session.delegate = self
        cameraView.scene = SCNScene()
        setupDetectionOverlay()
        setupVision()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
    }

    private func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("ARKit not supported on this device (simulator)")
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.environmentTexturing = .automatic

        cameraView.session.run(configuration)
    }

    private func setupVision() {
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            fatalError("Model not found")
        }

        do {
            visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        } catch {
            fatalError("Could not load Vision ML model: \(error)")
        }

        let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
            DispatchQueue.main.async {
                if let results = request.results {
                    self?.processDetections(results)
                }
            }
        }

        objectRecognition.imageCropAndScaleOption = .scaleFill
        self.requests = [objectRecognition]
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .right,
                                            options: [:])
        do {
            try handler.perform(self.requests)
        } catch {
            print("Vision error:", error)
        }
    }

    private func setupDetectionOverlay() {
        detectionOverlay = CALayer()
        detectionOverlay.frame = cameraView.bounds
        view.layer.addSublayer(detectionOverlay)
    }

    private func processDetections(_ results: [Any]) {
        detectionOverlay.sublayers?.forEach { $0.removeFromSuperlayer() }

        guard let observations = results as? [VNRecognizedObjectObservation] else { return }

        let bufferWidth = Int(cameraView.bounds.width)
        let bufferHeight = Int(cameraView.bounds.height)

        for observation in observations {

            // Select only the label with the highest confidence.
            let topLabelObservation = observation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(
                observation.boundingBox,
                bufferWidth,
                bufferHeight
            )

            let shapeLayer = createRoundedRectLayerWithBounds(objectBounds)

            let textLayer = createTextSubLayerInBounds(
                objectBounds,
                identifier: topLabelObservation.identifier,
                confidence: topLabelObservation.confidence
            )

            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
    }

    private func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let layer = CALayer()
        layer.frame = bounds
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 6
        return layer
    }

    private func createTextSubLayerInBounds(_ bounds: CGRect,
                                            identifier: String,
                                            confidence: VNConfidence) -> CATextLayer {
        let layer = CATextLayer()
        layer.string = String(format: "%@ (%.2f)", identifier, confidence)
        layer.foregroundColor = UIColor.red.cgColor
        layer.fontSize = 14
        layer.frame = CGRect(
            x: bounds.minX,
            y: bounds.minY - 20,
            width: bounds.width,
            height: 20
        )
        layer.contentsScale = UIScreen.main.scale
        return layer
    }
}
