import UIKit
import ARKit

class CameraView: UIView {
    @IBOutlet weak var arView: ARSCNView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
