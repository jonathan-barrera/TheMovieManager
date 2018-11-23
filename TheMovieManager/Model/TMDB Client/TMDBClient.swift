//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = Constants.apiKey
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let imageBase = "https://image.tmdb.org/t/p/w500"
        
        case getWatchlist
        case getRequestToken
        case login
        case newSession
        case webAuth
        case logout
        case getFavorites
        case search(String)
        case markWatchlist
        case markFavorite
        case poster(String)
        case getWatchlistPage(Int)
        case getFavoritesPage(Int)
        
        var stringValue: String {
            switch self {
            case .getWatchlist:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)" + "&sort_by=created_at.desc"
            case .getRequestToken:
                return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .newSession:
                return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth:
                return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout:
                return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            case .getFavorites:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)" +
                "&sort_by=created_at.desc"
            case .search(let query):
                return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .markWatchlist:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .markFavorite:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .poster(let posterPath):
                return Endpoints.imageBase + posterPath
            case .getWatchlistPage(let page):
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)" + "&sort_by=created_at.desc" + "&page=\(page)"
            case .getFavoritesPage(let page):
                return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)" +
                    "&sort_by=created_at.desc" + "&page=\(page)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func downloadPosterImage(posterPath: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.poster(posterPath).url) {
            (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
    class func markFavorite(mediaType: String, mediaId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkFavorite(mediaType: mediaType, mediaId: mediaId, favorite: !favorite)
        taskForPOSTRequest(url: Endpoints.markFavorite.url, body: body, responseType: TMDBResponse.self) {
            (response, error) in
            guard let response = response else {
                completion(false, error)
                return
            }
            if response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13 {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func markWatchlist(mediaType: String, mediaId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
        let body = MarkWatchlist(mediaType: mediaType, mediaId: mediaId, watchlist: !watchlist)
        taskForPOSTRequest(url: Endpoints.markWatchlist.url, body: body, responseType: TMDBResponse.self) {
            (response, error) in
            guard let response = response else {
                completion(false, error)
                return
            }
            if response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13 {
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func search(query: String, completion: @escaping ([Movie], Error?) -> Void) -> URLSessionTask {
        let task = self.taskForGETRequest(url: Endpoints.search(query).url, responseType: MovieResults.self) {
            (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
        return task
    }
    
    class func startNewSession(completion: @escaping (Bool, Error?) -> Void) {
        let body = PostSession(requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.newSession.url, body: body, responseType: SessionResponse.self) {
            (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.login.url, body: body, responseType: RequestTokenResponse.self) {
            (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true, nil)
            } else {
                completion(false, error)
            }
        }
    }
    
    class func getFavorites(completion: @escaping (Int, Error?) -> Void) {
        self.taskForGETRequest(url: Endpoints.getFavorites.url, responseType: MovieResults.self) {
            (response, error) in
            guard let response = response else {
                completion(0, error)
                return
            }
            completion(response.totalPages, nil)
        }
    }
    
    class func getFavoritesPage(page: Int, completion: @escaping ([Movie], Error?) -> Void) {
        self.taskForGETRequest(url: Endpoints.getFavoritesPage(page).url, responseType: MovieResults.self) {
            (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
    }
    
    class func getWatchlist(completion: @escaping (Int, Error?) -> Void) {
        self.taskForGETRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) {
            (response, error) in
            guard let response = response else {
                completion(0, error)
                return
            }
            completion(response.totalPages, nil)
        }
    }
    
    class func getWatchlistPage(page: Int, completion: @escaping ([Movie], Error?) -> Void) {
        self.taskForGETRequest(url: Endpoints.getWatchlistPage(page).url, responseType: MovieResults.self) {
            (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
    }
    
    class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
        self.taskForGETRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) {
            (requestTokenResponse, error) in
            guard let requestTokenResponse = requestTokenResponse else {
                completion(false, error)
                return
            }
            Auth.requestToken = requestTokenResponse.requestToken
            completion(true, nil)
        }
    }
    
    class func logout(completion: @escaping () -> Void) {
        var urlRequest = URLRequest(url: Endpoints.logout.url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let logoutRequest = LogoutRequest(sessionId: Auth.sessionId)
        urlRequest.httpBody = try! JSONEncoder().encode(logoutRequest)
        
        let task = URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completion()
        }
        task.resume()
    }
    
    @discardableResult
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type,
                                                        completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    @discardableResult
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable> (url: URL, body: RequestType, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try! JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
}
