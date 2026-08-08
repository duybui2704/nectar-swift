import Foundation

/// Map JSON login Printerval → `AuthSession` (key linh hoạt).
enum AuthDTOMapper {
    static func session(from data: Data) throws -> AuthSession {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.network("Login response không hợp lệ.")
        }

        let status = (root["status"] as? String ?? "").lowercased()
        if !status.isEmpty, status != APIConfig.successStatus, status != "success", status != "ok" {
            let message = string(root, keys: ["message", "error", "error_message"])
                ?? "Đăng nhập thất bại."
            throw AppError.validation(message)
        }

        let result = (root["result"] as? [String: Any])
            ?? (root["data"] as? [String: Any])
            ?? root

        let customer = (result["customer"] as? [String: Any])
            ?? (result["user"] as? [String: Any])
            ?? result

        guard let token = string(root, keys: [
            "token",
        ]) ?? string(customer, keys: [
            "token",
        ]) else {
            NectarLog.log("Login missing token — keys: \(Array(result.keys).sorted())", title: "Auth", level: .error)
            throw AppError.network("Thiếu token trong phản hồi login.")
        }

        let email = string(customer, keys: ["email", "username", "user_name", "userName"])
        let first = string(customer, keys: ["first_name", "firstName", "firstname"]) ?? ""
        let last = string(customer, keys: ["last_name", "lastName", "lastname"]) ?? ""
        let fullFromParts = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        let name = string(customer, keys: ["name", "full_name", "fullName", "display_name", "displayName"])
            ?? (fullFromParts.isEmpty ? nil : fullFromParts)
            ?? email
            ?? "Customer"

        let id: String? = {
            if let n = customer["id"] as? Int { return String(n) }
            if let n = customer["id"] as? NSNumber { return n.stringValue }
            return string(customer, keys: ["id", "customer_id", "customerId"])
        }()

        return AuthSession(
            token: token,
            displayName: name,
            email: email,
            customerId: id
        )
    }

    private static func string(_ dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let s = dict[key] as? String, !s.isEmpty { return s }
            if let n = dict[key] as? NSNumber { return n.stringValue }
        }
        return nil
    }
}
