//
//  GitHubRelease.swift
//  Harbor
//

import Foundation

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let htmlUrl: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
    }

    /// Extracts version from tag (removes "v" prefix if present)
    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }

    /// Truncates release notes to specified character limit
    func truncatedBody(maxLength: Int = 200) -> String {
        guard body.count > maxLength else { return body }
        let truncated = String(body.prefix(maxLength))
        return truncated + "..."
    }
}
