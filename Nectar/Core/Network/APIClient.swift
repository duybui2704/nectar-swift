import Foundation

/// Printerval HTTP client — multi-service base URL + default headers.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let storage: AppStorageService

    init(
        session: URLSession? = nil,
        storage: AppStorageService = .shared
    ) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = APIConfig.requestTimeout
            config.timeoutIntervalForResource = APIConfig.resourceTimeout
            config.waitsForConnectivity = true
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config)
        }
        self.storage = storage
    }

    func get<T: Decodable>(
        _ path: String,
        service: APIService = .customer,
        query: [String: String] = [:],
        as type: T.Type,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await requestData(
            service: service,
            path: path,
            method: "GET",
            query: query,
            body: nil,
            authenticated: authenticated
        )
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.network("Decode \(T.self) thất bại: \(error.localizedDescription)")
        }
    }

    /// GET trả về raw `Data` (khi chưa có DTO cụ thể).
    func getData(
        _ path: String,
        service: APIService = .customer,
        query: [String: String] = [:],
        authenticated: Bool = true
    ) async throws -> Data {
        try await requestData(
            service: service,
            path: path,
            method: "GET",
            query: query,
            body: nil,
            authenticated: authenticated
        )
    }

    func post<Body: Encodable, T: Decodable>(
        _ path: String,
        service: APIService = .customer,
        query: [String: String] = [:],
        body: Body,
        as type: T.Type,
        authenticated: Bool = true
    ) async throws -> T {
        let encoded = try JSONEncoder().encode(body)
        let data = try await requestData(
            service: service,
            path: path,
            method: "POST",
            query: query,
            body: encoded,
            authenticated: authenticated
        )
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.network("Decode \(T.self) thất bại: \(error.localizedDescription)")
        }
    }

    private func requestData(
        service: APIService,
        path: String,
        method: String,
        query: [String: String],
        body: Data?,
        authenticated: Bool,
        retryCount: Int = 0
    ) async throws -> Data {
        let url = try buildURL(service: service, path: path, query: query)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = APIConfig.requestTimeout

        for (key, value) in APIConfig.defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if authenticated, let token = storage.sessionToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = body

        NetworkLogger.logRequest(urlRequest)
        let started = Date()

        do {
            let (data, response) = try await session.data(for: urlRequest)
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            NetworkLogger.logResponse(response, data: data, error: nil, durationMs: ms)

            guard let http = response as? HTTPURLResponse else {
                throw AppError.network("Phản hồi không hợp lệ.")
            }
            if http.statusCode == 401 {
                throw AppError.unauthorized
            }
            guard (200...299).contains(http.statusCode) else {
                throw AppError.network("HTTP \(http.statusCode)")
            }
            return data
        } catch let error as AppError {
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            NetworkLogger.logResponse(nil, data: nil, error: error, durationMs: ms)

            if case .unauthorized = error, retryCount == 0 {
                let refreshed = try await refreshTokenIfNeeded()
                if refreshed {
                    return try await requestData(
                        service: service,
                        path: path,
                        method: method,
                        query: query,
                        body: body,
                        authenticated: authenticated,
                        retryCount: 1
                    )
                }
            }
            throw error
        } catch {
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            NetworkLogger.logResponse(nil, data: nil, error: error, durationMs: ms)

            // Retry khi timeout / mất mạng tạm thời
            if shouldRetry(error), retryCount < APIConfig.maxTimeoutRetries {
                #if DEBUG
                print("⏳ Retry \(path) after network error…")
                #endif
                try await Task.sleep(nanoseconds: 400_000_000)
                return try await requestData(
                    service: service,
                    path: path,
                    method: method,
                    query: query,
                    body: body,
                    authenticated: authenticated,
                    retryCount: retryCount + 1
                )
            }

            throw AppError.network(error.localizedDescription)
        }
    }

    private func shouldRetry(_ error: Error) -> Bool {
        let urlError = error as? URLError
        switch urlError?.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private func buildURL(service: APIService, path: String, query: [String: String]) throws -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(url: service.baseURL.appendingPathComponent(trimmed), resolvingAgainstBaseURL: false) else {
            throw AppError.network("URL không hợp lệ.")
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw AppError.network("URL không hợp lệ.")
        }
        return url
    }

    func refreshTokenIfNeeded() async throws -> Bool {
        guard storage.sessionToken != nil else {
            throw AppError.unauthorized
        }
        _ = storage.createSession()
        return true
    }
}
