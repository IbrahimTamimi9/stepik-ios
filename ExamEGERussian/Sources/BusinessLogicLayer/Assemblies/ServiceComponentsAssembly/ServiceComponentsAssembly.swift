//
//  ServiceComponentsAssembly.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 04/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

final class ServiceComponentsAssembly: ServiceComponents {
    private let authAPI: AuthAPI
    private let stepicsAPI: StepicsAPI
    private let profilesAPI: ProfilesAPI
    private let defaultsStorageManager: DefaultsStorageManager
    private let randomCredentialsGenerator: RandomCredentialsGenerator

    init(authAPI: AuthAPI,
         stepicsAPI: StepicsAPI,
         profilesAPI: ProfilesAPI,
         defaultsStorageManager: DefaultsStorageManager,
         randomCredentialsGenerator: RandomCredentialsGenerator
        ) {
        self.authAPI = authAPI
        self.stepicsAPI = stepicsAPI
        self.profilesAPI = profilesAPI
        self.defaultsStorageManager = defaultsStorageManager
        self.randomCredentialsGenerator = randomCredentialsGenerator
    }

    var userRegistrationService: UserRegistrationService {
        return UserRegistrationServiceImplementation(
            authAPI: authAPI,
            stepicsAPI: stepicsAPI,
            profilesAPI: profilesAPI,
            defaultsStorageManager: defaultsStorageManager,
            randomCredentialsGenerator: randomCredentialsGenerator
        )
    }

    var graphService: GraphService {
        return GraphServiceImpl()
    }
}
