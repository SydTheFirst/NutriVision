//
//  DataManager.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import Firebase

class DataManager: ObservableObject {
    @Published var users: [User] = []
    
    init() {
        fetchUsers()
    }
    
    func fetchUsers(){
        users.removeAll()
        let db = Firestore.firestore()
        let ref = db.collection("Users")
        ref.getDocuments { snapshot, error in
            guard error == nil else{
                print(error!.localizedDescription)
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents{
                    let data = document.data()
                    
                    let id = data["id"] as? Int
                    let name = data["name"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let age = data["age"] as? Int
                    let height = data["height"] as? Int
                    let weight = data["weight"] as? Double
                    
                    let user = User(id: id, name: name, email: email, age: age, height: height, weight: weight)
                    self.users.append(user)
                }
            }
        }
    }
}
