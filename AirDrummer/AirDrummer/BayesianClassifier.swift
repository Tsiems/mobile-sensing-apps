//
//  BayesianClassifier.swift
//  Bayes
//
//  Created by Fabian Canas on 5/9/15.
//  Copyright (c) 2015 Fabian Canas. All rights reserved.
//

import Darwin

let nonZeroLog = 0.00000001

public struct BayesianClassifier<C :Hashable, F :Hashable> {
    public typealias Feature = F
    public typealias Category = C
    
    public init(eventSpace: EventSpace<Category,Feature>){
        self.eventSpace = eventSpace
    }
    
    public var eventSpace :EventSpace<Category,Feature> = EventSpace<Category,Feature>()
    
    public func classify <S :Sequence> (features :S) -> Category? where S.Iterator.Element == Feature {
        return argmax(collection: categoryProbabilities(features: features))
    }
    
    public func categoryProbabilities <S :Sequence> (features: S) -> [Category: Double] where S.Iterator.Element == Feature {
        return eventSpace.categories.reduce([C:Double](), {(v: [C:Double], c: Category) in
            var mv = v
            mv[c] = log(self.eventSpace.P(category: c)) + sum(s: features.map { log(self.eventSpace.P(feature: $0, givenCategory: c) + nonZeroLog) } )
            return mv
        })
    }
}