//
//  AuthHostingController.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 21/12/2025.
//

import UIKit
import SwiftUI

class AuthHostingController: UIHostingController<AnyView> {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder,
                   rootView: AnyView(
                       NavigationStack {
                           AuthView()
                       }
                   ))
    }
}


