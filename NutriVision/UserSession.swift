import Foundation

class UserSession {
    static let shared = UserSession()

    private init() {}

    var isLoggedIn: Bool {
        get { UserDefaults.standard.bool(forKey: "loggedIn") }
        set { UserDefaults.standard.set(newValue, forKey: "loggedIn") }
    }

    func logIn() {
        isLoggedIn = true
    }

    func logOut() {
        isLoggedIn = false
    }
}
