//
//  main.swift
//  SwiftARC
//
//  Created by Douglas Richardson on 2/20/15.
//  Copyright (c) 2015 True Labs, Inc. All rights reserved.
//

import Foundation

class A {
    let name : String
    init(_ name : String) {
        self.name = name
        println("------- init \(name)   ----------")
    }
    
    deinit {
        println("------- deinit \(name) ----------")
    }
}

func localA() {
    let a = A(__FUNCTION__)
}

func optionalA() {
    var a : A? = A(__FUNCTION__)
}

func optionalClosureContainingA() {
    var a = A(__FUNCTION__)
    var c : (() -> ())? = nil
    c = {
        println("c called with a = \(a)")
    }
    c?()
}

func optionalClosureContainingAsyncA(doneCallback : dispatch_block_t) {
    var a = A(__FUNCTION__)
    var c : (() -> ())? = nil
    
    let now = dispatch_time(DISPATCH_TIME_NOW, 0)
    let firstBlockTime = dispatch_time(now, Int64(2 * NSEC_PER_SEC))
    let secondBlockTime = dispatch_time(firstBlockTime, Int64(2 * NSEC_PER_SEC))
    
    dispatch_after(firstBlockTime, dispatch_get_main_queue(), {
        println("first. is nil? \(c == nil)")
        c?()
        return
    })
    
    dispatch_after(secondBlockTime, dispatch_get_main_queue(), {
        println("second. is nil? \(c == nil)")
        c?()
        println("setting c to nil")
        c = nil // A deinit called here
        println("c set to nil")
        dispatch_async(dispatch_get_main_queue(), doneCallback)
    })
    
    c = {
        println("c called with a = \(a)")
    }
    
    println("end " + __FUNCTION__)
}

func selfNillingOptionalClosureContainingAsyncA(doneCallback : dispatch_block_t) {
    var a = A(__FUNCTION__)
    var c : (() -> ())? = nil
    
    let now = dispatch_time(DISPATCH_TIME_NOW, 0)
    let firstBlockTime = dispatch_time(now, Int64(2 * NSEC_PER_SEC))
    let secondBlockTime = dispatch_time(firstBlockTime, Int64(2 * NSEC_PER_SEC))
    
    dispatch_after(firstBlockTime, dispatch_get_main_queue(), {
        println("first. is nil? \(c == nil)")
        c?()
        return
    })
    
    dispatch_after(secondBlockTime, dispatch_get_main_queue(), {
        println("second. is nil? \(c == nil)")
        while c != nil {
            c?()
        }
        println("second ending")
    })
    
    var counter = 3
    c = {
        println("c called with a = \(a)")
        --counter
        if counter <= 0 {
            println("counter zero, setting c = nil")
            c = nil // appears that invoker retains block, so setting to nil here
            // does not result in an immediate deinit, which is good considering we're still
            // executing the block.
            println("c set to nil")
            dispatch_async(dispatch_get_main_queue(), doneCallback)
        } else {
            println("counter decremented to \(counter)")
        }
        
        println("exiting call to c closure")
    }
    
    println("end " + __FUNCTION__)
}

let globalA = A("global")
localA()
optionalA()
optionalClosureContainingA()
optionalClosureContainingAsyncA {
    selfNillingOptionalClosureContainingAsyncA { exit(0) }
    }

dispatch_main()



