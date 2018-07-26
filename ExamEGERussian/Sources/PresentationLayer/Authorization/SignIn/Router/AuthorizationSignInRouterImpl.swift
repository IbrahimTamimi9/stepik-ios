//
//  AuthorizationSignInRouterImpl.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 17/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

final class AuthorizationSignInRouterImpl: BaseRouter, AuthorizationSignInRouter {
    func showSignUp() {
        pushViewController(derivedFrom: { navigationController in
            assemblyFactory.authorizationAssembly.signUp.module(navigationController: navigationController)
        })
    }
}
