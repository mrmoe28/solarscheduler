import Foundation
import CryptoKit

extension String {
    /// Creates a SHA256 hash of the string
    func sha256Hash() -> String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.map { byte in
            String(format: "%02x", byte)
        }.joined()
        return hashString
    }
    
    /// Validates password requirements
    var isValidPassword: Bool {
        // At least 6 characters
        return self.count >= 6
    }
    
    /// Validates email format
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

extension User {
    /// Verifies if the provided password matches the stored password hash
    func verifyPassword(_ password: String) -> Bool {
        return password.sha256Hash() == self.passwordHash
    }
}