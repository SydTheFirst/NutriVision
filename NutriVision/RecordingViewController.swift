import UIKit
import ARKit

class RecordingViewController: UIViewController {

    @IBOutlet weak var cameraView: ARSCNView!
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Recording"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraView.session.pause()
    }

    func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("ARKit not supported on this device (simulator)")
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.environmentTexturing = .automatic
        
        cameraView.session.run(configuration)
    }
}
