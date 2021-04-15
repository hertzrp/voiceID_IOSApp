//
//  PhotoVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/22.
//

import Foundation
import UIKit

class PhotoVC: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    weak var photoReturnDelegate : PhotoReturnDelegate?
    var photoString :String! = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if photoString != ""{
            let loadedImage = base64toImage(img: photoString)!.resizeImage(targetSize: CGSize(width: 250, height: 257))
            postImage.image = loadedImage
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        let retString = imagetoBase64(img: postImage.image)!
        photoReturnDelegate?.photoDidReturn(retString)
        dismiss(animated: true, completion: nil)
        
    }
    @IBOutlet weak var postImage: UIImageView!
    @IBAction func pickMedia(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = ["public.image"]
        self.present(imagePickerController, animated: true, completion: nil)
    }
    @IBAction func accessCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = true
            imagePickerController.sourceType = .camera
            imagePickerController.mediaTypes = ["public.image"]
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            print("Camera not available")
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if mediaType  == "public.image" {
                if info[UIImagePickerController.InfoKey.editedImage] != nil {
                    postImage.image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
                } else {
                    postImage.image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage)!
                }
                postImage.image = postImage.image!.resizeImage(targetSize: CGSize(width: 250, height: 257))
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagetoBase64(img: UIImage?) -> String? {
        if (img == nil) {
            return ""
        } else {
            let compressData = img!.jpegData(compressionQuality: 0.5)
            let strbase64 = compressData?.base64EncodedString(options: .lineLength64Characters)
            return strbase64
        }
    }
    func base64toImage(img: String) -> UIImage? {
        if (img == "") {
          return nil
        }
        let dataDecoded : Data = Data(base64Encoded: img, options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        return decodedimage!
    }
    override func viewDidDisappear(_ animated: Bool) {
        let retString = imagetoBase64(img: postImage.image)!
        photoReturnDelegate?.photoDidReturn(retString)
        dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if (widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newimage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newimage!
    }
}
