import Foundation

/// Public owner information, bundled as data rather than interpolated into executable code.
struct Brand: Decodable {
    let name: String
    let english_name: String
    let github_url: String
    let website: String
    let wechat_name: String
    let feedback_email: String

    static func load(from url: URL?) -> Brand {
        guard let url, let data = try? Data(contentsOf: url),
              let brand = try? JSONDecoder().decode(Brand.self, from: data) else { return fallback }
        return brand
    }
    static let current = load(from: Bundle.main.resourceURL?.appendingPathComponent("About/brand.json"))
    private static let fallback = Brand(name: "Nitor", english_name: "Nitor",
                                        github_url: "https://github.com/TianMingAI",
                                        website: "", wechat_name: "", feedback_email: "")
    static func webURL(_ value: String) -> URL? {
        guard let url = URL(string: value), ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }
    var feedbackURL: URL? {
        guard !feedback_email.isEmpty, feedback_email.contains("@"),
              !feedback_email.contains(where: { $0.isWhitespace }),
              !feedback_email.contains("?"), !feedback_email.contains("#") else { return nil }
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = feedback_email
        return parts.url
    }
    static func hasImage(_ filename: String) -> Bool {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("About/\(filename)") else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
