//
//  HomeViewController.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 19/11/2025.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var startRecordingButton: UIButton!
    @IBOutlet weak var seeHistoryButton: UIButton!
    @IBOutlet weak var savedMealsButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func startRecordingTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "RecordingVC") as! RecordingViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    func updateUI() {
        let loggedIn = UserSession.shared.isLoggedIn

        // Protected features
        seeHistoryButton.isHidden = !loggedIn
        savedMealsButton.isHidden = !loggedIn

        // Login / Register only if logged out
        loginButton.isHidden = loggedIn
        registerButton.isHidden = loggedIn
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        // TODO: implement your login screen
        // For now, we simulate login:
        UserSession.shared.logIn()
        updateUI()
    }

    @IBAction func registerTapped(_ sender: UIButton) {
        // TODO: implement your register screen
        // Simulate success:
        UserSession.shared.logIn()
        updateUI()
    }

}
