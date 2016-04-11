//
//  ViewController.swift
//  s3-upload-from-camera-or-library
//
//  Created by Jose Deras on 4/11/16.
//  Copyright © 2016 Jose Deras. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let camImagePicker = UIImagePickerController()
            camImagePicker.delegate = self
            camImagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            camImagePicker.allowsEditing = false
            self.presentViewController(camImagePicker, animated: true, completion: nil)
        }
    }

    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    @IBOutlet weak var progressView: UIProgressView!
    
    //handles upload
    var uploadCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var uploadFileURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //setting progress bar to 0
        self.progressView.progress = 0.0;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
     //begin upload from photo library
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        //first run if its coming from photo album
        if(picker.sourceType == UIImagePickerControllerSourceType.PhotoLibrary)
        {
            
            //getting details of image
            let uploadFileURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            
            let imageName = uploadFileURL.lastPathComponent
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as String
            
            // getting local path
            let localPath = (documentDirectory as NSString).stringByAppendingPathComponent(imageName!)
            
            
            //getting actual image
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            let data = UIImagePNGRepresentation(image)
            data!.writeToFile(localPath, atomically: true)
            
            let imageData = NSData(contentsOfFile: localPath)!
            let photoURL = NSURL(fileURLWithPath: localPath)
            
            // let imageWithData = UIImage(data: imageData)!
            
            
            //defining bucket and upload file name
            let S3BucketName: String = "BUCKET-NAME"
            let S3UploadKeyName: String = "FileName.jpg"
            
            
            
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
                dispatch_async(dispatch_get_main_queue(), {
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    self.progressView.progress = progress
                    // self.statusLabel.text = "Uploading..."
                    NSLog("Progress is: %f",progress)
                })
            }
            
            self.uploadCompletionHandler = { (task, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    if ((error) != nil){
                        NSLog("Failed with error")
                        NSLog("Error: %@",error!);
                        //    self.statusLabel.text = "Failed"
                    }
                    else if(self.progressView.progress != 1.0) {
                        //    self.statusLabel.text = "Failed"
                        NSLog("Error: Failed - Likely due to invalid region / filename")
                    }
                    else{
                        //    self.statusLabel.text = "Success"
                        NSLog("Sucess")
                    }
                })
            }
            
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            
            transferUtility?.uploadFile(photoURL, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/jpeg", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
                if let error = task.error {
                    NSLog("Error: %@",error.localizedDescription);
                    //  self.statusLabel.text = "Failed"
                }
                if let exception = task.exception {
                    NSLog("Exception: %@",exception.description);
                    //   self.statusLabel.text = "Failed"
                }
                if let _ = task.result {
                    // self.statusLabel.text = "Generating Upload File"
                    NSLog("Upload Starting!")
                    // Do something with uploadTask.
                }
                
                return nil;
            }
            
            //end if photo library upload
            self.dismissViewControllerAnimated(true, completion: nil);
            
        }
            
            
            //second check if its coming from camera
        else if(picker.sourceType == UIImagePickerControllerSourceType.Camera)
        {
            
            //  var imageToSave: UIImage = info(UIImagePickerControllerOriginalImage) as UIImage
            var imageToSave: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            //defining bucket and upload file name
            let S3BucketName: String = "BUCKET-NAME"
            //setting temp name for upload
            let S3UploadKeyName = "File-Namejpg"
            
            //settings temp location for image
            let imageName = NSURL.fileURLWithPath(NSTemporaryDirectory() + S3UploadKeyName).lastPathComponent
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as String
            
            // getting local path
            let localPath = (documentDirectory as NSString).stringByAppendingPathComponent(imageName!)
            
            
            //getting actual image
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            let data = UIImagePNGRepresentation(image)
            data!.writeToFile(localPath, atomically: true)
            
            let imageData = NSData(contentsOfFile: localPath)!
            let photoURL = NSURL(fileURLWithPath: localPath)
            
            
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
                dispatch_async(dispatch_get_main_queue(), {
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    self.progressView.progress = progress
                    // self.statusLabel.text = "Uploading..."
                    NSLog("Progress is: %f",progress)
                })
            }
            
            self.uploadCompletionHandler = { (task, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    if ((error) != nil){
                        NSLog("Failed with error")
                        NSLog("Error: %@",error!);
                        //    self.statusLabel.text = "Failed"
                    }
                    else if(self.progressView.progress != 1.0) {
                        //    self.statusLabel.text = "Failed"
                        NSLog("Error: Failed - Likely due to invalid region / filename")
                    }
                    else{
                        //    self.statusLabel.text = "Success"
                        NSLog("Sucess")
                    }
                })
            }
            
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            
            transferUtility?.uploadFile(photoURL, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/jpeg", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
                if let error = task.error {
                    NSLog("Error: %@",error.localizedDescription);
                    //  self.statusLabel.text = "Failed"
                }
                if let exception = task.exception {
                    NSLog("Exception: %@",exception.description);
                    //   self.statusLabel.text = "Failed"
                }
                if let _ = task.result {
                    // self.statusLabel.text = "Generating Upload File"
                    NSLog("Upload Starting!")
                    // Do something with uploadTask.
                }
                
                return nil;
            }
            
            //end if photo library upload
            self.dismissViewControllerAnimated(true, completion: nil);
            
            
            
        }
            
        else{
            NSLog("Shit fucked up yo")
        }
        
        
    }

}

