//
//  GithubOAuthManager.swift
//  Giterest
//
//  Created by Louis Tur on 11/16/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import Foundation
import UIKit

internal enum GithubAuthScope: String {
  case user, public_repo
}

internal class GithubOAuthManager {
  private static let authorizationURL: URL = URL(string: "https://github.com/login/oauth/authorize")!
  private static let redirectURI: URL = URL(string: "giterest://auth.url")!
  
  private var clientID: String?
  private var clientSecret: String?
  
  private var requestToken: String?
  private var accessToken: String?
  
  internal static let shared: GithubOAuthManager = GithubOAuthManager()
  private init() {}
  
  internal class func configure(clientID: String, clientSecret: String) {
    shared.clientID = clientID
    shared.clientSecret = clientSecret
  }
  
  internal func requestAuthentication(scopes: [GithubAuthScope]) throws {
    guard
      clientID != nil,
      clientSecret != nil
    else {
      throw NSError(domain: "No Client", code: 01, userInfo: nil)
    }
    
    var urlComponents = URLComponents(url: GithubOAuthManager.authorizationURL, resolvingAgainstBaseURL: true)
    
    let clientIDQuery = URLQueryItem(name: "client_id", value: self.clientID!)
    let redirectURIQuery = URLQueryItem(name: "redirect_uri", value: GithubOAuthManager.redirectURI.absoluteString)
    let scopeQuery = URLQueryItem(name: "scope", value: scopes.flatMap { $0.rawValue }.joined(separator: " ".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!) )
    
    urlComponents?.queryItems = [clientIDQuery, redirectURIQuery, scopeQuery]
    
    UIApplication.shared.open(urlComponents!.url!, options: [:], completionHandler: nil)
  }
  
}
