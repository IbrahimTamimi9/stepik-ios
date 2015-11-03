//
//  Sorter.swift
//  Stepic
//
//  Created by Alexander Karpov on 26.10.15.
//  Copyright © 2015 Alex Karpov. All rights reserved.
//

import Foundation

struct Sorter {
    static func sort<T : JSONInitializable, TID>(array : [T], byIds ids: [TID]) -> [T] {
        var res : [T] = []
        
        for id in ids {
            let elements = array.filter({return "\($0.id)" == "\(id)"})
            if elements.count == 1 {
                res += [elements[0]]
            } else {
                //TODO : Maybe should throw exception here
                print("Something went wrong")
            }
        }
        
        return res
    }
}