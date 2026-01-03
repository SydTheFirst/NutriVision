//
//  ARCameraViewTests.swift
//  NutriVision
//
//  Created by Marco Ferreira on 02/01/2026.
//


import XCTest
import ARKit
import SceneKit
@testable import NutriVision

final class ARCameraViewTests: XCTestCase {

    var coordinator: ARCameraView.Coordinator!
    var detectedIngredients: [Ingredient]!

    override func setUp() {
        super.setUp()
        detectedIngredients = []
        
        let arView = ARCameraView(
            detectedIngredients: .constant(detectedIngredients),
            calories: 0, protein: 0, carbs: 0, fats: 0,
            isScanning: .constant(true)
        )
        coordinator = ARCameraView.Coordinator(arView)
        
        // Inject a mock ARSCNView
        let mockView = MockARSCNView()
        coordinator.sceneView = mockView
    }

    override func tearDown() {
        coordinator = nil
        detectedIngredients = nil
        super.tearDown()
    }

    // MARK: - Test highestMacro
    func testHighestMacro() {
        let result = coordinator.highestMacro(protein: 10, carbs: 20, fats: 15)
        XCTAssertEqual(result.label, "Carbs")
        XCTAssertEqual(result.value, 20)
    }

    // MARK: - Test estimateWeight
    func testEstimateWeight_withMockARFrame_returnsClampedWeight() {
        let mockObservation = VNRecognizedObjectObservation(boundingBox: CGRect(x: 0, y: 0, width: 0.2, height: 0.2))
        let weight = coordinator.estimateWeight(for: mockObservation)
        XCTAssertGreaterThanOrEqual(weight, 50)
        XCTAssertLessThanOrEqual(weight, 1500)
    }

    // MARK: - Test ingredient detection handling
    func testHandleDetections_addsNewIngredient() {
        let observation = VNRecognizedObjectObservation(boundingBox: CGRect(x: 0, y: 0, width: 0.2, height: 0.2))
        observation.setValue([VNClassificationObservation(identifier: "apple", confidence: 0.8)], forKey: "labels")
        
        coordinator.handleDetections([observation])
        
        XCTAssertEqual(coordinator.parent.detectedIngredients.count, 1)
        XCTAssertEqual(coordinator.parent.detectedIngredients.first?.name, "apple")
        XCTAssertGreaterThan(coordinator.parent.detectedIngredients.first!.areaScore, 0)
    }

    // MARK: - Test removeIngredientCard
    func testRemoveIngredientCard_removesNode() {
        let ingredient = Ingredient(aiDetectedName: "banana")
        detectedIngredients.append(ingredient)
        
        let node = SCNNode()
        coordinator.ingredientCards[ingredient.id] = node
        XCTAssertNotNil(coordinator.ingredientCards[ingredient.id])
        
        coordinator.removeIngredientCard(id: ingredient.id)
        XCTAssertNil(coordinator.ingredientCards[ingredient.id])
    }

    // MARK: - Test makeIngredientInfoCard
    func testMakeIngredientInfoCard_createsNode() {
        let ingredient = Ingredient(aiDetectedName: "apple", calories: 52, protein: 0.3, carbs: 14, fats: 0.2)
        let position = SCNVector3(0,0,0)
        let node = coordinator.makeIngredientInfoCard(ingredient: ingredient, position: position)
        XCTAssertEqual(node.position, position)
        XCTAssertFalse(node.childNodes.isEmpty)
    }
}

// MARK: - Mock ARSCNView / ARSession
class MockARSCNView: ARSCNView {
    override var session: ARSession { MockARSession() }
}

class MockARSession: ARSession {
    override var currentFrame: ARFrame? { MockARFrame() }
}

class MockARFrame: ARFrame {
    override var camera: ARCamera { MockARCamera() }
}

class MockARCamera: ARCamera {
    override var transform: simd_float4x4 { matrix_identity_float4x4 }
}
