//
//  ViewController.swift
//  ML
//
//  Created by Maxim Perehod on 11/10/2018.
//  Copyright © 2018 Maxim Perehod. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation
import AudioToolbox


@available(iOS 11.0, *)
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let danger = ["remote controller", "cat", "dog", "keyboard", "knob", "table", "sponges", "money", "smartphone", "toilet", "metro", "staha", "rubish", "sole"]

 
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var shodstvo: UILabel!
    
    
    var model: ImageClassifier!
    
    override func viewWillAppear(_ animated: Bool) {
        model = ImageClassifier()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = imageView.frame.width / 2
        imageView.clipsToBounds = true
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func choose(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
    }
    
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            // делаю фото 299 на 299
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
            image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            // переделываю фотку на нужный формат
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            var pixelBuffer : CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
            guard (status == kCVReturnSuccess) else {
                return
            }
            
            
            //
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
            
            
            context?.translateBy(x: 0, y: newImage.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            
            
            UIGraphicsPushContext(context!)
            newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            
            
            imageView.image = newImage
            
            
            // отправление фото непосредственно в модель мащин лёрнинга
            guard let prediction = try? model.prediction(image: pixelBuffer!) else {
                return
            }
            
            navigationItem.title = "\(NSLocalizedString(prediction.classLabel + "1", comment: ""))"
            
            if danger.contains(prediction.classLabel) {
                
                AudioServicesPlaySystemSound(SystemSoundID(1332))
                
                
            } else {
                
                AudioServicesPlaySystemSound(SystemSoundID(1327))
            }
            
            textView.text = "\(NSLocalizedString(prediction.classLabel, comment: ""))"
            
            shodstvo.text = "\(Int(Double(prediction.classLabelProbs[prediction.classLabel]!) * 100)) % сходства"
        }
    }
    
}
