//
//  UpdateCheckerService.swift
//  Harbor
//

import Foundation

actor UpdateCheckerService {

    /// Checks GitHub API for the latest release
    func checkForUpdates() async -> UpdateCheckResult {
        let urlString = "\(Constants.githubApiBaseURL)/repos/\(Constants.githubRepoOwner)/\(Constants.githubRepoName)/releases/latest"

        guard let url = URL(string: urlString) else {
            return .error(.invalidURL)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .error(.networkError)
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

            guard let currentVersion = getCurrentVersion() else {
                return .error(.invalidCurrentVersion)
            }

            if isNewerVersion(current: currentVersion, latest: release.version) {
                return .updateAvailable(release)
            } else {
                return .upToDate
            }

        } catch {
            return .error(.networkError)
        }
    }

    /// Gets current app version from bundle
    private func getCurrentVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Compares two version strings
    private func isNewerVersion(current: String, latest: String) -> Bool {
        // Strip "v" prefix if present
        let currentClean = current.hasPrefix("v") ? String(current.dropFirst()) : current
        let latestClean = latest.hasPrefix("v") ? String(latest.dropFirst()) : latest

        // Use numeric comparison for version strings
        return currentClean.compare(latestClean, options: .numeric) == .orderedAscending
    }
}

enum UpdateCheckResult {
    case updateAvailable(GitHubRelease)
    case upToDate
    case error(UpdateCheckError)
}

enum UpdateCheckError {
    case invalidURL
    case networkError
    case invalidCurrentVersion
}
