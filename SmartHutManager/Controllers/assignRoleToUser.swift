import FirebaseFunctions
import Foundation

func assignRoleToUser(email: String, role: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard !email.isEmpty, !role.isEmpty else {
        completion(.failure(NSError(domain: "AssignRole", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email or role cannot be empty."])))
        return
    }

    print("[Cloud Functions] Assigning role \(role) to user: \(email)")
    
    let functions = Functions.functions()
    functions.httpsCallable("assignRole").call(["email": email, "role": role]) { result, error in
        if let error = error as NSError? {
            print("[Cloud Functions Error] Failed to assign role: \(error.localizedDescription)")
            switch error.code {
            case FunctionsErrorCode.permissionDenied.rawValue:
                completion(.failure(NSError(domain: "AssignRole", code: error.code, userInfo: [NSLocalizedDescriptionKey: "Permission denied."])))
            case FunctionsErrorCode.unavailable.rawValue:
                completion(.failure(NSError(domain: "AssignRole", code: error.code, userInfo: [NSLocalizedDescriptionKey: "Service unavailable. Try again later."])))
            default:
                completion(.failure(error))
            }
        } else if let data = result?.data as? [String: Any], let message = data["message"] as? String {
            print("[Cloud Functions] Role successfully assigned: \(message)")
            completion(.success(message))
        } else {
            let unexpectedError = NSError(domain: "AssignRole", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected result format."])
            print("[Cloud Functions Error] \(unexpectedError.localizedDescription)")
            completion(.failure(unexpectedError))
        }
    }
}
