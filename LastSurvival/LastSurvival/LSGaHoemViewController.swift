
import UIKit
import SpriteKit
import Alamofire
import Zuidhou

class LSGaHoemViewController: UIViewController {

    private var skView: SKView!

    override func loadView() {
        skView = SKView(frame: UIScreen.main.bounds)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        self.view = skView
        
        
        let aguys = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        aguys!.view.tag = 511
        aguys?.view.frame = UIScreen.main.bounds
        view.addSubview(aguys!.view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mfoeu = NetworkReachabilityManager()
        mfoeu?.startListening { state in
            switch state {
            case .reachable(_):
                let iasj = VueJeu()
                iasj.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
                
                mfoeu?.stopListening()
            case .notReachable:
                break
            case .unknown:
                break
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard skView.scene == nil else { return }
        let scene = TitleVaultScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
}
