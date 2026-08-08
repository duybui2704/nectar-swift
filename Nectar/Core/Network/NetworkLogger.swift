import Foundation

/// Log request/response API qua `NectarLog` (OSLog category `Network`).
/// Filter: `Nectar log Network` hoặc Console.app category **Network**.
enum NetworkLogger {
    static var isEnabled: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "(nil)"
        var lines = [
            "┌── API REQUEST ─────────────────────────────",
            "│ \(method) \(url)",
        ]
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            lines.append("│ Headers:")
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                lines.append("│   \(key): \(redact(header: key, value: value))")
            }
        }
        if let body = request.httpBody, !body.isEmpty {
            lines.append("│ Body:")
            lines.append(contentsOf: prettyJSONLines(body).map { "│   \($0)" })
        }
        lines.append("└────────────────────────────────────────────")
        NectarLog.log(lines.joined(separator: "\n"), title: "Network", level: .info)
    }

    static func logResponse(
        _ response: URLResponse?,
        data: Data?,
        error: Error?,
        durationMs: Int
    ) {
        guard isEnabled else { return }
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1
        let url = response?.url?.absoluteString ?? http?.url?.absoluteString ?? "(nil)"
        let ok = (200...299).contains(status)
        let icon = ok ? "✅" : "❌"
        let level: NectarLog.Level = (error != nil || !ok) ? .error : .info

        var lines = [
            "┌── API RESPONSE \(icon) ───────────────────────",
            "│ \(status) \(url)",
            "│ \(durationMs) ms",
        ]

        if let error {
            lines.append("│ Error: \(error.localizedDescription)")
        }

        if let data, !data.isEmpty {
            lines.append("│ Body (\(data.count) bytes):")
            lines.append(contentsOf: prettyJSONLines(data).map { "│   \($0)" })
        }

        lines.append("└────────────────────────────────────────────")
        NectarLog.log(lines.joined(separator: "\n"), title: "Network", level: level)
    }

    // MARK: - Helpers

    private static func redact(header: String, value: String) -> String {
        let key = header.lowercased()
        if key == "authorization" || key.contains("token") {
            guard value.count > 12 else { return "***" }
            return String(value.prefix(12)) + "…"
        }
        return value
    }

    private static func prettyJSONLines(_ data: Data) -> [String] {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let text = String(data: pretty, encoding: .utf8)
        else {
            let raw = String(data: data, encoding: .utf8) ?? "<binary \(data.count) bytes>"
            return [String(raw.prefix(2000))]
        }
        let clipped = text.count > 4000 ? String(text.prefix(4000)) + "\n…(truncated)" : text
        return clipped.components(separatedBy: "\n")
    }
}
