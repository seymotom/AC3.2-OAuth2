//
//  GithubOAuthManager.swift
//  Giterest
//
//  Created by Tom Seymour on 11/17/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import Foundation
import UIKit

enum GithubScope: String {
    case user, public_repo
}

class GithubOAuthManager {
    
    static let authorizationURL: URL = URL(string: "https://github.com/login/oauth/authorize")!
    static let redirectURL: URL = URL(string: "giterest://auth.url")!
    
    static let accessTokenURL: URL = URL(string: "https://github.com/login/oauth/access_token")!
    
    private var clientID: String?
    private var clientSecret: String?
    
    private var accessToken: String?
    
    let defaults = UserDefaults.standard
    
    
    internal static let shared: GithubOAuthManager = GithubOAuthManager()
    private init() {}
    
    internal class func configure(clientID: String, clientSecret: String) {
        shared.clientID = clientID
        shared.clientSecret = clientSecret
        shared.defaults.set(clientID, forKey: "client_id")
        shared.defaults.set(clientSecret, forKey: "client_secret")
    }
    
    func updateAccessToken(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func requestAuthorization(scopes: [GithubScope]) throws {
        guard
            let clientID = self.clientID,
            let clientSecret = self.clientSecret
        else {
            throw NSError(domain: "Client ID / Client Secret Not Set", code: 1, userInfo: nil)
        }
        
        let clientIDQuery = URLQueryItem(name: "client_id", value: clientID)
        let redirectURLQuery = URLQueryItem(name: "redirect_uri", value: GithubOAuthManager.redirectURL.absoluteString)
        
        let scopeQuery: URLQueryItem = URLQueryItem(name: "scope", value: scopes.flatMap { $0.rawValue }.joined(separator: " "))
        
        var components = URLComponents(url: GithubOAuthManager.authorizationURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [clientIDQuery, redirectURLQuery, scopeQuery]
        
        UIApplication.shared.open(components!.url!, options: [:], completionHandler: nil)
        
    }
    
    func requestAuthToken(url: URL) {
        var accessCode: String?
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {

            for queryItem in urlComponents.queryItems! {
                if queryItem.name == "code" {
                    accessCode = queryItem.value!
                }
            }
        }
        
        let clientIDQuery = URLQueryItem(name: "client_id", value: self.clientID)
        let clientSecretQuery = URLQueryItem(name: "client_secret", value: self.clientSecret)
        let accessCodeQuery = URLQueryItem(name: "code", value: accessCode)
        let redirectURIQuery = URLQueryItem(name: "redirect_uri", value: GithubOAuthManager.redirectURL.absoluteString)
        
        var components = URLComponents(url: GithubOAuthManager.accessTokenURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [clientIDQuery, clientSecretQuery, accessCodeQuery, redirectURIQuery]
        
        print(components?.url!)
        var request = URLRequest(url: (components?.url)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)

        session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                print(error)
            }
            if response != nil {
                print("response: \(response)")
            }
            if data != nil {
                print(data!)
//                if let accessTokenString = String(data: data!, encoding: String.Encoding.utf8) {
//                    // then parse the string to get the access token.
//                    // do it this way if you can't add a header to return the data as json
//                    print(">>>>>>>>>" + accessTokenString)
//                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    if let validJson = json as? [String: Any]{
                        print(validJson)
                        if let accessToken = validJson["access_token"] as? String {
                            self.accessToken = accessToken
                            self.defaults.set(self.accessToken!, forKey: "access_token")
                            print(self.accessToken)
                        }
                    }
                }
                catch { print("error encountered \(error)") }
            }

        }.resume()
        
        
        // Required params
        // 1. client_id
        // 2. client_secret
        // 3. access_code
        // 4. redirect_uri

        // ** use URLComponents + URLQueryItems to build request URL **
        
        // 1. make the post request to the auth token endpoint
        // 2. get the response to the point where it's data
    }
    
    func getStarredRepos() {
        guard let url = URL(string: "https://api.github.com/user/starred?access_token=\(self.accessToken!)") else { return }
        
        let session  = URLSession(configuration: .default)
        session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if data != nil {
                print(" yay data!")
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: Any]]
                    
                    if let validJson = json {
                        print(validJson)
                        // guard let resultsDict = validJson["results"] as! [String: Any] else { return }
                    }
                    
                }
                catch {
                    print("Problem casting json: \(error)")
                }
            }
        }.resume()
        
    }
    
}
