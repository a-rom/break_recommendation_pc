//
//  FaceTracker.swift
//  break_recommendation_pc
//
//  Created by 田中歩 on 2017/10/07.
//  Copyright © 2017年 田中歩. All rights reserved.
//

import Foundation
import AppKit
import AVFoundation
var TIRED = 0
var COUNT = 0
var REST_COUNT = 0
var faceRect = CGRect()



class FaceTracker: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    
    var videoOutput = AVCaptureVideoDataOutput()
    var view:NSView
    private var findface : (_ arr:Array<CGRect>) -> Void
    required init(view:NSView, findface: @escaping (_ arr:Array<CGRect>) -> Void)
    {
        self.view=view
        self.findface = findface
        super.init()
        self.initialize()
    }
    
    func initialize()
    {
        //各デバイスの登録(audioは実際いらない)
        do {
            let videoInput = try AVCaptureDeviceInput(device: self.videoDevice) as AVCaptureDeviceInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        do {
            let audioInput = try AVCaptureDeviceInput(device: self.audioDevice) as AVCaptureInput
            self.captureSession.addInput(audioInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        
        //フレーム毎に呼び出すデリゲート登録
        //let queue:DispatchQueue = DispatchQueue(label:"myqueue",attribite: DISPATCH_QUEUE_SERIAL)
        let queue:DispatchQueue = DispatchQueue(label: "myqueue", attributes: .concurrent)
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.view.layer?.addSublayer(videoLayer)
        
        
        
        
        //カメラ向き
        for connection in self.videoOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.isVideoOrientationSupported {
                    conn.videoOrientation = AVCaptureVideoOrientation.portrait
                }
            }
        }
        
        self.captureSession.startRunning()
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> NSImage {
        //バッファーをNSImageに変換
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let cgsize:CGSize = CGSize(width: imageRef!.width, height: imageRef!.height)
        let resultImage = NSImage(cgImage: imageRef!,size:cgsize)
        return resultImage
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        //同期処理（非同期処理ではキューが溜まりすぎて画面がついていかない）
        DispatchQueue.main.sync(execute: {
            
            //バッファーをCIImageに変換
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            //let ciimage = CIImage(cgImage: image as! CGImage)
            //var imageRect:CGRect = CGRect(0, 0, image.size.width, image.size.height)
            //var ciimage = image.CcgImage&forProposedRect;: imageRect, context: nil, hints: nil)
            let imageData = image.tiffRepresentation!
            let ciimage:CIImage! = CIImage(data: imageData)
            //let ciimage = CIImage(image: image)
            
            //CIDetectorAccuracyHighだと高精度（使った感じは遠距離による判定の精度）だが処理が遅くなる
            let detector : CIDetector = CIDetector(
                ofType: CIDetectorTypeFace,
                context: nil,
                options:[CIDetectorAccuracy: CIDetectorAccuracyLow] )!
            
            let options = [CIDetectorSmile : true, CIDetectorEyeBlink : true]
            
            let faces : NSArray = detector.features(in: ciimage, options: options) as NSArray
            
            if faces.count != 0
            {
                var rects = Array<CGRect>();
                var _ : CIFaceFeature = CIFaceFeature()
                formatter.dateFormat = "MM-dd-HH-mm-ss"
                for feature in faces {
                    
                    // 座標変換
                    //var faceRect : CGRect = (feature as AnyObject).bounds
                    faceRect = (feature as AnyObject).bounds
                    let widthPer = (self.view.bounds.width/image.size.width)
                    let heightPer = (self.view.bounds.height/image.size.height)
                    
                    
                    // UIKitは左上に原点があるが、CoreImageは左下に原点があるので揃える
                    faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                    
                    //倍率変換
                    faceRect.origin.x = faceRect.origin.x * widthPer
                    faceRect.origin.y = faceRect.origin.y * heightPer
                    faceRect.size.width = faceRect.size.width * widthPer
                    faceRect.size.height = faceRect.size.height * heightPer
                    
                    
                    
                    
                    if (feature as AnyObject).leftEyeClosed == true {
                        //let date = Date()
                        //let dateStr = formatter.string(from: date)
                        //formatter.dateFormat = "MM-dd-HH-mm-ss"
                        //let eyeClosedCount:[String:Any] = ["time":dateStr,"eye_closed": COUNT];
                        COUNT = 1
                        //databaseRef.childByAutoId().child(deviceId).setValue(eyeClosedCount)
                        print(COUNT)
                        
                        
                    }
                    
                    rects.append(faceRect)
                }
                self.findface(rects)
            }
            
            
        })
        
        
    }
    
}

