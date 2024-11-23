import Foundation

enum StorageError: Error {
    case saveError
    case loadError
    case dataNotFound
    case decodingError
    case encodingError
    
    var localizedDescription: String {
        switch self {
        case .saveError: return "Failed to save data"
        case .loadError: return "Failed to load data"
        case .dataNotFound: return "No data found"
        case .decodingError: return "Failed to decode data"
        case .encodingError: return "Failed to encode data"
        }
    }
}

class StorageService {
    static let shared = StorageService()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func save<T: Encodable>(_ item: T, forKey key: String, completion: @escaping (Result<Void, StorageError>) -> Void) {
        do {
            let data = try JSONEncoder().encode(item)
            userDefaults.set(data, forKey: key)
            completion(.success(()))
        } catch {
            completion(.failure(.encodingError))
        }
    }
    
    func load<T: Decodable>(forKey key: String, as type: T.Type, completion: @escaping (Result<T, StorageError>) -> Void) {
        guard let data = userDefaults.data(forKey: key) else {
            completion(.failure(.dataNotFound))
            return
        }
        
        do {
            let item = try JSONDecoder().decode(type, from: data)
            completion(.success(item))
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    func delete(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
