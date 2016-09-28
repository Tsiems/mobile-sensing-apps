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
    
    
    
    lazy var enemiesLeft = 5
    
    lazy var goalsMade = 0
    
    
    
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
                    self.physicsWorld.gravity = CGVector(dx:CGFloat(1.1*9.8*gravity.x), dy:CGFloat(1.1*9.8*gravity.y))
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
        
         Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(GameScene.spawnEnemy), userInfo: nil, repeats: true)
        
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
        self.addStaticBlockAtPoint(point: CGPoint(x: size.width * 0.5, y: size.height * 0.55))
        self.addSprite()
    }
    
    func addBorder(){
        let left = SKSpriteNode()
        let right = SKSpriteNode()
        let bottom = SKSpriteNode()
        
        let top_left = SKSpriteNode()
        let top_right = SKSpriteNode()
        
        left.size = CGSize(width:size.width*0.1,height:size.height)
        left.position = CGPoint(x:0, y:size.height*0.5)
        
        right.size = CGSize(width:size.width*0.1,height:size.height)
        right.position = CGPoint(x:size.width, y:size.height*0.5)
        
        bottom.size = CGSize(width:size.width,height:size.height*0.1)
        bottom.position = CGPoint(x:size.width*0.5, y:0)
        
        
        top_left.size = CGSize(width:size.width/3,height:size.height*0.1)
        top_left.position = CGPoint(x:size.width*0.165, y:size.height)
        top_right.size = CGSize(width:size.width/3,height:size.height*0.1)
        top_right.position = CGPoint(x:size.width*0.825, y:size.height)

        
        for obj in [left,right,top_left,top_right, bottom]{
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
        
        spriteA.size = CGSize(width:size.width * 0.1,height:size.height * 0.075)
        
        spriteA.position = CGPoint(x: size.width * random(min: CGFloat(0.1), max: CGFloat(0.9)), y: size.height * 0.75)
        
        spriteA.physicsBody = SKPhysicsBody(rectangleOf:spriteA.size)
        // lose energy after a miss bounce
        spriteA.physicsBody?.restitution = CGFloat(0.5)
//        spriteA.physicsBody?.restitution = random(min: CGFloat(1.0), max: CGFloat(1.5))
        spriteA.physicsBody?.isDynamic = true
        spriteA.name = "me"
        
        self.addChild(spriteA)
    }
    
    func addStaticBlockAtPoint(point:CGPoint){
        let 🔲 = SKSpriteNode()
        
        🔲.color = UIColor.blue
        🔲.size = CGSize(width:size.width*0.1,height:size.height * 0.05)
        🔲.position = point
        
        🔲.physicsBody = SKPhysicsBody(rectangleOf:🔲.size)
        🔲.physicsBody?.isDynamic = true
        🔲.physicsBody?.pinned = true
        🔲.physicsBody?.allowsRotation = false
        
        self.addChild(🔲)
        
    }
    
    
    
    func spawnEnemy(){
        
        if enemiesLeft > 0 {
            //supposed to pick random point within the screen width
            let xPos = random(min:0, max: frame.width )
            
            let enemy = SKSpriteNode(imageNamed: "enemy") //create a new enemy each time
            enemy.position = CGPoint(x:CGFloat(xPos), y:self.frame.size.height/4*3)
            enemy.size = CGSize(width:size.width * 0.1,height:size.height * 0.075)
    //        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 7)
            enemy.physicsBody = SKPhysicsBody(rectangleOf:enemy.size)
            enemy.physicsBody?.affectedByGravity = false
            enemy.physicsBody?.restitution = CGFloat(0.5)
    //        enemy.physicsBody?.categoryBitMask = 0
    //        enemy.physicsBody?.contactTestBitMask = 1
            enemy.physicsBody?.isDynamic = true
            enemy.name = "my_enemy"
            addChild(enemy)
            
            
            enemiesLeft -= 1
        }
    }
    
    
    
    
    override func update(_ currentTime: CFTimeInterval) {
        
        // Loop over all nodes in the scene
        self.enumerateChildNodes(withName: "*") {
            node, stop in
            if (node is SKSpriteNode) {
                let sprite = node as! SKSpriteNode
                // Check if the node is not in the scene
                if (sprite.position.x < -sprite.size.width/2.0 || sprite.position.x > self.size.width+sprite.size.width/2.0
                    || sprite.position.y < -sprite.size.height/2.0 || sprite.position.y > self.size.height+sprite.size.height/2.0) {
                    if sprite.name == "me" {
                        print("YOU LOSE!")
                    }
                    sprite.removeFromParent()
                    print("Remove child!")
                    self.goalsMade += 1
                }
            }
        }
    }

    
    
    
    // MARK: Utility Functions (thanks ray wenderlich!)
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }


}

