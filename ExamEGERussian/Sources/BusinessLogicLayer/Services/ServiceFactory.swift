//
//  ServiceFactory.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 13/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

protocol ServiceFactory: class {
    func userRegistrationService() -> UserRegistrationService
}
