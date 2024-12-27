import FirebaseFunctions
import Foundation

func assignRoleToUser(email: String, role: String, completion: @escaping (Result<String, Error>) -> Void) {
    let functions = Functions.functions()
    functions.httpsCallable("assignRole").call(["email": email, "role": role]) { result, error in
        if let error = error {
            completion(.failure(error))
        } else if let resultData = result?.data as? [String: Any], let message = resultData["message"] as? String {
            completion(.success(message))
        } else {
            completion(.failure(NSError(domain: "AssignRole", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected result format."])))
        }
    }
}
