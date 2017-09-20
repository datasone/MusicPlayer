//
//  HashClass.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/19.
//

import Foundation

class HashClass: Hashable {
    
    public var hashValue: Int
    
    init?() {
        hashValue = Int(arc4random()) + Int(arc4random())
    }
    
}

extension HashClass: Equatable {
    
    public static func ==(lhs: HashClass, rhs: HashClass) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

}
