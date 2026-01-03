//
//  ProfileSetupView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 22/12/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileSetupView: View {
    
    @StateObject var vm: ProfileSetupViewModel
    var onProfileComplete: () -> Void
    var onCancel: () -> Void
    
    init(email: String = "",
         userCredential: AuthDataResult? = nil,
         onProfileComplete: @escaping () -> Void,
         onCancel: @escaping () -> Void) {
        
        _vm = StateObject(wrappedValue: ProfileSetupViewModel(email: email, userCredential: userCredential))
        self.onProfileComplete = onProfileComplete
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Name", text: $vm.name)
                    TextField("Age", text: $vm.age)
                        .keyboardType(.numberPad)
                    TextField("Height (cm)", text: $vm.height)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $vm.weight)
                        .keyboardType(.decimalPad)
                    
                    Picker("Gender", selection: $vm.gender) {
                        Text("Male").tag(Gender.male)
                        Text("Female").tag(Gender.female)
                        Text("Other").tag(Gender.other)
                    }
                    
                    Picker("Goal", selection: $vm.weightGoal) {
                        Text("Maintain").tag(WeightGoal.maintain)
                        Text("Lose").tag(WeightGoal.lose)
                        Text("Gain").tag(WeightGoal.gain)
                    }
                }
                
                Section {
                    Button("Save") {
                        vm.saveProfile()
                        if !vm.showAlert {
                            onProfileComplete()
                        }
                    }
                    .disabled(!vm.isFormValid)
                    
                    Button("Cancel") {
                        vm.handleCancel()
                        if vm.showCancelAlert {
                            onCancel()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile Setup")
            .alert(vm.alertMessage, isPresented: $vm.showAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert("Cancel Profile Setup?", isPresented: $vm.showCancelAlert) {
                Button("Yes", role: .destructive) { onCancel() }
                Button("No", role: .cancel) { }
            }
        }
    }
}
