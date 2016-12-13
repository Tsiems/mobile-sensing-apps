//
//  KDDragAndDropManager.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDraggable {
    func canDragAtPoint(point : CGPoint) -> Bool
    func representationImageAtPoint(point : CGPoint) -> UIView?
    func dataItemAtPoint(point : CGPoint) -> AnyObject?
    func dragDataItem(item : AnyObject) -> Void
    @objc optional func startDraggingAtPoint(point : CGPoint) -> Void
    @objc optional func stopDragging() -> Void
}


@objc protocol KDDroppable {
    func canDropAtRect(rect : CGRect) -> Bool
    func willMoveItem(item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveItem(item : AnyObject, inRect rect : CGRect) -> Void
    func didMoveOutItem(item : AnyObject) -> Void
    func dropDataItem(item : AnyObject, atRect : CGRect) -> Void
}

class KDDragAndDropManager: NSObject, UIGestureRecognizerDelegate {
    
    private var canvas : UIView = UIView()
    private var views : [UIView] = []
    private var longPressGestureRecogniser = UILongPressGestureRecognizer()
    
    
    struct Bundle {
        var offset : CGPoint = CGPoint.zero
        var sourceDraggableView : UIView
        var overDroppableView : UIView?
        var representationImageView : UIView
        var dataItem : AnyObject
    }
    var bundle : Bundle?
    
    init(canvas : UIView, collectionViews : [UIView]) {
        
        super.init()
        
        self.canvas = canvas
        
        self.longPressGestureRecogniser.delegate = self
        self.longPressGestureRecogniser.minimumPressDuration = 0.1
        self.longPressGestureRecogniser.addTarget(self, action: #selector(KDDragAndDropManager.updateForLongPress))
        
        self.canvas.addGestureRecognizer(self.longPressGestureRecogniser)
        self.views = collectionViews
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        for view in self.views.filter({ v -> Bool in v is KDDraggable})  {
            
            let draggable = view as! KDDraggable
            
            let touchPointInView = touch.location(in: view)
            
            if draggable.canDragAtPoint(point: touchPointInView) == true {
                
                if let representation = draggable.representationImageAtPoint(point: touchPointInView) {
                    
                    representation.frame = self.canvas.convert(representation.frame, from: view)
                    
                    representation.alpha = 0.7
                    
                    let pointOnCanvas = touch.location(in: self.canvas)
                    
                    let offset = CGPoint(x: pointOnCanvas.x - representation.frame.origin.x, y: pointOnCanvas.y - representation.frame.origin.y)
                    
                    if let dataItem : AnyObject = draggable.dataItemAtPoint(point: touchPointInView) {
                        
                        self.bundle = Bundle(
                            offset: offset,
                            sourceDraggableView: view,
                            overDroppableView : view is KDDroppable ? view : nil,
                            representationImageView: representation,
                            dataItem : dataItem
                        )
                        
                        return true
                        
                    } // if let dataIte...
                    
                    
                } // if let representation = dragg...
                
                
            } // if draggable.canDragAtP...
            
        } // for view in self.views.fil...
        
        return false
        
    }
    
    
    
    
    func updateForLongPress(recogniser : UILongPressGestureRecognizer) -> Void {
        
        if let bundl = self.bundle {
            
            let pointOnCanvas = recogniser.location(in: recogniser.view)
            let sourceDraggable : KDDraggable = bundl.sourceDraggableView as! KDDraggable
            let pointOnSourceDraggable = recogniser.location(in: bundl.sourceDraggableView)
            
            switch recogniser.state {
                
                
            case .began :
                self.canvas.addSubview(bundl.representationImageView)
                sourceDraggable.startDraggingAtPoint?(point: pointOnSourceDraggable)
                
            case .changed :
                
                // Update the frame of the representation image
                var repImgFrame = bundl.representationImageView.frame
                repImgFrame.origin = CGPoint(x: pointOnCanvas.x - bundl.offset.x, y: pointOnCanvas.y - bundl.offset.y);
                bundl.representationImageView.frame = repImgFrame
                
                var overlappingArea : CGFloat = 0.0
                
                var mainOverView : UIView?
                
                for view in self.views.filter({ v -> Bool in v is KDDroppable }) {
                    
                    let viewFrameOnCanvas = self.convertRectToCanvas(rect: view.frame, fromView: view)
                    
                    
                    /*                ┌────────┐   ┌────────────┐
                     *                 │       ┌┼───│Intersection│
                     *                 │       ││   └────────────┘
                     *                 │   ▼───┘│
                     * ████████████████│████████│████████████████
                     * ████████████████└────────┘████████████████
                     * ██████████████████████████████████████████
                     */
                    
                    let intersectionNew = bundl.representationImageView.frame.intersection(viewFrameOnCanvas).size
                    
                    
                    if (intersectionNew.width * intersectionNew.height) > overlappingArea {
                        
                        overlappingArea = intersectionNew.width * intersectionNew.width
                        
                        mainOverView = view
                    }
                    
                    
                }
                
                
                
                if let droppable = mainOverView as? KDDroppable {
                    
                    let rect = self.canvas.convert(bundl.representationImageView.frame, to: mainOverView)
                    
                    if droppable.canDropAtRect(rect: rect) {
                        
                        if mainOverView != bundl.overDroppableView { // if it is the first time we are entering
                            
                            (bundl.overDroppableView as! KDDroppable).didMoveOutItem(item: bundl.dataItem)
                            droppable.willMoveItem(item: bundl.dataItem, inRect: rect)
                            
                        }
                        
                        // set the view the dragged element is over
                        self.bundle!.overDroppableView = mainOverView
                        
                        droppable.didMoveItem(item: bundl.dataItem, inRect: rect)
                        
                    }
                    
                    
                }
                
                
            case .ended :
                
                if bundl.sourceDraggableView != bundl.overDroppableView { // if we are actually dropping over a new view.
                    
                    print("\(bundl.overDroppableView?.tag)")
                    
                    if let droppable = bundl.overDroppableView as? KDDroppable {
                        
                        sourceDraggable.dragDataItem(item: bundl.dataItem)
                        
                        let rect = self.canvas.convert(bundl.representationImageView.frame, to: bundl.overDroppableView)
                        
                        droppable.dropDataItem(item: bundl.dataItem, atRect: rect)
                        
                    }
                }
                
                
                bundl.representationImageView.removeFromSuperview()
                sourceDraggable.stopDragging?()
                
            default:
                break
                
            }
            
            
        } // if let bundl = self.bundle ...
        
        
        
    }
    
    // MARK: Helper Methods
    func convertRectToCanvas(rect : CGRect, fromView view : UIView) -> CGRect {
        
        var r : CGRect = rect
        
        var v = view
        
        while v != self.canvas {
            
            if let sv = v.superview {
                
                r.origin.x += sv.frame.origin.x
                r.origin.y += sv.frame.origin.y
                
                v = sv
                
                continue
            }
            break
        }
        
        return r
    }
    
}
