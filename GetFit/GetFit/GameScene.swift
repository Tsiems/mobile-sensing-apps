//
//  GameScene.swift
//  GetFit
//
//  Created by Danh Nguyen on 9/27/16.
//  Copyright © 2016 Danh Nguyen. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion

class GameScene: SKScene {
    // MARK: Raw Motion Functions
    let motion = CMMotionManager()
    func startMotionUpdates(){
        // some internal inconsistency here: we need to ask the device manager for device
        
        if self.motion.isDeviceMotionAvailable{
            self.motion.deviceMotionUpdateInterval = 0.1
            self.motion.startDeviceMotionUpdates(to: OperationQueue()) {
                (data,error) in
                if error != nil {
                    print("Error: %@", error)
                }
                
                if let gravity = data?.gravity {
                    self.physicsWorld.gravity = CGVector(dx:CGFloat(9.8*gravity.x), dy:CGFloat(9.8*gravity.y))
                }
            }
        }
    }
    
    func handleMotion(motionData:CMDeviceMotion?, error:NSError?){
        if let gravity = motionData?.gravity {
            self.physicsWorld.gravity = CGVector(dx:CGFloat(9.8*gravity.x), dy:CGFloat(9.8*gravity.y))
        }
    }
    
    // MARK: View Hierarchy Functions
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor.white
        
        // start motion for gravity
        self.startMotionUpdates()
        
        // make sides to the screen
        self.addBorder()
        
//        // add some stationary blocks
//        self.addStaticBlockAtPoint(CGPoint(x: size.width * 0.1, y: size.height * 0.25))
//        self.addStaticBlockAtPoint(CGPoint(x: size.width * 0.9, y: size.height * 0.25))
//        
//        // add a spinning block
//        self.addBlockAtPoint(CGPoint(x: size.width * 0.5, y: size.height * 0.35))
//        
        self.addSprite()
    }
    
    func addBorder(){
        let left = SKSpriteNode()
        let right = SKSpriteNode()
        let top = SKSpriteNode()
        let bottom = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        top.size = CGSize(width:size.width,height:size.height*0.1)
        top.position = CGPoint(x:size.width*0.5, y:size.height)
        
        bottom.size = CGSize(width:size.width,height:size.height*0.1)
        bottom.position = CGPoint(x:size.width*0.5, y:0)

        
        for obj in [left,right,top, bottom]{
            obj.color = UIColor.blue
            obj.physicsBody = SKPhysicsBody(rectangleOf:obj.size)
            obj.physicsBody?.isDynamic = true
            obj.physicsBody?.pinned = true
            obj.physicsBody?.allowsRotation = false
            self.addChild(obj)
        }
    }
    
    // MARK: Create Sprites Functions
    func addSprite(){
        let spriteA = SKSpriteNode(imageNamed: "eric") // this is literally eric... 😎
        
        spriteA.size = CGSize(width:size.width*0.1,height:size.height * 0.1)
        
        spriteA.position = CGPoint(x: size.width * random(min: CGFloat(0.1), max: CGFloat(0.9)), y: size.height * 0.75)
        
        spriteA.physicsBody = SKPhysicsBody(rectangleOf:spriteA.size)
        spriteA.physicsBody?.restitution = random(min: CGFloat(1.0), max: CGFloat(1.5))
        spriteA.physicsBody?.isDynamic = true
        
        self.addChild(spriteA)
    }
    
    
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }


}

