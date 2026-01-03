import XCTest
@testable import NutriVision

// MARK: - Mock URLProtocol for intercepting network requests
final class MockURLProtocol: URLProtocol {
    static var testData: Data?
    static var testResponse: HTTPURLResponse?
    static var testError: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.testError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let data = MockURLProtocol.testData {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = MockURLProtocol.testResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - NutritionServiceTests
final class NutritionServiceTests: XCTestCase {

    var service: NutritionService!
    var session: URLSession!

    // MARK: - Setup / Teardown
    override func setUp() {
        super.setUp()
        
        // Configure URLSession with MockURLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        
        // Inject mock session into NutritionService (requires minor refactor in service)
        service = NutritionService(session: session)
        
        // Reset rate limiter before each test
        NutritionService.resetRateLimiter()
    }

    override func tearDown() {
        service = nil
        session = nil
        MockURLProtocol.testData = nil
        MockURLProtocol.testResponse = nil
        MockURLProtocol.testError = nil
        super.tearDown()
    }

    // MARK: - Rate Limiting Tests
    func testGlobalRateLimitBlocksCall() async throws {
        NutritionService.lastGlobalCallTime = Date() // simulate previous call

        let result = try await service.fetchNutrition(for: "apple")
        XCTAssertNil(result, "Rate limiter should block requests made too soon.")
    }

    func testGlobalRateLimitAllowsCall() async throws {
        NutritionService.lastGlobalCallTime = Date(timeIntervalSince1970: 0) // far in past

        // Provide mock successful response
        let json = """
        {
            "ingredients":[{"parsed":[{"nutrients":{"ENERC_KCAL":{"label":"Energy","quantity":52,"unit":"kcal"}}}]}]
        }
        """.data(using: .utf8)!
        MockURLProtocol.testData = json
        MockURLProtocol.testResponse = HTTPURLResponse(
            url: URL(string: "https://api.edamam.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let result = try await service.fetchNutrition(for: "apple")
        XCTAssertNotNil(result, "Request should succeed if rate limiter allows it.")
        XCTAssertEqual(result?.calories, 52)
    }

    // MARK: - JSON Decoding Tests
    func testDecodingValidJSON() throws {
        let json = """
        {
            "ingredients": [
                {
                    "parsed": [
                        {
                            "nutrients": {
                                "ENERC_KCAL": {"label":"Energy","quantity":52,"unit":"kcal"},
                                "PROCNT": {"label":"Protein","quantity":0.3,"unit":"g"}
                            }
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(EdamamResponse.self, from: json)
        XCTAssertEqual(decoded.firstParsedNutrients?["ENERC_KCAL"]?.quantity, 52)
        XCTAssertEqual(decoded.firstParsedNutrients?["PROCNT"]?.quantity, 0.3)
    }

    func testIngredientMappingWithMissingNutrients() {
        let nutrients: [String: NutrientInfo] = [
            "ENERC_KCAL": NutrientInfo(label: "Energy", quantity: 100, unit: "kcal")
            // PROCNT, CHOCDF, FAT missing
        ]

        let ingredient = Ingredient(
            name: "apple",
            amount: 1,
            unit: "serving",
            calories: nutrients["ENERC_KCAL"]?.quantity ?? 0,
            protein: nutrients["PROCNT"]?.quantity ?? 0,
            carbs: nutrients["CHOCDF"]?.quantity ?? 0,
            fats: nutrients["FAT"]?.quantity ?? 0
        )

        XCTAssertEqual(ingredient.calories, 100)
        XCTAssertEqual(ingredient.protein, 0)
        XCTAssertEqual(ingredient.carbs, 0)
        XCTAssertEqual(ingredient.fats, 0)
    }

    // MARK: - HTTP Error Handling
    func testFetchNutritionHandlesHTTP429() async throws {
        MockURLProtocol.testResponse = HTTPURLResponse(
            url: URL(string: "https://api.edamam.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )

        let result = try await service.fetchNutrition(for: "apple")
        XCTAssertNil(result, "HTTP 429 should return nil without crashing.")
    }

    // MARK: - Invalid URL Handling
    func testInvalidQueryReturnsNil() async throws {
        let invalidQuery = "\u{FFFF}" // invalid Unicode for URL

        let result = try await service.fetchNutrition(for: invalidQuery)
        XCTAssertNil(result, "Invalid query should return nil.")
    }

    // MARK: - Concurrency / Multiple Calls
    func testMultipleCallsRespectRateLimit() async throws {
        NutritionService.lastGlobalCallTime = Date()

        async let firstCall = service.fetchNutrition(for: "apple")
        async let secondCall = service.fetchNutrition(for: "banana")

        let results = try await [firstCall, secondCall]

        XCTAssertTrue(results.contains(nil), "At least one call should be blocked by rate limiter.")
    }
}
