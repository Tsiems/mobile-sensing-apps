//
//  EventSpace.swift
//  Bayes
//
//  Created by Fabian Canas on 5/9/15.
//  Copyright (c) 2015 Fabian Canas. All rights reserved.
//

public struct EventSpace <C: Hashable, F: Hashable> {
    public typealias Category = C
    public typealias Feature = F
    
    public init() {}
    
    internal var categories :[Category] {
        get {
            return _categories.members
        }
    }
    
    private var _categories :Bag<C> = Bag<C>()
    private var _features :Bag<F> = Bag<F>()
    private var featureCategory :Bag<HashableTuple<C,F>> = Bag<HashableTuple<C,F>>()
    
    public mutating func observe <F: Sequence> (category: Category, features: F) where F.Iterator.Element == Feature {
        _categories.append(element: category)
        _features.append(elements: features)
        featureCategory.append(elements: features.map {
            HashableTuple(category, $0)
        })
    }
    
    public func P(feature: Feature, andCategory category: Category) -> Double {
        return Double(featureCategory.count(element: HashableTuple(category, feature))) / Double(_categories.count)
    }
    
    public func P(feature: Feature, givenCategory category: Category) -> Double {
        return P(feature: feature, andCategory: category)/P(category: category)
    }
    
    public func P(category: Category) -> Double {
        return _categories.P(element: category)
    }
}
