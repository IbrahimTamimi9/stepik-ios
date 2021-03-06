//
//  KnowledgeGraphVertex.swift
//  ExamEGERussian
//
//  Created by Ivan Magda on 19/07/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import Foundation

public final class KnowledgeGraphVertex<T: Hashable>: Vertex<T> {
    public var title: String
    public var lessons = [KnowledgeGraphLesson]()

    init(id: T, title: String = "") {
        self.title = title
        super.init(id: id)
    }
}
