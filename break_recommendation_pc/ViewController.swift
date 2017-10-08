//
//  ViewController.swift
//  break_recommendation_pc
//
//  Created by 田中歩 on 2017/10/07.
//  Copyright © 2017年 田中歩. All rights reserved.
//

import Cocoa
import CoreImage
import AVFoundation
import AppKit

//var databaseRef:DatabaseReference!
//let deviceId = UIDevice.current.identifierForVendor!.uuidString
let formatter = DateFormatter()


class ViewController: NSViewController {
    
    
    @IBOutlet weak var tired: NSButton?
    
    
    var faceTracker:FaceTracker? = nil;
    //@IBOutlet var cameraView :NSView?//viewController上に一つviewを敷いてそれと繋いでおく
    @IBOutlet weak var cameraView: NSImageView!
    
    var rectView = NSView()
    override func viewWillAppear() {
        //databaseRef = Database.database().reference()
        self.rectView.layer?.borderWidth = 3//四角い枠を用意しておく
        self.view.addSubview(self.rectView)
        faceTracker = FaceTracker(view: self.cameraView!, findface:{arr in
            let rect = arr[0];//一番の顔だけ使う
            self.rectView.frame = rect;//四角い枠を顔の位置に移動する
            
        })
        //Timer.scheduledTimer(timeInterval: 10.00, target: self, selector: #selector(self.onUpdate), userInfo: nil, repeats: false)
        
        Timer.scheduledTimer(timeInterval: 1.00, target: self, selector: #selector(self.moveFace), userInfo: nil, repeats: true)
        
        
        

    }
    func onUpdate(){
        
        //REST_COUNT = COUNT / 3
        //number.text = (String(REST_COUNT))
        
        
        
    }
    
    
    func moveFace(){
        //let date = Date()
        //let dateStr = formatter.string(from: date)
        //formatter.dateFormat = "MM-dd-HH-mm-ss"
        //let moveFace:[String:Any] = ["time":dateStr,"origin_x": faceRect.origin.x,"origin_y": faceRect.origin.y];
        //databaseRef.childByAutoId().child(deviceId).setValue(moveFace)
        print("100")
        
        
        
    }
    
    
    @IBAction func tired(_ sender: Any) {
        //let date = Date()
        //let dateStr = formatter.string(from: date)
        //formatter.dateFormat = "MM-dd-HH-mm-ss"
        //let callTired:[String:Any] = ["time":dateStr,"tired": TIRED];
        //TIRED = 1
        //databaseRef.childByAutoId().child(deviceId).setValue(callTired)
        
        
    }


}
