//
//  HomeHostingController.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import UIKit
import SwiftUI

class HomeHostingController: UIHostingController<HomeView> {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: HomeView())
    }
    
    override init(rootView: HomeView) {
        super.init(rootView: rootView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide the navigation bar for a clean look
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Keep navigation bar hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
