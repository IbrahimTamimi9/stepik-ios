//
//  AuthInfo.swift
//  Stepic
//
//  Created by Alexander Karpov on 17.09.15.
//  Copyright (c) 2015 Alex Karpov. All rights reserved.
//

import UIKit

extension NSNotification.Name {
    static let didLogout = NSNotification.Name("didLogout")
}

class AuthInfo: NSObject {
    static var shared = AuthInfo()

    fileprivate let defaults = UserDefaults.standard

    fileprivate override init() {
        super.init()

        print("initializing AuthInfo with userId \(String(describing: userId))")
        if let id = userId {
            if let users = User.fetchById(id) {
                if users.isEmpty {
                    AnalyticsReporter.reportEvent(AnalyticsEvents.Errors.authInfoNoUserOnInit)
                } else {
                    user = users.first
                }
            }
        }
    }

    fileprivate func setTokenValue(_ newToken: StepicToken?) {
        defaults.setValue(newToken?.accessToken, forKey: "access_token")
        defaults.setValue(newToken?.refreshToken, forKey: "refresh_token")
        defaults.setValue(newToken?.tokenType, forKey: "token_type")
        defaults.setValue(newToken?.expireDate.timeIntervalSince1970, forKey: "expire_date")
        defaults.synchronize()
    }

    var token: StepicToken? {
        set(newToken) {
            if newToken == nil || newToken?.accessToken == "" {
                print("\nsetting new token to nil\n")

                let performLogoutActions = {
                    [weak self] in
                    guard let strongSelf = self else {
                        return
                    }

                    UIThread.performUI {
                        //Delete enrolled information
                        NotificationCenter.default.post(name: .didLogout, object: nil)
                        TabsInfo.myCoursesIds = []
                        let c = Course.getAllCourses(enrolled: true)
                        for course in c {
                            course.enrolled = false
                        }

                        Certificate.deleteAll()
                        Progress.deleteAllStoredProgresses()
                        Notification.deleteAll()
                        AnalyticsUserProperties.shared.clearUserDependentProperties()
                        #if !os(tvOS)
                            NotificationsBadgesManager.shared.set(number: 0)
                        #endif
                        CoreDataHelper.instance.save()

                        AuthInfo.shared.user = nil
                        DeviceDefaults.sharedDefaults.deviceId = nil

                        strongSelf.setTokenValue(nil)
                    }
                }

                #if os(tvOS)
                    NotificationCenter.default.post(name: .userLoggedOut, object: nil)
                    performLogoutActions()
                #else
                    //Unregister from notifications
                    NotificationRegistrator.shared.unregisterFromNotifications(completion: {
                        performLogoutActions()
                    })
                #endif
            } else {
                print("\nsetting new token -> \(newToken!.accessToken)\n")
                didRefresh = true
                setTokenValue(newToken)
                Session.delete()
            }
        }

        get {
            if let accessToken = defaults.value(forKey: "access_token") as? String,
            let refreshToken = defaults.value(forKey: "refresh_token") as? String,
            let tokenType = defaults.value(forKey: "token_type") as? String {
//                print("got accessToken \(accessToken)")
                let expireDate = Date(timeIntervalSince1970: defaults.value(forKey: "expire_date") as? TimeInterval ?? 0.0)
                return StepicToken(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType, expireDate: expireDate)
            } else {
                return nil
            }
        }
    }

    var isAuthorized: Bool {
        return token != nil
    }

    var hasUser: Bool {
        return user != nil
    }

    var needsToRefreshToken: Bool {
        //TODO: Fix this
        if let token = token {
            return Date().compare(token.expireDate as Date) == ComparisonResult.orderedDescending
        } else {
            return false
        }
    }

    var authorizationType: AuthorizationType {
        get {
            if let typeRaw = defaults.value(forKey: "authorization_type") as? Int {
                return AuthorizationType(rawValue: typeRaw)!
            } else {
                return AuthorizationType.none
            }
        }

        set(type) {
            defaults.setValue(type.rawValue, forKey: "authorization_type")
            defaults.synchronize()
        }
    }

    var didRefresh: Bool = false

    var anonymousUserId: Int?

    var userId: Int? {
        set(id) {
            if let user = user {
                if user.isGuest {
                    print("setting anonymous user id \(String(describing: id))")
                    anonymousUserId = id
                    AnalyticsUserProperties.shared.setUserID(to: nil)
                    return
                }
            }
            AnalyticsUserProperties.shared.setUserID(to: user?.id)
            print("setting user id \(String(describing: id))")
            defaults.setValue(id, forKey: "user_id")
            defaults.synchronize()
        }
        get {
            if let user = user {
                if user.isGuest {
                    print("returning anonymous user id \(String(describing: anonymousUserId))")
                    return anonymousUserId
                } else {
                    print("returning normal user id \(String(describing: defaults.value(forKey: "user_id") as? Int))")
                    return defaults.value(forKey: "user_id") as? Int
                }
            } else {
                print("returning normal user id \(String(describing: defaults.value(forKey: "user_id") as? Int))")
                return defaults.value(forKey: "user_id") as? Int
            }
        }
    }

    var user: User? {
        didSet {
            print("\n\ndid set user with id \(String(describing: user?.id))\n\n")
            userId = user?.id
        }
    }

    var initialHTTPHeaders: [String: String] {
        if !AuthInfo.shared.isAuthorized {
            return Session.cookieHeaders
        } else {
            return APIDefaults.headers.bearer
        }
    }
}

enum AuthorizationType: Int {
    case none = 0, password, code
}
