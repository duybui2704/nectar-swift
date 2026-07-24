import Foundation

/// PostPay-style HTTP client with Bearer token, envelope decode, JWT refresh hooks.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let storage: AppStorageService

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        storage: AppStorageService = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.storage = storage
    }

    func get<T: Decodable>(_ path: String, as type: T.Type, authenticated: Bool = true) async throws -> T {
        try await request(path: path, method: "GET", body: nil as Data?, as: type, authenticated: authenticated)
    }

    func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        as type: T.Type,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: "POST", body: data, as: type, authenticated: authenticated)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: Data?,
        as type: T.Type,
        authenticated: Bool,
        retryCount: Int = 0
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = APIConfig.requestTimeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(APIConfig.appHeader, forHTTPHeaderField: "app")
        if authenticated, let token = storage.sessionToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = body

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.network("Phản hồi không hợp lệ.")
            }
            if http.statusCode == 401 {
                throw AppError.unauthorized
            }
            guard (200...299).contains(http.statusCode) else {
                throw AppError.network("HTTP \(http.statusCode)")
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as AppError {
            if case .unauthorized = error, retryCount == 0 {
                let refreshed = try await refreshTokenIfNeeded()
                if refreshed {
                    return try await request(path: path, method: method, body: body, as: type, authenticated: authenticated, retryCount: 1)
                }
            }
            throw error
        } catch {
            throw AppError.network(error.localizedDescription)
        }
    }

    func refreshTokenIfNeeded() async throws -> Bool {
        // Demo: simulate refresh success when session exists
        guard storage.sessionToken != nil else {
            throw AppError.unauthorized
        }
        _ = storage.createSession()
        return true
    }

    func unwrapMirrorEnvelope<T>(_ envelope: APIEnvelope<T>) throws -> T {
        switch envelope.code {
        case APIConfig.successCode:
            guard let body = envelope.body else { throw AppError.notFound }
            return body
        case APIConfig.jwtLogoutCode:
            storage.clearSession()
            throw AppError.unauthorized
        case APIConfig.jwtRefreshCode:
            throw AppError.unauthorized
        default:
            throw AppError.network(envelope.message)
        }
    }
}
