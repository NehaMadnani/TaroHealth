import Foundation

enum AuthError: Error {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .networkError(let message): return message
        case .unknown: return "An unknown error occurred"
        }
    }
}
//
//  AuthError.swift
//  Taro Health
//
//  Created by Neha Suresh on 11/23/24.
//

