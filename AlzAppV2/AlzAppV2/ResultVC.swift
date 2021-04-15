//
//  ResultVC.swift
//  AlzAppV2
//
//  Created by Wang on 2020/11/21.
//

import Foundation
import UIKit

class ResultVC: UIViewController{
    
    @IBOutlet weak var resultImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var IncorrectButton: UIButton!
    
    var photoString :String! = ""
    var nameString = ""
    var relationshipString = ""
    weak var resultReturnDelegate: ResultReturnDelegate?
    var showIncorrect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = nameString
        relationshipLabel.text = relationshipString
        if photoString != ""{
            let loadedImage = base64toImage(img: photoString)!.resizeImage(targetSize: CGSize(width: 250, height: 257))
            resultImage.image = loadedImage
        }
        if showIncorrect != true{
            IncorrectButton.isHidden = true
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        resultReturnDelegate?.resultDidReturn()
    }
    func base64toImage(img: String) -> UIImage? {
        if (img == "") {
          return nil
        }
        let dataDecoded : Data = Data(base64Encoded: img, options: .ignoreUnknownCharacters)!
        let decodedimage = UIImage(data: dataDecoded)
        return decodedimage!
    }
    
    
    @IBAction func IncorrectTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Incorrect", message: "If we didn't correctly identify you, head to the voice collection scene to help us fine-tune our algorithm by submitting additional Voice Clips for this User.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}


